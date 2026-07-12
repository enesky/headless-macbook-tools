import AppKit
import SwiftUI

@main
struct HeadlessMacBookToolsApp: App {
    @StateObject private var monitor: SystemMonitor
    @StateObject private var tools: ToolController
    @StateObject private var shortcuts: GlobalShortcutStore

    init() {
        let monitor = SystemMonitor()
        let tools = ToolController()
        let shortcuts = GlobalShortcutStore()
        shortcuts.configure(tools: tools, monitor: monitor)
        _monitor = StateObject(wrappedValue: monitor)
        _tools = StateObject(wrappedValue: tools)
        _shortcuts = StateObject(wrappedValue: shortcuts)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor, tools: tools, shortcuts: shortcuts)
                .onOpenURL { tools.run(url: $0) }
        } label: {
            Image(nsImage: MenuBarIcon.image)
                .accessibilityLabel("Headless MacOS Tools")
        }
        .menuBarExtraStyle(.window)
    }
}
