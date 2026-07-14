enum LidState: Equatable, Sendable {
    case open, closed, unavailable
    var text: String { switch self { case .open: "Open"; case .closed: "Closed"; case .unavailable: "Not Connected" } }
}

enum EnergyMode: Hashable, Sendable, CaseIterable {
    case automatic, lowPower, highPower, unavailable

    static var configurable: [Self] { [.lowPower, .automatic, .highPower] }

    var text: String {
        switch self {
        case .automatic: "Automatic"
        case .lowPower: "Low Power"
        case .highPower: "High Power"
        case .unavailable: "Unavailable"
        }
    }
}

enum EnergyPowerSource: Sendable {
    case battery, adapter

    var title: String { self == .battery ? "On Battery" : "On Power Adapter" }
    var helperKey: String { self == .battery ? "b" : "c" }
}

enum ActiveMode: Equatable, Sendable {
    case normal, clamshellReady, noExternalDisplay
    static func resolve(hasExternalDisplay: Bool, isOnACPower: Bool, allowOnBattery: Bool, activeModeEnabled: Bool) -> Self {
        if !activeModeEnabled { return .normal }
        if !hasExternalDisplay { return .noExternalDisplay }
        return isOnACPower || allowOnBattery ? .clamshellReady : .normal
    }
    static func selfCheck() {
        assert(resolve(hasExternalDisplay: false, isOnACPower: false, allowOnBattery: true, activeModeEnabled: true) == .noExternalDisplay)
        assert(resolve(hasExternalDisplay: true, isOnACPower: false, allowOnBattery: false, activeModeEnabled: true) == .normal)
        assert(resolve(hasExternalDisplay: true, isOnACPower: false, allowOnBattery: true, activeModeEnabled: true) == .clamshellReady)
        assert(resolve(hasExternalDisplay: true, isOnACPower: true, allowOnBattery: false, activeModeEnabled: true) == .clamshellReady)
        assert(resolve(hasExternalDisplay: true, isOnACPower: true, allowOnBattery: false, activeModeEnabled: false) == .normal)
    }
    var text: String { switch self { case .normal: "Normal"; case .clamshellReady: "Clamshell Ready"; case .noExternalDisplay: "No external display" } }
}
