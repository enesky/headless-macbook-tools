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
    @Published private(set) var isOnACPower = false
    @Published private(set) var lidState: LidState = .unavailable
    @Published private(set) var assertionActive = false
    @Published private(set) var lidOverrideActive = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var dimBuiltInAtLogin = UserDefaults.standard.bool(forKey: "dimBuiltInAtLogin")
    @Published private(set) var allowOnBattery = UserDefaults.standard.bool(forKey: "allowOnBattery")
    @Published private(set) var lidOverrideDesired = UserDefaults.standard.bool(forKey: "lidOverrideDesired")
    private let assertion = PowerAssertion()
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var ownsLidOverride = false
    private var lastActionError: String?
    private var restoreLidOverrideAfterWake = UserDefaults.standard.bool(forKey: "restoreLidOverrideAfterWake")

    var mode: ActiveMode { .resolve(hasExternalDisplay: hasExternalDisplay, isOnACPower: isOnACPower, allowOnBattery: allowOnBattery, activeModeEnabled: true) }
    var menuBarIcon: String { mode == .clamshellReady ? "display.and.arrow.down" : "display" }

    init() {
        ActiveMode.selfCheck()
        refresh()
        if dimBuiltInAtLogin { dimBuiltInDisplay() }
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.refresh() } })
        observers.append(center.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.handleWake() } })
        timer = .scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in Task { @MainActor in self?.refresh() } }
    }

    func refresh() {
        hasBuiltInDisplay = Self.detectBuiltInDisplay()
        hasExternalDisplay = Self.detectExternalDisplay()
        hasAirPlayDisplay = Self.detectAirPlayDisplay()
        isOnACPower = Self.detectACPower()
        lidState = Self.detectLidState()
        do {
            try assertion.update(shouldBeActive: hasExternalDisplay && (isOnACPower || allowOnBattery))
            assertionActive = assertion.isActive
            lidOverrideActive = (try? LidSleepOverride.isEnabled()) ?? lidOverrideActive
            errorMessage = lastActionError
        } catch { assertionActive = false; errorMessage = error.localizedDescription }
        launchAtLogin = SMAppService.mainApp.status == .enabled
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
    func stop() {
        restoreNormalPowerBehavior()
    }
    func goToSleep() {
        releaseAppAssertionOnly()
        let shouldRestoreLidOverride = lidOverrideDesired || lidOverrideActive
        do {
            if shouldRestoreLidOverride {
                restoreLidOverrideAfterWake = true
                UserDefaults.standard.set(true, forKey: "restoreLidOverrideAfterWake")
                try LidSleepOverride.setEnabled(false)
                lidOverrideActive = false
            }
            try SystemSleep.sleepNow()
            lastActionError = nil
        } catch {
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
        refresh()
        if dimBuiltInAtLogin { dimBuiltInDisplay() }
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
    private static func detectACPower() -> Bool {
        IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() != nil
    }
    private static func detectLidState() -> LidState {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { return .unavailable }
        defer { IOObjectRelease(service) }
        guard let value = IORegistryEntryCreateCFProperty(service, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool else { return .unavailable }
        return value ? .closed : .open
    }
}
