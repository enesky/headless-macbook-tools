import CoreGraphics
import Darwin

enum BuiltInDisplayBrightness {
    private typealias Setter = @convention(c) (CGDirectDisplayID, Float) -> Int32

    static func setToZero() -> String? {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let library = dlopen(path, RTLD_NOW),
              let symbol = dlsym(library, "DisplayServicesSetBrightness") else {
            return "Brightness control is unavailable on this macOS version."
        }
        defer { dlclose(library) }

        let setBrightness = unsafeBitCast(symbol, to: Setter.self)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else {
            return "Could not find the built-in display."
        }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else {
            return "Could not find the built-in display."
        }

        guard let display = displays.prefix(Int(count)).first(where: { CGDisplayIsBuiltin($0) != 0 }) else {
            return "Could not find the built-in display."
        }
        guard setBrightness(display, 0) == 0 else { return "Could not dim the built-in display." }
        return nil
    }
}
