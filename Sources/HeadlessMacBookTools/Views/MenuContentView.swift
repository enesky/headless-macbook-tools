import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var monitor: SystemMonitor
    @ObservedObject var tools: ToolController
    @ObservedObject var shortcuts: GlobalShortcutStore
    @State private var showingClamshellInfo = false
    @State private var showingSleepToolsInfo = false
    @State private var showingNotificationsInfo = false
    @State private var showingShortcutEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            systemStatus
            Divider()
            clamshellSection
            Divider()
            infoSection("SLEEP TOOLS", isPresented: $showingSleepToolsInfo, help: "About Sleep Tools") {
                ForEach(tools.services.filter { $0.id.contains("sleep") }, id: \.id) { serviceToggle($0) }
            } info: {
                sleepToolsInfo
            }
            Divider()
            energyModeSection
            Divider()
            infoSection("NOTIFICATIONS", isPresented: $showingNotificationsInfo, help: "About Notifications") {
                switchRow("Login, Wake & Unlock Sound", monitor.loginWakeSoundEnabled, monitor.setLoginWakeSoundEnabled)
                ForEach(tools.services.filter { !$0.id.contains("sleep") }, id: \.id) { serviceToggle($0) }
            } info: {
                notificationsInfo
            }
            Divider()
            shortcutsSection
            Divider()
            if let error = monitor.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
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
            Text("Headless MacOS Tools").font(.headline)
            Spacer()
        }
    }

    private var systemStatus: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            status("Built-in Display", monitor.disableBuiltInDisplay ? "Disabled" : "Enabled")
            status("External Display", monitor.hasExternalDisplay ? "Connected" : "Not Connected")
            status("AirPlay", monitor.hasAirPlayDisplay ? "Connected" : "Not Connected")
            status("Lid", monitor.lidState.text)
            status("Power Source", monitor.isOnACPower ? "Power Adapter" : "Battery")
            status("Energy Mode", monitor.energyMode.text)
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("SHORTCUTS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Edit") { showingShortcutEditor.toggle() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .popover(isPresented: $showingShortcutEditor, arrowEdge: .trailing) {
                        shortcutEditor
                    }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach([ShortcutCommand.airPlay, .sideScreenUSB, .sleepNow, .sideScreenWireless]) { shortcutButton($0) }
            }
            if !shortcuts.registrationErrors.isEmpty {
                Label("Some shortcuts are already in use. Click Edit to choose new combinations.", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var energyModeSection: some View {
        section("ENERGY MODE") {
            if monitor.batteryEnergyMode != .unavailable {
                energyModePicker(.battery)
            }
            if monitor.adapterEnergyMode != .unavailable {
                energyModePicker(.adapter)
            }
        }
    }

    private func energyModePicker(_ source: EnergyPowerSource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(source.title).font(.caption).foregroundStyle(.secondary)
            Picker(source.title, selection: Binding(
                get: { source == .battery ? monitor.batteryEnergyMode : monitor.adapterEnergyMode },
                set: { monitor.setEnergyMode($0, for: source) }
            )) {
                ForEach(EnergyMode.configurable.filter { monitor.supportsHighPowerMode || $0 != .highPower }, id: \.self) {
                    Text($0.text).tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
    }

    private func shortcutButton(_ command: ShortcutCommand) -> some View {
        let display = shortcuts.bindings[command]?.readableDisplay ?? "—"
        let displayColor: Color = shortcuts.registrationErrors[command] == nil ? .secondary : .red
        return Button { shortcuts.run(command) } label: {
            HStack(spacing: 8) {
                Image(systemName: command.icon).frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(command.title).lineLimit(2)
                    Text(display)
                        .font(.caption2)
                        .foregroundStyle(displayColor)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator.opacity(0.55), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .help(shortcuts.registrationErrors[command] ?? "Run \(command.title)")
    }

    private var shortcutEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcuts").font(.headline)
            Text("Click a shortcut, then press the new key combination. Press Esc to cancel.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(ShortcutCommand.allCases) { command in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: command.icon)
                            .frame(width: 20, alignment: .center)
                        Text(command.title)
                            .lineLimit(1)
                        Spacer()
                        Button { shortcuts.beginRecording(command) } label: {
                            Text(shortcuts.recording == command ? "Press keys…" : shortcuts.bindings[command]?.readableDisplay ?? "Set")
                                .font(.caption2)
                                .foregroundStyle(shortcuts.recording == command ? Color.accentColor : .secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 9)
                                .frame(width: 190)
                                .frame(minHeight: 38)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.separator.opacity(0.55), lineWidth: 0.5)
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if let error = shortcuts.registrationErrors[command] {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 28)
                    }
                }
            }
            HStack {
                Button("Reset Defaults") { shortcuts.resetDefaults() }
                Spacer()
                Button("Done") { showingShortcutEditor = false }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(14)
        .frame(width: 480)
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
            switchRow("Launch at Login", monitor.launchAtLogin, monitor.setLaunchAtLogin)
            switchRow("Allow on Battery", monitor.allowOnBattery, monitor.setAllowOnBattery)
            switchRow("Ignore Lid Close (Disable Sleep)", monitor.lidOverrideDesired, monitor.setLidOverrideEnabled)
            if monitor.hasBuiltInDisplay {
                switchRow("Disable Built-in Display", monitor.disableBuiltInDisplay, monitor.setDisableBuiltInDisplay)
                if !monitor.disableBuiltInDisplay {
                    switchRow("Dim Built-in Display", monitor.dimBuiltInAtLogin, monitor.setDimBuiltInAtLogin)
                }
            }
        }
    }

    private var clamshellInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clamshell Ready").font(.headline)
            Text("Keeps the Mac awake for an external-display workflow. By default, a physical external display and power adapter must both be connected.")
                .foregroundStyle(.secondary)
            infoRow("Launch at Login", "Starts Headless MacOS Tools automatically after you sign in.")
            infoRow("Allow on Battery", "Also keeps the Mac awake without a power adapter when a physical external display is connected.")
            infoRow("Ignore Lid Close", "Uses an unsupported system-wide sleep override. It may require administrator approval and should be used carefully.")
            infoRow("Dim Built-in Display", "Sets only the MacBook's built-in display brightness to zero.")
            infoRow("Disable Built-in Display", "Disables the built-in display while a physical external display is connected. Experimental and unsupported by macOS.")
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
            infoRow("Login, Wake & Unlock Sound", "Plays a short sound after login, wake, or unlocking the Mac.")
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
