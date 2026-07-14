import Foundation
import IOKit.pwr_mgt

@MainActor final class PowerAssertion {
    private var id = IOPMAssertionID(kIOPMNullAssertionID)
    var isActive: Bool { id != kIOPMNullAssertionID }

    func update(shouldBeActive: Bool) throws {
        if shouldBeActive == isActive { return }
        if shouldBeActive {
            var newID = IOPMAssertionID(kIOPMNullAssertionID)
            let result = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventSystemSleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), "Halftop Clamshell Ready is active" as CFString, &newID)
            guard result == kIOReturnSuccess else { throw AssertionError.creationFailed(result) }
            id = newID
        } else { release() }
    }

    func release() {
        guard isActive else { return }
        IOPMAssertionRelease(id)
        id = IOPMAssertionID(kIOPMNullAssertionID)
    }
    deinit { if id != kIOPMNullAssertionID { IOPMAssertionRelease(id) } }
}

enum AssertionError: LocalizedError {
    case creationFailed(IOReturn)
    var errorDescription: String? {
        switch self { case .creationFailed(let code): "Could not create sleep-prevention assertion (IOKit: \(code)). Check system security settings." }
    }
}
