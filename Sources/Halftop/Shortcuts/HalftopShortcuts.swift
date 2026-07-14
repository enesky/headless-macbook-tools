import AppIntents

struct RunHalftopToolIntent: AppIntent {
    static let title: LocalizedStringResource = "Run Halftop Tool"
    static let description = IntentDescription("Runs an AirPlay or SideScreen action through Halftop.")

    @Parameter(title: "Action") var action: ShortcutAction

    func perform() async throws -> some IntentResult {
        try ToolController.launch(action.toolAction)
        return .result()
    }
}

enum ShortcutAction: String, AppEnum {
    case airPlay, sideScreenUSB, sideScreenWireless

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Halftop Action")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .airPlay: "Start Auto AirPlay",
        .sideScreenUSB: "Start SideScreen USB",
        .sideScreenWireless: "Start SideScreen Wireless"
    ]

    var toolAction: ToolAction {
        switch self {
        case .airPlay: .airPlay
        case .sideScreenUSB: .sideScreenUSB
        case .sideScreenWireless: .sideScreenWireless
        }
    }
}

struct HalftopAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RunHalftopToolIntent(action: .airPlay),
            phrases: ["Start AirPlay with \(.applicationName)"],
            shortTitle: "Start AirPlay",
            systemImageName: "airplayvideo"
        )
        AppShortcut(
            intent: RunHalftopToolIntent(action: .sideScreenUSB),
            phrases: ["Start SideScreen USB with \(.applicationName)"],
            shortTitle: "SideScreen USB",
            systemImageName: "cable.connector"
        )
    }
}

private extension RunHalftopToolIntent {
    init(action: ShortcutAction) {
        self.init()
        self.action = action
    }
}
