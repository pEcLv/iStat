import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme: ThemeManager
    @AppStorage("refreshInterval") private var refreshInterval: Double = 1.0
    @AppStorage("showCPU") private var showCPU = true
    @AppStorage("showMemory") private var showMemory = true
    @AppStorage("showNetwork") private var showNetwork = true
    @AppStorage("showDisk") private var showDisk = true
    @AppStorage("showBattery") private var showBattery = true
    @AppStorage("showSensors") private var showSensors = true
    @AppStorage("menuBarStyle") private var menuBarStyle: MenuBarStyle = .cpuAndMemory

    var body: some View {
        TabView {
            GeneralTab(refreshInterval: $refreshInterval, menuBarStyle: $menuBarStyle)
                .tabItem { Label("General", systemImage: "gear") }

            ModulesTab(
                showCPU: $showCPU,
                showMemory: $showMemory,
                showNetwork: $showNetwork,
                showDisk: $showDisk,
                showBattery: $showBattery,
                showSensors: $showSensors
            )
            .tabItem { Label("Modules", systemImage: "square.grid.2x2") }

            AppearanceTab(theme: theme)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 380, height: 260)
    }
}

// MARK: - General Tab

struct GeneralTab: View {
    @Binding var refreshInterval: Double
    @Binding var menuBarStyle: MenuBarStyle

    var body: some View {
        Form {
            Picker("Refresh Interval", selection: $refreshInterval) {
                Text("0.5s").tag(0.5)
                Text("1s").tag(1.0)
                Text("2s").tag(2.0)
                Text("5s").tag(5.0)
            }
            .pickerStyle(.segmented)

            Picker("Menu Bar Display", selection: $menuBarStyle) {
                ForEach(MenuBarStyle.allCases, id: \.self) { style in
                    Text(style.displayName).tag(style)
                }
            }

            LaunchAtLoginToggle()
        }
        .padding()
    }
}

struct LaunchAtLoginToggle: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        Toggle("Launch at Login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { newValue in
                // 实际实现需要使用 SMLoginItemSetEnabled 或 ServiceManagement
                // 这里仅保存设置
            }
    }
}

// MARK: - Modules Tab

struct ModulesTab: View {
    @Binding var showCPU: Bool
    @Binding var showMemory: Bool
    @Binding var showNetwork: Bool
    @Binding var showDisk: Bool
    @Binding var showBattery: Bool
    @Binding var showSensors: Bool

    var body: some View {
        Form {
            Section("Visible Modules") {
                Toggle("CPU", isOn: $showCPU)
                Toggle("Memory", isOn: $showMemory)
                Toggle("Network", isOn: $showNetwork)
                Toggle("Disk", isOn: $showDisk)
                Toggle("Battery", isOn: $showBattery)
                Toggle("Sensors", isOn: $showSensors)
            }
        }
        .padding()
    }
}

// MARK: - Appearance Tab

struct AppearanceTab: View {
    @ObservedObject var theme: ThemeManager

    var body: some View {
        Form {
            Picker("Theme", selection: $theme.currentTheme) {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    HStack {
                        themeIcon(t)
                        Text(t.rawValue.capitalized)
                    }
                    .tag(t)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding()
    }

    @ViewBuilder
    private func themeIcon(_ theme: AppTheme) -> some View {
        switch theme {
        case .system:
            Image(systemName: "circle.lefthalf.filled")
        case .light:
            Image(systemName: "sun.max.fill")
        case .dark:
            Image(systemName: "moon.fill")
        }
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("System Monitor")
                .font(.title2.bold())

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("A lightweight system monitoring app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com/pEcLv/iStat")!)
                .font(.caption)
        }
        .padding()
    }
}

// MARK: - Menu Bar Style

enum MenuBarStyle: String, CaseIterable {
    case cpuOnly = "cpu"
    case memoryOnly = "memory"
    case cpuAndMemory = "cpuMemory"
    case networkSpeed = "network"
    case compact = "compact"

    var displayName: String {
        switch self {
        case .cpuOnly: return "CPU Only"
        case .memoryOnly: return "Memory Only"
        case .cpuAndMemory: return "CPU & Memory"
        case .networkSpeed: return "Network Speed"
        case .compact: return "Compact (Icon)"
        }
    }
}
