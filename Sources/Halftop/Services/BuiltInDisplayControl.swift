import CoreGraphics
import Darwin

@MainActor enum BuiltInDisplayControl {
    private typealias ConfigureEnabled = @convention(c) (CGDisplayConfigRef, CGDirectDisplayID, Bool) -> CGError
    private static var displayID: CGDirectDisplayID?
    private static var isDisabled = false

    static func setDisabled(_ disabled: Bool) -> String? {
        guard disabled != isDisabled else { return nil }
        guard let configureEnabled = loadConfigureEnabled() else {
            return "Built-in display control is unavailable on this macOS version."
        }

        if disabled {
            guard let builtIn = onlineBuiltInDisplay() else { return "Could not find the built-in display." }
            displayID = builtIn
        }
        guard let displayID else { return disabled ? "Could not find the built-in display." : nil }

        var configuration: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&configuration) == .success, let configuration else {
            return "Could not begin display configuration."
        }
        guard configureEnabled(configuration, displayID, !disabled) == .success,
              CGCompleteDisplayConfiguration(configuration, .forSession) == .success else {
            CGCancelDisplayConfiguration(configuration)
            return disabled ? "Could not disable the built-in display." : "Could not enable the built-in display."
        }

        isDisabled = disabled
        return nil
    }

    static func invalidateState() {
        isDisabled = false
    }

    private static func onlineBuiltInDisplay() -> CGDirectDisplayID? {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else { return nil }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else { return nil }
        return displays.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 }
    }

    private static func loadConfigureEnabled() -> ConfigureEnabled? {
        let path = "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"
        guard let library = dlopen(path, RTLD_NOW), let symbol = dlsym(library, "CGSConfigureDisplayEnabled") else {
            return nil
        }
        return unsafeBitCast(symbol, to: ConfigureEnabled.self)
    }
}
