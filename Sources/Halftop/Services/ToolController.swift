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
        case .sideScreenWireless: "Start SideScreen WiFi"
        }
    }

    var spokenTitle: String {
        switch self {
        case .airPlay: title
        case .sideScreenUSB: "SideScreen USB"
        case .sideScreenWireless: "SideScreen WiFi"
        }
    }

    var script: (folder: String, file: String) {
        switch self {
        case .airPlay: ("Auto-Airplay", "run-airplay.sh")
        case .sideScreenUSB: ("Auto-SideScreen-USB", "SideScreen-usb.sh")
        case .sideScreenWireless: ("Auto-SideScreen-USB", "SideScreen-wireless.sh")
        }
    }

    var requiresSideScreen: Bool {
        switch self {
        case .airPlay: false
        case .sideScreenUSB, .sideScreenWireless: true
        }
    }
}

struct SideScreenInstallation: Equatable, Sendable {
    let appURL: URL?
    let version: String?
    let isQuarantined: Bool

    static let minimumVersion = "0.11.0"
    static let releasesURL = URL(string: "https://github.com/tranvuongquocdat/SideScreen/releases/latest")!
    static let releaseURL = releasesURL

    var isInstalled: Bool { appURL != nil }
    var isSupported: Bool {
        guard let version else { return false }
        return version.compare(Self.minimumVersion, options: .numeric) != .orderedAscending
    }

    var statusText: String {
        if let version {
            isSupported ? "SideScreen \(version)" : "SideScreen \(version) installed, update required"
        } else if isInstalled {
            "SideScreen installed"
        } else {
            "SideScreen not installed"
        }
    }

    var summaryText: String {
        if !isInstalled { return "Not Installed" }
        return isSupported ? "Installed" : "Update Required"
    }

    var availabilityKey: String {
        "\(appURL?.path ?? "none")|\(version ?? "none")|\(isQuarantined)"
    }

    static func detect() -> SideScreenInstallation {
        let standardURL = URL(fileURLWithPath: "/Applications/SideScreen.app")
        let workspaceURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.sidescreen.app")
        let appURL = [standardURL, workspaceURL].compactMap { $0 }.first { isUsableAppURL($0) }
        let version = appURL
            .flatMap(Bundle.init(url:))?
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return SideScreenInstallation(appURL: appURL, version: version, isQuarantined: appURL.map(hasQuarantineAttribute) ?? false)
    }

    private static func isUsableAppURL(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path) && !url.path.contains("/.Trash/")
    }

    private static func hasQuarantineAttribute(_ url: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-p", "com.apple.quarantine", url.path]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
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
    @Published private(set) var sideScreen = SideScreenInstallation.detect()
    private var gatekeeperFixInProgress = false

    let services = [
        ManagedService(id: "com.eky.halftop.headless-auto-resleep", title: "Automatic Re-Sleep", folder: "headless-auto-resleep", installer: "install.sh", uninstaller: "uninstall.sh", installArgument: nil),
        ManagedService(id: "com.eky.halftop.bag-sleep-guard", title: "Bag Sleep Guard", folder: "bag-sleep-guard", installer: "install.sh", uninstaller: "uninstall.sh", installArgument: nil),
        ManagedService(id: "com.eky.halftop.sidescreen-login", title: "Launch SideScreen at Login", folder: "Auto-SideScreen-USB", installer: "install-login.sh", uninstaller: "uninstall-login.sh", installArgument: nil),
        ManagedService(id: "com.eky.halftop.battery-voice-alert", title: "Low Battery Voice Alert", folder: "Battery Voice Alert", installer: "Halftop", uninstaller: nil, installArgument: "install"),
        ManagedService(id: "com.eky.halftop.lock-screen-sayer", title: "Lock Screen Voice Alert", folder: "lock-screen-sayer", installer: "install.sh", uninstaller: "uninstall.sh", installArgument: nil)
    ]

    init() { refreshServices() }

    func run(_ action: ToolAction) {
        if action.requiresSideScreen {
            runSideScreenAction(action)
            return
        }
        do {
            try Self.launch(script: action.script.file, in: action.script.folder)
            lastMessage = "\(action.title) started"
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    private func runSideScreenAction(_ action: ToolAction) {
        do {
            try Self.validate(action)
        } catch {
            lastMessage = error.localizedDescription
            return
        }

        Self.playActionPrelude(action.spokenTitle)
        lastMessage = "\(action.title) starting"
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            do {
                try Self.launch(script: action.script.file, in: action.script.folder)
                lastMessage = "\(action.title) started"
            } catch {
                lastMessage = error.localizedDescription
            }
        }
    }

    func run(url: URL) {
        guard url.scheme == "halftop",
              let action = ToolAction(rawValue: url.host ?? "") else { return }
        run(action)
    }

    func refreshServices() {
        refreshSideScreen()
        for service in services {
            serviceStates[service.id] = Self.isLoaded(service.id)
        }
    }

    func refreshSideScreen() {
        let detected = SideScreenInstallation.detect()
        if detected != sideScreen {
            sideScreen = detected
        }
        fixSideScreenGatekeeperIfNeeded()
    }

    func fixSideScreenGatekeeper() {
        fixSideScreenGatekeeperIfNeeded(reportStatus: true)
    }

    private func fixSideScreenGatekeeperIfNeeded(reportStatus: Bool = false) {
        guard !gatekeeperFixInProgress,
              sideScreen.isSupported,
              sideScreen.isQuarantined,
              let appURL = sideScreen.appURL else { return }
        gatekeeperFixInProgress = true
        if reportStatus {
            lastMessage = "Fixing SideScreen Gatekeeper..."
        }
        Task {
            do {
                try await Self.removeQuarantine(from: appURL)
                if reportStatus {
                    lastMessage = "SideScreen Gatekeeper fixed"
                }
            } catch {
                lastMessage = error.localizedDescription
            }
            gatekeeperFixInProgress = false
            refreshSideScreen()
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

    static func launch(_ action: ToolAction) throws {
        try validate(action)
        if action.requiresSideScreen {
            playActionPrelude(action.spokenTitle)
            Thread.sleep(forTimeInterval: 3)
        }
        let item = action.script
        try launch(script: item.file, in: item.folder)
    }

    private static func validate(_ action: ToolAction) throws {
        if action.requiresSideScreen {
            let sideScreen = SideScreenInstallation.detect()
            guard sideScreen.isSupported else { throw ToolError.sideScreenUnavailable(sideScreen.statusText) }
        }
    }

    private static func playActionPrelude(_ phrase: String) {
        let beep = Process()
        beep.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
        beep.arguments = ["-t", "0.07", "/System/Library/Sounds/Funk.aiff"]
        try? beep.run()

        let speech = Process()
        speech.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        speech.arguments = [phrase]
        try? speech.run()
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

    private nonisolated static func removeQuarantine(from appURL: URL) async throws {
        do {
            try runXattr(appURL)
        } catch {
            try runXattrWithAdminPrompt(appURL)
        }
    }

    private nonisolated static func runXattr(_ appURL: URL) throws {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-cr", appURL.path]
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ToolError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private nonisolated static func runXattrWithAdminPrompt(_ appURL: URL) throws {
        let command = "/usr/bin/xattr -cr \(shellQuote(appURL.path))"
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "do shell script \(appleScriptQuote(command)) with administrator privileges"]
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ToolError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private nonisolated static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private nonisolated static func appleScriptQuote(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
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
    case sideScreenUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .missingResources: "The Tools folder is missing from the application bundle."
        case .commandFailed(let output): output.isEmpty ? "The command could not be run." : output
        case .sideScreenUnavailable(let status): "\(status). Install SideScreen 0.11.0 or newer."
        }
    }
}
