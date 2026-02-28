import SwiftUI

struct SettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Double = 1.0
    @AppStorage("showCPU") private var showCPU = true
    @AppStorage("showMemory") private var showMemory = true
    @AppStorage("showNetwork") private var showNetwork = true
    @AppStorage("showDisk") private var showDisk = true
    @AppStorage("showBattery") private var showBattery = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        TabView {
            GeneralSettingsView(
                refreshInterval: $refreshInterval,
                launchAtLogin: $launchAtLogin
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            ModulesSettingsView(
                showCPU: $showCPU,
                showMemory: $showMemory,
                showNetwork: $showNetwork,
                showDisk: $showDisk,
                showBattery: $showBattery
            )
            .tabItem {
                Label("Modules", systemImage: "square.grid.2x2")
            }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 400, height: 300)
    }
}

struct GeneralSettingsView: View {
    @Binding var refreshInterval: Double
    @Binding var launchAtLogin: Bool

    var body: some View {
        Form {
            Section {
                Picker("Refresh Interval", selection: $refreshInterval) {
                    Text("0.5 seconds").tag(0.5)
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                }

                Toggle("Launch at Login", isOn: $launchAtLogin)
            }
        }
        .padding()
    }
}

struct ModulesSettingsView: View {
    @Binding var showCPU: Bool
    @Binding var showMemory: Bool
    @Binding var showNetwork: Bool
    @Binding var showDisk: Bool
    @Binding var showBattery: Bool

    var body: some View {
        Form {
            Section("Visible Modules") {
                Toggle("CPU", isOn: $showCPU)
                Toggle("Memory", isOn: $showMemory)
                Toggle("Network", isOn: $showNetwork)
                Toggle("Disk", isOn: $showDisk)
                Toggle("Battery", isOn: $showBattery)
            }
        }
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("System Monitor")
                .font(.title.bold())

            Text("Version 1.0.0")
                .foregroundColor(.secondary)

            Text("A lightweight system monitoring app for macOS")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}
