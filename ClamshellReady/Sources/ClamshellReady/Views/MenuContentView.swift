import AppKit
import SwiftUI

struct MenuContentView: View {
    let monitor: SystemMonitor
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "display.and.arrow.down")
                Text("Clamshell Ready")
                    .font(.headline)
                Spacer()
                Toggle("Clamshell Ready", isOn: Binding(get: { monitor.activeModeEnabled }, set: { monitor.setActiveModeEnabled($0) }))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            Divider()
            if let error = monitor.errorMessage { Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
            switchRow("Allow on Battery", Binding(get: { monitor.allowOnBattery }, set: { monitor.setAllowOnBattery($0) }))
            switchRow("Ignore Lid Close (Disable sleep)", Binding(get: { monitor.lidOverrideDesired }, set: { monitor.setLidOverrideEnabled($0) }))
            switchRow("Launch at Login", Binding(get: { monitor.launchAtLogin }, set: { monitor.setLaunchAtLogin($0) }))
            if monitor.hasBuiltInDisplay {
                switchRow("Dim Built-in Display", Binding(get: { monitor.dimBuiltInAtLogin }, set: { monitor.setDimBuiltInAtLogin($0) }))
            }
            Divider()
            status("External Display", monitor.hasExternalDisplay ? "Connected" : "Not connected")
            status("Power Adapter", monitor.isOnACPower ? "Connected" : "Not connected")
            status("Lid", monitor.lidState.text)
            Divider()
            HStack {
                Button("Refresh") { monitor.refresh() }
                Spacer()
                Button("Go to Sleep") { monitor.goToSleep() }
                Button("Quit") { monitor.stop(); NSApplication.shared.terminate(nil) }.keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 330)
    }
    private func status(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
    private func switchRow(_ title: String, _ binding: Binding<Bool>, isEnabled: Bool = true) -> some View {
        HStack {
            Text(title)
            Spacer()
            Toggle(title, isOn: binding)
                .labelsHidden()
                .toggleStyle(.switch)
                .disabled(!isEnabled)
        }
    }
}
