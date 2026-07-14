import AppKit
import CoreGraphics
import IOKit
import IOKit.ps
import Combine
import ServiceManagement

@MainActor final class SystemMonitor: ObservableObject {
    @Published private(set) var hasExternalDisplay = false
    @Published private(set) var hasAirPlayDisplay = false
    @Published private(set) var hasBuiltInDisplay = false
    @Published private(set) var isBuiltInDisplayEnabled = false
    @Published private(set) var isOnACPower = false
    @Published private(set) var energyMode: EnergyMode = .unavailable
    @Published private(set) var batteryEnergyMode: EnergyMode = .unavailable
    @Published private(set) var adapterEnergyMode: EnergyMode = .unavailable
    @Published private(set) var supportsHighPowerMode = false
    @Published private(set) var lidState: LidState = .unavailable
    @Published private(set) var assertionActive = false
    @Published private(set) var lidOverrideActive = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var dimBuiltInAtLogin = UserDefaults.standard.bool(forKey: "dimBuiltInAtLogin")
    @Published private(set) var disableBuiltInDisplay = UserDefaults.standard.bool(forKey: "disableBuiltInDisplay")
    @Published private(set) var loginWakeSoundEnabled = SystemMonitor.initialLoginWakeSoundSetting()
    @Published private(set) var allowOnBattery = UserDefaults.standard.bool(forKey: "allowOnBattery")
    @Published private(set) var lidOverrideDesired = UserDefaults.standard.bool(forKey: "lidOverrideDesired")
    private let assertion = PowerAssertion()
    private var timer: Timer?
    private var dimTask: Task<Void, Never>?
    private var energyModeRefreshTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []
    private var ownsLidOverride = false
    private var isPreparingForSleep = false
    private var lastActionError: String?
    private var energyModeKey: String?
    private var energyModeSettlingUntil = Date.distantPast
    private var restoreLidOverrideAfterWake = UserDefaults.standard.bool(forKey: "restoreLidOverrideAfterWake")
    private var lastLoginWakeSound = Date.distantPast

    var mode: ActiveMode { .resolve(hasExternalDisplay: hasExternalDisplay, isOnACPower: isOnACPower, allowOnBattery: allowOnBattery, activeModeEnabled: true) }
    var menuBarIcon: String { mode == .clamshellReady ? "display.and.arrow.down" : "display" }

    init() {
        ActiveMode.selfCheck()
        refresh()
        UserDefaults.standard.set(loginWakeSoundEnabled, forKey: "loginWakeSoundEnabled")
        if loginWakeSoundEnabled { playLoginWakeSound() }
        if dimBuiltInAtLogin { scheduleBuiltInDisplayDim() }
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.refresh() } })
        observers.append(center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.handleWake() } })
        observers.append(center.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.playLoginWakeSound() } })
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func refresh() {
        isBuiltInDisplayEnabled = Self.detectBuiltInDisplay()
        hasBuiltInDisplay = hasBuiltInDisplay || isBuiltInDisplayEnabled || Self.hasBuiltInBattery()
        hasExternalDisplay = Self.detectExternalDisplay()
        hasAirPlayDisplay = Self.detectAirPlayDisplay()
        isOnACPower = Self.detectACPower()
        let modes = Self.detectEnergyModes(hasBuiltInBattery: hasBuiltInDisplay)
        energyModeKey = modes.key
        supportsHighPowerMode = modes.key == "power"
        if Date() >= energyModeSettlingUntil {
            batteryEnergyMode = modes.battery
            adapterEnergyMode = modes.adapter
        }
        energyMode = isOnACPower ? adapterEnergyMode : batteryEnergyMode
        lidState = Self.detectLidState()
        do {
            try assertion.update(shouldBeActive: !isPreparingForSleep && hasExternalDisplay && (isOnACPower || allowOnBattery))
            assertionActive = assertion.isActive
            lidOverrideActive = (try? LidSleepOverride.isEnabled()) ?? lidOverrideActive
            errorMessage = lastActionError
        } catch { assertionActive = false; errorMessage = error.localizedDescription }
        launchAtLogin = SMAppService.mainApp.status == .enabled
        applyBuiltInDisplayPreference()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            launchAtLogin = enabled
            errorMessage = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            errorMessage = "Could not update Launch at Login: \(error.localizedDescription)"
        }
    }
    func setDimBuiltInAtLogin(_ enabled: Bool) {
        dimBuiltInAtLogin = enabled
        UserDefaults.standard.set(enabled, forKey: "dimBuiltInAtLogin")
        if enabled { dimBuiltInDisplay() }
    }
    func setDisableBuiltInDisplay(_ enabled: Bool) {
        disableBuiltInDisplay = enabled
        UserDefaults.standard.set(enabled, forKey: "disableBuiltInDisplay")
        applyBuiltInDisplayPreference()
    }
    func setLoginWakeSoundEnabled(_ enabled: Bool) {
        loginWakeSoundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "loginWakeSoundEnabled")
        if enabled { playLoginWakeSound() }
    }
    func setAllowOnBattery(_ enabled: Bool) {
        allowOnBattery = enabled
        UserDefaults.standard.set(enabled, forKey: "allowOnBattery")
        refresh()
    }
    func setLidOverrideEnabled(_ enabled: Bool) {
        lidOverrideDesired = enabled
        UserDefaults.standard.set(enabled, forKey: "lidOverrideDesired")
        do {
            try LidSleepOverride.setEnabled(enabled)
            ownsLidOverride = enabled
            lidOverrideActive = enabled
            lastActionError = nil
            refresh()
        } catch {
            lastActionError = error.localizedDescription
            refresh()
        }
    }
    func setEnergyMode(_ mode: EnergyMode, for source: EnergyPowerSource) {
        guard let energyModeKey else { return }
        energyModeRefreshTask?.cancel()
        energyModeSettlingUntil = Date().addingTimeInterval(8)
        if source == .battery { batteryEnergyMode = mode } else { adapterEnergyMode = mode }
        energyMode = isOnACPower ? adapterEnergyMode : batteryEnergyMode
        energyModeRefreshTask = Task { @MainActor [weak self] in
            do {
                try await Task.detached(priority: .userInitiated) {
                    try EnergyModeControl.set(mode, for: source, key: energyModeKey)
                }.value
                guard !Task.isCancelled, let self else { return }
                for _ in 0..<32 {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled else { return }
                    let modes = Self.detectEnergyModes(hasBuiltInBattery: self.hasBuiltInDisplay)
                    let confirmed = source == .battery ? modes.battery : modes.adapter
                    if confirmed == mode { break }
                }
                self.energyModeSettlingUntil = .distantPast
                self.lastActionError = nil
                self.errorMessage = nil
                self.refresh()
            } catch {
                guard let self else { return }
                self.energyModeSettlingUntil = .distantPast
                self.refresh()
                self.lastActionError = error.localizedDescription
                self.errorMessage = self.lastActionError
            }
        }
    }
    func stop() {
        _ = BuiltInDisplayControl.setDisabled(false)
        restoreNormalPowerBehavior()
    }
    func goToSleep() {
        guard !isPreparingForSleep else { return }
        Task { await prepareAndSleep() }
    }

    private func prepareAndSleep() async {
        isPreparingForSleep = true
        releaseAppAssertionOnly()
        let shouldRestoreLidOverride = lidOverrideDesired || lidOverrideActive
        do {
            if shouldRestoreLidOverride {
                restoreLidOverrideAfterWake = true
                UserDefaults.standard.set(true, forKey: "restoreLidOverrideAfterWake")
                try LidSleepOverride.setEnabled(false)
                for _ in 0..<20 {
                    if try !LidSleepOverride.isEnabled() { break }
                    try await Task.sleep(for: .milliseconds(100))
                }
                guard try !LidSleepOverride.isEnabled() else { throw SystemSleepError.sleepDisabled }
                lidOverrideActive = false
            }
            try SystemSleep.sleepNow()
            lastActionError = nil
        } catch {
            isPreparingForSleep = false
            if shouldRestoreLidOverride { try? restoreDesiredLidOverride() }
            lastActionError = error.localizedDescription
            refresh()
        }
    }

    private func releaseAppAssertionOnly() {
        assertion.release()
        assertionActive = false
    }

    private func dimBuiltInDisplay() {
        if let error = BuiltInDisplayBrightness.setToZero() {
            lastActionError = error
            refresh()
        } else {
            lastActionError = nil
            errorMessage = nil
        }
    }

    private func applyBuiltInDisplayPreference() {
        if disableBuiltInDisplay && hasExternalDisplay && !isBuiltInDisplayEnabled {
            lastActionError = nil
            errorMessage = nil
            return
        }
        if let error = BuiltInDisplayControl.setDisabled(disableBuiltInDisplay && hasExternalDisplay) {
            lastActionError = error
            errorMessage = error
        } else {
            lastActionError = nil
            errorMessage = nil
        }
    }

    private func restoreNormalPowerBehavior() {
        releaseAppAssertionOnly()
        lidOverrideDesired = false
        restoreLidOverrideAfterWake = false
        UserDefaults.standard.set(false, forKey: "lidOverrideDesired")
        UserDefaults.standard.set(false, forKey: "restoreLidOverrideAfterWake")
        if lidOverrideActive || ownsLidOverride {
            do {
                try LidSleepOverride.setEnabled(false)
                lidOverrideActive = false
                ownsLidOverride = false
                lastActionError = nil
            } catch {
                lastActionError = error.localizedDescription
            }
        }
    }

    private func handleWake() {
        isPreparingForSleep = false
        BuiltInDisplayControl.invalidateState()
        refresh()
        playLoginWakeSound()
        if dimBuiltInAtLogin { scheduleBuiltInDisplayDim() }
        if restoreLidOverrideAfterWake && lidOverrideDesired {
            do {
                try restoreDesiredLidOverride()
                lastActionError = nil
            } catch {
                lastActionError = error.localizedDescription
            }
            refresh()
        }
    }

    private func playLoginWakeSound() {
        guard loginWakeSoundEnabled, Date().timeIntervalSince(lastLoginWakeSound) >= 2 else { return }
        lastLoginWakeSound = Date()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
        process.arguments = ["-t", "0.07", "/System/Library/Sounds/Purr.aiff"]
        try? process.run()
    }

    private static func initialLoginWakeSoundSetting() -> Bool {
        if let saved = UserDefaults.standard.object(forKey: "loginWakeSoundEnabled") as? Bool { return saved }
        return FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/LaunchAgents/com.eky.login-beep.plist")
    }

    private func scheduleBuiltInDisplayDim() {
        dimTask?.cancel()
        dimTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, self?.dimBuiltInAtLogin == true else { return }
            self?.dimBuiltInDisplay()
        }
    }

    private func restoreDesiredLidOverride() throws {
        try LidSleepOverride.setEnabled(true)
        lidOverrideActive = true
        ownsLidOverride = true
        restoreLidOverrideAfterWake = false
        UserDefaults.standard.set(false, forKey: "restoreLidOverrideAfterWake")
    }

    private static func detectExternalDisplay() -> Bool {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else { return false }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else { return false }
        return displays.prefix(Int(count)).contains {
            CGDisplayIsBuiltin($0) == 0 && CGDisplayVendorNumber($0) != 0 && CGDisplayModelNumber($0) != 0
        }
    }
    private static func detectAirPlayDisplay() -> Bool {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else { return false }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else { return false }
        return displays.prefix(Int(count)).contains {
            CGDisplayIsBuiltin($0) == 0
                && (CGDisplayVendorNumber($0) == 0 || CGDisplayModelNumber($0) == 0)
                && (CGDisplayIsInMirrorSet($0) != 0 || CGDisplayMirrorsDisplay($0) != kCGNullDirectDisplay)
        }
    }
    private static func detectBuiltInDisplay() -> Bool {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else { return false }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else { return false }
        return displays.prefix(Int(count)).contains { CGDisplayIsBuiltin($0) != 0 }
    }
    private static func hasBuiltInBattery() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return false }
        IOObjectRelease(service)
        return true
    }
    private static func detectACPower() -> Bool {
        IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() != nil
    }
    private static func detectEnergyModes(hasBuiltInBattery: Bool) -> (battery: EnergyMode, adapter: EnergyMode, key: String?) {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "custom"]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return (.unavailable, .unavailable, nil) }
        process.waitUntilExit()
        guard process.terminationStatus == 0,
              let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else {
            return (.unavailable, .unavailable, nil)
        }

        var source: EnergyPowerSource?
        var battery: EnergyMode = .unavailable
        var adapter: EnergyMode = .unavailable
        var key: String?
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "Battery Power:" { source = .battery; continue }
            if trimmed == "AC Power:" { source = .adapter; continue }
            let parts = trimmed.split(whereSeparator: \Character.isWhitespace)
            guard parts.count >= 2, let value = Int(parts[1]) else { continue }
            let setting = String(parts[0])
            guard setting == "powermode" || setting == "lowpowermode" else { continue }
            key = setting == "powermode" ? "power" : "low"
            let mode: EnergyMode = switch value { case 1: .lowPower; case 2: .highPower; default: .automatic }
            if source == .battery { battery = mode }
            if source == .adapter { adapter = mode }
        }
        let stored = storedEnergyModes()
        if stored.battery != .unavailable { battery = stored.battery }
        if stored.adapter != .unavailable { adapter = stored.adapter }
        if let storedKey = stored.key { key = storedKey }
        if battery == .unavailable, hasBuiltInBattery, key != nil { battery = .automatic }
        return (battery, adapter, key)
    }
    private static func storedEnergyModes() -> (battery: EnergyMode, adapter: EnergyMode, key: String?) {
        let directory = URL(fileURLWithPath: "/Library/Preferences", isDirectory: true)
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("com.apple.PowerManagement.") && file.pathExtension == "plist" {
            guard let data = try? Data(contentsOf: file),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
                  let profiles = plist as? [String: Any] else { continue }
            let battery = storedEnergyMode(in: profiles["Battery Power"])
            let adapter = storedEnergyMode(in: profiles["AC Power"])
            if battery.mode != .unavailable || adapter.mode != .unavailable {
                return (battery.mode, adapter.mode, battery.key ?? adapter.key)
            }
        }
        return (.unavailable, .unavailable, nil)
    }
    private static func storedEnergyMode(in profile: Any?) -> (mode: EnergyMode, key: String?) {
        guard let settings = profile as? [String: Any] else { return (.unavailable, nil) }
        let pair: (Any?, String) = settings["PowerMode"] != nil
            ? (settings["PowerMode"], "power")
            : (settings["LowPowerMode"], "low")
        guard let value = pair.0 as? NSNumber else { return (.unavailable, nil) }
        let mode: EnergyMode = switch value.intValue { case 1: .lowPower; case 2: .highPower; default: .automatic }
        return (mode, pair.1)
    }
    private static func detectLidState() -> LidState {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { return .unavailable }
        defer { IOObjectRelease(service) }
        guard let value = IORegistryEntryCreateCFProperty(service, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool else { return .unavailable }
        return value ? .closed : .open
    }
}
