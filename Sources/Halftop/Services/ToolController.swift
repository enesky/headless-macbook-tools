import AppKit
import Combine
import Foundation

enum ToolAction: String, CaseIterable, Sendable {
    case airPlay = "airplay"
    case sideScreenUSB = "sidescreen-usb"
    case sideScreenWireless = "sidescreen-wireless"

    var title: String {
        switch self {
        case .airPlay: "Start Auto AirPlay"
        case .sideScreenUSB: "Start SideScreen USB"
        case .sideScreenWireless: "Start SideScreen Wireless"
        }
    }

    var script: (folder: String, file: String) {
        switch self {
        case .airPlay: ("Auto-Airplay", "run-airplay.sh")
        case .sideScreenUSB: ("Auto-SideScreen-USB", "SideScreen-usb.sh")
        case .sideScreenWireless: ("Auto-SideScreen-USB", "SideScreen-wireless.sh")
        }
    }
}

struct ManagedService: Identifiable, Sendable {
    let id: String
    let title: String
    let folder: String
    let installer: String
    let uninstaller: String?
    let installArgument: String?
}

@MainActor final class ToolController: ObservableObject {
    @Published private(set) var lastMessage: String?
    @Published private(set) var busyService: String?
    @Published private(set) var serviceStates: [String: Bool] = [:]

    let services = [
        ManagedService(id: "com.eky.halftop.headless-auto-resleep", title: "Automatic Re-Sleep", folder: "headless-auto-resleep", installer: "install.sh", uninstaller: "uninstall.sh", installArgument: nil),
        ManagedService(id: "com.eky.halftop.bag-sleep-guard", title: "Bag Sleep Guard", folder: "bag-sleep-guard", installer: "install.sh", uninstaller: "uninstall.sh", installArgument: nil),
        ManagedService(id: "com.eky.halftop.battery-voice-alert", title: "Low Battery Voice Alert", folder: "Battery Voice Alert", installer: "Halftop", uninstaller: nil, installArgument: "install"),
        ManagedService(id: "com.eky.halftop.lock-screen-sayer", title: "Lock Screen Voice Alert", folder: "lock-screen-sayer", installer: "install.sh", uninstaller: "uninstall.sh", installArgument: nil)
    ]

    init() { refreshServices() }

    func run(_ action: ToolAction) {
        do {
            try Self.launch(script: action.script.file, in: action.script.folder)
            lastMessage = "\(action.title) started"
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    func run(url: URL) {
        guard url.scheme == "halftop",
              let action = ToolAction(rawValue: url.host ?? "") else { return }
        run(action)
    }

    func refreshServices() {
        for service in services {
            serviceStates[service.id] = Self.isLoaded(service.id)
        }
    }

    func set(_ service: ManagedService, enabled: Bool) {
        busyService = service.id
        Task {
            do {
                if enabled {
                    try await Self.execute(script: service.installer, in: service.folder, argument: service.installArgument)
                } else if let uninstaller = service.uninstaller {
                    try await Self.execute(script: uninstaller, in: service.folder, argument: nil)
                } else {
                    try await Self.execute(script: service.installer, in: service.folder, argument: "uninstall")
                }
                lastMessage = "\(service.title): \(enabled ? "on" : "off")"
            } catch {
                lastMessage = error.localizedDescription
            }
            busyService = nil
            refreshServices()
        }
    }

    nonisolated static func launch(_ action: ToolAction) throws {
        let item = action.script
        try launch(script: item.file, in: item.folder)
    }

    private nonisolated static func subAppsURL() throws -> URL {
        let url = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Tools", isDirectory: true)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ToolError.missingResources
        }
        return url
    }

    private nonisolated static func launch(script: String, in folder: String) throws {
        let directory = try subAppsURL().appendingPathComponent(folder, isDirectory: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [directory.appendingPathComponent(script).path]
        process.currentDirectoryURL = directory
        try process.run()
    }

    private nonisolated static func execute(script: String, in folder: String, argument: String?) async throws {
        let directory = try subAppsURL().appendingPathComponent(folder, isDirectory: true)
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [directory.appendingPathComponent(script).path] + (argument.map { [$0] } ?? [])
        process.currentDirectoryURL = directory
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ToolError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private nonisolated static func isLoaded(_ label: String) -> Bool {
        guard let feature = label.split(separator: ".").last else { return false }
        let marker = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Halftop/Agents/.enabled/\(feature)")
        return FileManager.default.fileExists(atPath: marker.path)
    }
}

enum ToolError: LocalizedError {
    case missingResources
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingResources: "The Tools folder is missing from the application bundle."
        case .commandFailed(let output): output.isEmpty ? "The command could not be run." : output
        }
    }
}
