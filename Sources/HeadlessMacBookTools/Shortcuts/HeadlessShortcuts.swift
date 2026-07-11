import AppIntents

struct RunHeadlessToolIntent: AppIntent {
    static let title: LocalizedStringResource = "Run Headless Tool"
    static let description = IntentDescription("Runs an AirPlay or SideScreen action through Headless MacBook Tools.")

    @Parameter(title: "Action") var action: ShortcutAction

    func perform() async throws -> some IntentResult {
        try ToolController.launch(action.toolAction)
        return .result()
    }
}

enum ShortcutAction: String, AppEnum {
    case airPlay, sideScreenUSB, sideScreenWireless

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Headless Action")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .airPlay: "Connect to AirPlay Display",
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

struct HeadlessAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RunHeadlessToolIntent(action: .airPlay),
            phrases: ["Start AirPlay with \(.applicationName)"],
            shortTitle: "Start AirPlay",
            systemImageName: "airplayvideo"
        )
        AppShortcut(
            intent: RunHeadlessToolIntent(action: .sideScreenUSB),
            phrases: ["Start SideScreen USB with \(.applicationName)"],
            shortTitle: "SideScreen USB",
            systemImageName: "cable.connector"
        )
    }
}

private extension RunHeadlessToolIntent {
    init(action: ShortcutAction) {
        self.init()
        self.action = action
    }
}
