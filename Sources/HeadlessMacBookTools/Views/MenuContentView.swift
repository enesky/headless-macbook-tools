import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var monitor: SystemMonitor
    @ObservedObject var tools: ToolController
    @State private var showingClamshellInfo = false
    @State private var showingSleepToolsInfo = false
    @State private var showingNotificationsInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            systemStatus
            Divider()
            section("DISPLAY") {
                action(.airPlay, icon: "airplayvideo")
                action(.sideScreenUSB, icon: "cable.connector")
                action(.sideScreenWireless, icon: "wifi")
            }
            Divider()
            clamshellSection
            Divider()
            infoSection("SLEEP TOOLS", isPresented: $showingSleepToolsInfo, help: "About Sleep Tools") {
                ForEach(tools.services.filter { $0.id.contains("sleep") }, id: \.id) { serviceToggle($0) }
            } info: {
                sleepToolsInfo
            }
            Divider()
            infoSection("NOTIFICATIONS", isPresented: $showingNotificationsInfo, help: "About Notifications") {
                ForEach(tools.services.filter { !$0.id.contains("sleep") }, id: \.id) { serviceToggle($0) }
            } info: {
                notificationsInfo
            }
            Divider()
            if let error = monitor.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.red)
            } else if let message = tools.lastMessage {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("Refresh") { monitor.refresh(); tools.refreshServices() }
                Spacer()
                Button("Quit") { monitor.stop(); NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    private var header: some View {
        HStack {
            Spacer()
            Image(nsImage: MenuBarIcon.image)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            Text("Headless MacBook Tools").font(.headline)
            Spacer()
        }
    }

    private var systemStatus: some View {
        VStack(spacing: 8) {
            HStack {
                status("External Display", monitor.hasExternalDisplay ? "Connected" : "Not Connected")
                status("AirPlay", monitor.hasAirPlayDisplay ? "Connected" : "Not Connected")
            }
            HStack {
                status("Power Adapter", monitor.isOnACPower ? "Connected" : "Not Connected")
                status("Lid", monitor.lidState.text)
            }
        }
    }

    private var clamshellSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) {
                Text("CLAMSHELL READY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Button {
                    showingClamshellInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("About Clamshell Ready")
                .popover(isPresented: $showingClamshellInfo, arrowEdge: .trailing) {
                    clamshellInfo
                }
                Spacer()
            }
            switchRow("Allow on Battery", monitor.allowOnBattery, monitor.setAllowOnBattery)
            switchRow("Ignore Lid Close (Disable Sleep)", monitor.lidOverrideDesired, monitor.setLidOverrideEnabled)
            switchRow("Launch at Login", monitor.launchAtLogin, monitor.setLaunchAtLogin)
            if monitor.hasBuiltInDisplay {
                switchRow("Dim Built-in Display", monitor.dimBuiltInAtLogin, monitor.setDimBuiltInAtLogin)
            }
            actionRow("Sleep Now", icon: "moon.zzz") { monitor.goToSleep() }
        }
    }

    private var clamshellInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clamshell Ready").font(.headline)
            Text("Keeps the Mac awake for an external-display workflow. By default, a physical external display and power adapter must both be connected.")
                .foregroundStyle(.secondary)
            infoRow("Allow on Battery", "Also keeps the Mac awake without a power adapter when a physical external display is connected.")
            infoRow("Ignore Lid Close", "Uses an unsupported system-wide sleep override. It may require administrator approval and should be used carefully.")
            infoRow("Launch at Login", "Starts Headless MacBook Tools automatically after you sign in.")
            infoRow("Dim Built-in Display", "Sets only the MacBook's built-in display brightness to zero.")
            infoRow("Sleep Now", "Temporarily releases the wake assertion and puts the Mac to sleep.")
        }
        .padding(14)
        .frame(width: 330)
    }

    private var sleepToolsInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Tools").font(.headline)
            Text("Background safeguards that decide when the Mac should return to sleep.")
                .foregroundStyle(.secondary)
            infoRow("Automatic Re-Sleep", "After an unattended wake, returns the Mac to sleep when no physical external display or recent input is detected.")
            infoRow("Bag Sleep Guard", "If the Mac wakes while locked and running on battery, returns it to sleep when there is no keyboard or trackpad input.")
        }
        .padding(14)
        .frame(width: 330)
    }

    private var notificationsInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications").font(.headline)
            Text("Optional spoken alerts for useful MacBook state changes.")
                .foregroundStyle(.secondary)
            infoRow("Low Battery Voice Alert", "Speaks battery warnings at selected low-charge levels while the Mac is discharging.")
            infoRow("Lock Screen Voice Alert", "Says “Lock Screen” when the macOS session becomes locked.")
        }
        .padding(14)
        .frame(width: 330)
    }

    private func infoRow(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }

    private func infoSection<Content: View, Info: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        help: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder info: @escaping () -> Info
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) {
                Text(title).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                Button { isPresented.wrappedValue.toggle() } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(help)
                .popover(isPresented: isPresented, arrowEdge: .trailing) { info() }
                Spacer()
            }
            content()
        }
    }

    private func action(_ action: ToolAction, icon: String) -> some View {
        actionRow(action.title, icon: icon) { tools.run(action) }
    }

    private func actionRow(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon).frame(width: 18)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator.opacity(0.55), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func serviceToggle(_ service: ManagedService) -> some View {
        switchRow(service.title, tools.serviceStates[service.id] ?? false) { tools.set(service, enabled: $0) }
            .disabled(tools.busyService == service.id)
    }

    private func switchRow(_ title: String, _ value: Bool, _ update: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Toggle(title, isOn: Binding(get: { value }, set: update))
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .frame(maxWidth: .infinity)
    }

    private func status(_ title: String, _ value: String) -> some View {
        VStack(alignment: .center, spacing: 1) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
    }
}
