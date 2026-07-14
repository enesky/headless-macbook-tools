import Darwin
import Foundation

enum LidHelperInstaller {
    private static let label = "com.eky.halftop.lid-daemon"
    private static let installPath = "/usr/local/libexec/Halftop Privileged Helper"
    private static let plistPath = "/Library/LaunchDaemons/\(label).plist"
    private static let socketPath = "/var/run/halftop-lid-helper.sock"

    static func install() throws {
        let source = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/PrivilegedHelpers/Halftop Privileged Helper")
            .path

        guard FileManager.default.isExecutableFile(atPath: source) else {
            throw LidSleepOverrideError.commandFailed("privileged helper is missing from the app bundle")
        }

        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Halftop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let plistURL = tempDirectory.appendingPathComponent("com.eky.halftop.lid-daemon.plist")
        let scriptURL = tempDirectory.appendingPathComponent("install-lid-daemon.sh")

        try launchDaemonPlist(allowedUID: getuid()).write(to: plistURL, atomically: true, encoding: .utf8)
        try installScript(source: source, plist: plistURL.path).write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)

        try run("/usr/bin/osascript", [
            "-e",
            #"do shell script "/bin/sh " & quoted form of "\#(scriptURL.path)" with administrator privileges"#
        ])
        for _ in 0..<40 {
            if FileManager.default.fileExists(atPath: socketPath) { return }
            usleep(50_000)
        }
        throw LidSleepOverrideError.helperUnavailable
    }

    private static func launchDaemonPlist(allowedUID: uid_t) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>\(label)</string>
          <key>ProgramArguments</key>
          <array>
            <string>\(installPath)</string>
            <string>--allowed-uid</string>
            <string>\(allowedUID)</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
          <key>StandardOutPath</key>
          <string>/var/log/Halftop.log</string>
          <key>StandardErrorPath</key>
          <string>/var/log/Halftop.log</string>
        </dict>
        </plist>
        """
    }

    private static func installScript(source: String, plist: String) -> String {
        """
        #!/bin/sh
        set -eu

        /bin/mkdir -p /usr/local/libexec
        /bin/launchctl bootout system /Library/LaunchDaemons/com.eky.ClamshellReady.LidDaemon.plist >/dev/null 2>&1 || true
        /bin/launchctl bootout system /Library/LaunchDaemons/com.eky.Halftop.LidDaemon.plist >/dev/null 2>&1 || true
        /bin/rm -f /Library/LaunchDaemons/com.eky.ClamshellReady.LidDaemon.plist /Library/LaunchDaemons/com.eky.Halftop.LidDaemon.plist /usr/local/libexec/clamshell-ready-lid-daemon /usr/local/libexec/Halftop /var/run/clamshell-ready-lid-helper.sock
        /usr/bin/install -o root -g wheel -m 0755 \(source.shellQuoted) \(installPath.shellQuoted)
        /usr/bin/install -o root -g wheel -m 0644 \(plist.shellQuoted) \(plistPath.shellQuoted)

        if /bin/launchctl print system/\(label.shellQuoted) >/dev/null 2>&1; then
            /bin/launchctl bootout system \(plistPath.shellQuoted) >/dev/null 2>&1 || true
        fi

        /bin/launchctl bootstrap system \(plistPath.shellQuoted)
        /bin/launchctl enable system/\(label.shellQuoted)
        """
    }

    @discardableResult
    private static func run(_ executable: String, _ arguments: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            throw LidSleepOverrideError.commandFailed(output.isEmpty ? "exit code \(process.terminationStatus)" : output)
        }

        return output
    }
}

private extension String {
    var shellQuoted: String {
        "'\(replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
