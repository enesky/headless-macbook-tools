import AppKit
import SwiftUI

@main
struct HeadlessMacBookToolsApp: App {
    @StateObject private var monitor = SystemMonitor()
    @StateObject private var tools = ToolController()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor, tools: tools)
                .onOpenURL { tools.run(url: $0) }
        } label: {
            Image(nsImage: MenuBarIcon.image)
                .accessibilityLabel("Headless MacBook Tools")
        }
        .menuBarExtraStyle(.window)
    }
}
