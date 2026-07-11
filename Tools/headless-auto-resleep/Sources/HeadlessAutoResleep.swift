import AppKit
import CoreGraphics
import Foundation
import IOKit

let delaySeconds: TimeInterval = 3.0
let initialSampleIntervalSeconds: TimeInterval = 0.25
let initialInputIgnoreSeconds: TimeInterval = 1.0
let actionIdleThresholdSeconds: TimeInterval = 0.75
let stuckKeyObservationSeconds: TimeInterval = 3.0
let stuckKeySampleIntervalSeconds: TimeInterval = 0.5
let stuckKeyIdleThresholdSeconds: TimeInterval = 0.5
let minDecisionGapSeconds: TimeInterval = 8.0
let logURL = URL(fileURLWithPath: NSHomeDirectory())
    .appendingPathComponent("Library/Logs/headless-auto-resleep.log")

var lastDecisionAt = Date.distantPast

func log(_ message: String) {
    let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logURL.path),
           let handle = try? FileHandle(forWritingTo: logURL) {
            _ = try? handle.seekToEnd()
            _ = try? handle.write(contentsOf: data)
            _ = try? handle.close()
        } else {
            try? FileManager.default.createDirectory(
                at: logURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: logURL)
        }
    }
}

func run(_ executable: String, _ arguments: [String] = [], wait: Bool = true) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    do {
        try process.run()
        if wait {
            process.waitUntilExit()
        }
    } catch {
        log("failed to run \(executable): \(error)")
    }
}

func say(_ phrase: String) {
    run("/usr/bin/say", [phrase])
}

func beep() {
    run("/usr/bin/afplay", ["-t", "0.15", "/System/Library/Sounds/Purr.aiff"])
}

func hidIdleSeconds() -> TimeInterval? {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
    guard service != 0 else { return nil }
    defer { IOObjectRelease(service) }

    let key = "HIDIdleTime" as CFString
    guard let value = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0)?
        .takeRetainedValue() as? NSNumber else {
        return nil
    }

    return value.doubleValue / 1_000_000_000
}

func screenIsLocked() -> Bool {
    guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
    return (dict["CGSSessionScreenIsLocked"] as? Bool) == true
}

func hasExternalDisplay() -> Bool {
    var count: UInt32 = 0
    CGGetOnlineDisplayList(0, nil, &count)
    guard count > 0 else { return false }

    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    let result = CGGetOnlineDisplayList(count, &displays, &count)
    guard result == .success else { return false }

    return displays.prefix(Int(count)).contains { display in
        CGDisplayIsActive(display) != 0 && CGDisplayIsBuiltin(display) == 0
    }
}

func observeStuckKeyThenDecide() {
    DispatchQueue.global(qos: .utility).async {
        let sampleCount = max(1, Int(stuckKeyObservationSeconds / stuckKeySampleIntervalSeconds))
        var stuckSamples = 0

        for _ in 0..<sampleCount {
            Thread.sleep(forTimeInterval: stuckKeySampleIntervalSeconds)
            if let idle = hidIdleSeconds(), idle < stuckKeyIdleThresholdSeconds {
                stuckSamples += 1
            }
        }

        let stillLocked = screenIsLocked()
        let externalDisplay = hasExternalDisplay()
        let stuckKeyLikely = stuckSamples >= sampleCount - 1

        DispatchQueue.main.async {
            if !stillLocked {
                log("unlocked: no speech after input watch, stuckSamples=\(stuckSamples)/\(sampleCount)")
                return
            }

            if externalDisplay {
                log("waking up: after input watch externalDisplay=true stuckSamples=\(stuckSamples)/\(sampleCount)")
                say("waking up")
                return
            }

            if stuckKeyLikely {
                log("auto re-sleep: stuck key likely, stuckSamples=\(stuckSamples)/\(sampleCount)")
                beep()
                run("/usr/bin/pmset", ["sleepnow"])
                return
            }

            log("waking up: input did not look stuck, stuckSamples=\(stuckSamples)/\(sampleCount)")
            say("waking up")
        }
    }
}

func observeInitialWakeThenDecide(lockedAtWake: Bool) {
    DispatchQueue.global(qos: .utility).async {
        let sampleCount = max(1, Int(delaySeconds / initialSampleIntervalSeconds))
        var inputSeen = false
        var lastIdle: TimeInterval?

        for index in 0..<sampleCount {
            Thread.sleep(forTimeInterval: initialSampleIntervalSeconds)
            let elapsed = Double(index + 1) * initialSampleIntervalSeconds
            lastIdle = hidIdleSeconds()

            if elapsed >= initialInputIgnoreSeconds,
               let idle = lastIdle,
               idle < actionIdleThresholdSeconds {
                inputSeen = true
            }
        }

        let externalDisplay = hasExternalDisplay()
        let lockedNow = screenIsLocked()
        let unlockedAfterWake = lockedAtWake && !lockedNow

        DispatchQueue.main.async {
            if !lockedNow {
                log("unlocked: no speech, unlockedAfterWake=\(unlockedAfterWake) idle=\(lastIdle.map(String.init(describing:)) ?? "unknown")")
                return
            }

            if externalDisplay {
                log("waking up: externalDisplay=true idle=\(lastIdle.map(String.init(describing:)) ?? "unknown")")
                say("waking up")
                return
            }

            if inputSeen {
                log("watching input: possible stuck key, idle=\(lastIdle.map(String.init(describing:)) ?? "unknown")")
                observeStuckKeyThenDecide()
                return
            }

            log("auto re-sleep: no action, no external display, idle=\(lastIdle.map(String.init(describing:)) ?? "unknown")")
            say("auto re-sleep")
            run("/usr/bin/pmset", ["sleepnow"])
        }
    }
}

func decideAfterWake() {
    let now = Date()
    guard now.timeIntervalSince(lastDecisionAt) >= minDecisionGapSeconds else { return }
    lastDecisionAt = now
    let lockedAtWake = screenIsLocked()
    observeInitialWakeThenDecide(lockedAtWake: lockedAtWake)
}

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: .main
) { _ in
    decideAfterWake()
}

log("HeadlessAutoResleep started")
RunLoop.main.run()
