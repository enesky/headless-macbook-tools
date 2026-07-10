import Foundation
import IOKit.pwr_mgt

enum SystemSleepError: LocalizedError {
    case serviceUnavailable
    case sleepFailed(IOReturn)

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            "Could not put the system to sleep: power-management service is unavailable."
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
        guard result == kIOReturnSuccess else { throw SystemSleepError.sleepFailed(result) }
    }
}
