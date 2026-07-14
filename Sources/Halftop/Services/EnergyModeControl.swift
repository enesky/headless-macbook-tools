import Foundation

enum EnergyModeControl {
    static func set(_ mode: EnergyMode, for source: EnergyPowerSource, key: String) throws {
        let value = switch mode {
        case .automatic: "0"
        case .lowPower: "1"
        case .highPower: "2"
        case .unavailable: throw EnergyModeControlError.unsupported
        }
        guard key == "power" || (key == "low" && mode != .highPower) else {
            throw EnergyModeControlError.unsupported
        }
        let command = "energy-\(source.helperKey)-\(key)-\(value)"
        do {
            try LidHelperClient.send(command)
        } catch LidSleepOverrideError.helperUnavailable {
            try LidHelperInstaller.install()
            try send(command)
        } catch LidSleepOverrideError.commandFailed(let message) where message.contains("invalid command") {
            try LidHelperInstaller.install()
            try send(command)
        } catch {
            throw EnergyModeControlError.commandFailed(error.localizedDescription)
        }
    }

    private static func send(_ command: String) throws {
        do { try LidHelperClient.send(command) }
        catch { throw EnergyModeControlError.commandFailed(error.localizedDescription) }
    }
}

enum EnergyModeControlError: LocalizedError {
    case unsupported
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupported: "This energy mode is not supported by this Mac."
        case .commandFailed(let message): "Could not change Energy Mode: \(message)"
        }
    }
}
