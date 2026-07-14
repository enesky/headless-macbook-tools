import AppKit
import Carbon.HIToolbox
import Combine
import Foundation

@MainActor final class GlobalShortcutStore: ObservableObject, @unchecked Sendable {
    @Published private(set) var bindings: [ShortcutCommand: ShortcutBinding] = [:]
    @Published private(set) var registrationErrors: [ShortcutCommand: String] = [:]
    @Published private(set) var recording: ShortcutCommand?

    private let signature: OSType = 0x484D4254 // HMBT
    private var hotKeys: [ShortcutCommand: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private var localKeyMonitor: Any?
    private var handlers: [ShortcutCommand: () -> Void] = [:]

    init() {
        ShortcutCommand.selfCheck()
        for command in ShortcutCommand.allCases {
            bindings[command] = Self.load(command) ?? command.defaultBinding
        }
        installEventHandler()
    }

    func configure(tools: ToolController, monitor: SystemMonitor) {
        handlers[.airPlay] = { tools.run(.airPlay) }
        handlers[.sideScreenUSB] = { tools.run(.sideScreenUSB) }
        handlers[.sideScreenWireless] = { tools.run(.sideScreenWireless) }
        handlers[.sleepNow] = {
            let speech = Process()
            speech.executableURL = URL(fileURLWithPath: "/usr/bin/say")
            speech.arguments = ["Going to sleep"]
            try? speech.run()
            Task { @MainActor in
                while speech.isRunning {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                try? await Task.sleep(for: .milliseconds(250))
                monitor.goToSleep()
            }
        }
        registerAll()
    }

    func run(_ command: ShortcutCommand) {
        handlers[command]?()
    }

    func beginRecording(_ command: ShortcutCommand) {
        stopRecording()
        recording = command
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let eventPointer = Unmanaged.passUnretained(event).toOpaque()
            MainActor.assumeIsolated {
                let localEvent = Unmanaged<NSEvent>.fromOpaque(eventPointer).takeUnretainedValue()
                if localEvent.keyCode == 53 {
                    self.stopRecording()
                } else {
                    self.capture(localEvent, for: command)
                }
            }
            return nil
        }
    }

    func resetDefaults() {
        stopRecording()
        for command in ShortcutCommand.allCases {
            bindings[command] = command.defaultBinding
            Self.save(command.defaultBinding, for: command)
        }
        registerAll()
    }

    private func capture(_ event: NSEvent, for command: ShortcutCommand) {
        let flags = event.modifierFlags.intersection([.control, .option, .shift, .command])
        guard !flags.isEmpty else {
            registrationErrors[command] = "Use at least one modifier key."
            return
        }

        let binding = ShortcutBinding(
            keyCode: UInt32(event.keyCode),
            modifiers: Self.carbonModifiers(flags),
            key: Self.keyLabel(for: event)
        )
        bindings[command] = binding
        Self.save(binding, for: command)
        stopRecording()
        registerAll()
    }

    private func stopRecording() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
        recording = nil
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard result == noErr else { return result }
                let store = Unmanaged<GlobalShortcutStore>.fromOpaque(userData).takeUnretainedValue()
                MainActor.assumeIsolated { store.invoke(hotKeyID) }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    private func registerAll() {
        for reference in hotKeys.values { UnregisterEventHotKey(reference) }
        hotKeys.removeAll()
        registrationErrors.removeAll()

        for command in ShortcutCommand.allCases {
            guard let binding = bindings[command] else { continue }
            var reference: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: signature, id: UInt32(command.rawValue))
            let result = RegisterEventHotKey(
                binding.keyCode,
                binding.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &reference
            )
            if result == noErr, let reference {
                hotKeys[command] = reference
            } else {
                registrationErrors[command] = "\(binding.readableDisplay) is already used by macOS or another app."
            }
        }
    }

    private func invoke(_ hotKeyID: EventHotKeyID) {
        guard hotKeyID.signature == signature,
              let command = ShortcutCommand(rawValue: Int(hotKeyID.id)) else { return }
        run(command)
    }

    private static func carbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        return modifiers
    }

    private static func keyLabel(for event: NSEvent) -> String {
        if event.keyCode == 36 { return "↩" }
        if event.keyCode == 49 { return "Space" }
        if event.keyCode == 51 { return "⌫" }
        return event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
    }

    private static func defaultsKey(_ command: ShortcutCommand) -> String {
        "globalShortcut.\(command.rawValue)"
    }

    private static func load(_ command: ShortcutCommand) -> ShortcutBinding? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey(command)) else { return nil }
        return try? JSONDecoder().decode(ShortcutBinding.self, from: data)
    }

    private static func save(_ binding: ShortcutBinding, for command: ShortcutCommand) {
        guard let data = try? JSONEncoder().encode(binding) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey(command))
    }
}
