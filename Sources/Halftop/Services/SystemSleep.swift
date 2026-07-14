import Foundation
import IOKit.pwr_mgt

enum SystemSleepError: LocalizedError {
    case serviceUnavailable
    case sleepFailed(IOReturn)
    case sleepDisabled

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            "Could not put the system to sleep: power-management service is unavailable."
        case .sleepDisabled:
            "Could not put the system to sleep while Ignore Lid Close is still active. Turn it off, then try again."
        case .sleepFailed(let code):
            "Could not put the system to sleep (IOKit: \(code))."
        }
    }
}

struct SystemSleep {
    static func sleepNow() throws {
        let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        guard port != 0 else { throw SystemSleepError.serviceUnavailable }
        defer { IOServiceClose(port) }

        let result = IOPMSleepSystem(port)
        if UInt32(bitPattern: result) == 0xe00002e2 { throw SystemSleepError.sleepDisabled }
        guard result == kIOReturnSuccess else { throw SystemSleepError.sleepFailed(result) }
    }
}
