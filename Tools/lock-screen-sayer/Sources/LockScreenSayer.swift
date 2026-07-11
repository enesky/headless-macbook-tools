import Foundation

let phrase = CommandLine.arguments.dropFirst().joined(separator: " ").isEmpty
    ? "Lock Screen"
    : CommandLine.arguments.dropFirst().joined(separator: " ")

var lastSpokenAt = Date.distantPast

func speak() {
    let now = Date()
    guard now.timeIntervalSince(lastSpokenAt) > 2 else { return }
    lastSpokenAt = now

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
    process.arguments = [phrase]

    do {
        try process.run()
    } catch {
        NSLog("LockScreenSayer failed to run say: \(error)")
    }
}

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsLocked"),
    object: nil,
    queue: .main
) { _ in
    speak()
}

RunLoop.main.run()
