import SwiftUI

struct MonitorView: View {
    @EnvironmentObject var monitor: SystemMonitorManager
    @StateObject private var theme = ThemeManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                CPUSection(monitor: monitor.cpuMonitor)
                MemorySection(monitor: monitor.memoryMonitor)
                NetworkSection(monitor: monitor.networkMonitor)
                DiskSection(monitor: monitor.diskMonitor)
                BatterySection(monitor: monitor.batteryMonitor)
                SensorSection(monitor: monitor.sensorMonitor)
                FooterView(theme: theme)
            }
            .padding(10)
        }
        .frame(width: 300, height: 480)
        .preferredColorScheme(theme.colorScheme)
    }
}

// MARK: - CPU Section

struct CPUSection: View {
    @ObservedObject var monitor: CPUMonitor

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "CPU", icon: "cpu", color: .cpuColor)

                HStack(spacing: 12) {
                    AnimatedRing(value: monitor.usage / 100, color: .cpuColor, lineWidth: 6)
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.1f%%", monitor.usage))
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        HStack(spacing: 8) {
                            StatLabel(title: "User", value: String(format: "%.0f%%", monitor.userUsage), color: .cpuColor)
                            StatLabel(title: "Sys", value: String(format: "%.0f%%", monitor.systemUsage), color: .orange)
                        }
                    }

                    Spacer()
                }

                LineChart(data: monitor.history, color: .cpuColor)
                    .frame(height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

// MARK: - Memory Section

struct MemorySection: View {
    @ObservedObject var monitor: MemoryMonitor

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Memory", icon: "memorychip", color: .memoryColor)

                HStack(spacing: 12) {
                    AnimatedRing(value: monitor.usagePercent / 100, color: .memoryColor, lineWidth: 6)
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "%.1f%%", monitor.usagePercent))
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        Text("\(formatBytes(monitor.usedMemory)) / \(formatBytes(monitor.totalMemory))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    MemoryBreakdown(monitor: monitor)
                }

                LineChart(data: monitor.history, color: .memoryColor)
                    .frame(height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

struct MemoryBreakdown: View {
    @ObservedObject var monitor: MemoryMonitor

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            MemoryItem(label: "Active", value: monitor.activeMemory, color: .yellow)
            MemoryItem(label: "Wired", value: monitor.wiredMemory, color: .red)
            MemoryItem(label: "Compressed", value: monitor.compressedMemory, color: .orange)
        }
    }
}

struct MemoryItem: View {
    let label: String
    let value: UInt64
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(label): \(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory))")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Network Section

struct NetworkSection: View {
    @ObservedObject var monitor: NetworkMonitor

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Network", icon: "network", color: .networkDownColor)

                SpeedIndicator(download: monitor.downloadSpeed, upload: monitor.uploadSpeed)

                ZStack {
                    LineChart(data: monitor.downloadHistory, color: .networkDownColor, maxValue: maxSpeed)
                    LineChart(data: monitor.uploadHistory, color: .networkUpColor, maxValue: maxSpeed, showGradient: false)
                }
                .frame(height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private var maxSpeed: Double {
        max(
            monitor.downloadHistory.max() ?? 1024,
            monitor.uploadHistory.max() ?? 1024,
            1024
        ) * 1.2
    }
}

// MARK: - Disk Section

struct DiskSection: View {
    @ObservedObject var monitor: DiskMonitor

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "Disk", icon: "internaldrive", color: .diskColor)

                ForEach(monitor.disks) { disk in
                    DiskRow(disk: disk)
                }
            }
        }
    }
}

struct DiskRow: View {
    let disk: DiskMonitor.DiskInfo
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(disk.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%%", disk.usagePercent))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(diskColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.diskColor.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(diskColor)
                        .frame(width: geo.size.width * animatedProgress)
                }
            }
            .frame(height: 6)

            Text("\(DiskMonitor.formatBytes(disk.freeSpace)) free of \(DiskMonitor.formatBytes(disk.totalSpace))")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = disk.usagePercent / 100
            }
        }
        .onChange(of: disk.usagePercent) { newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedProgress = newValue / 100
            }
        }
    }

    private var diskColor: Color {
        if disk.usagePercent > 90 { return .red }
        if disk.usagePercent > 75 { return .orange }
        return .diskColor
    }
}

// MARK: - Battery Section

struct BatterySection: View {
    @ObservedObject var monitor: BatteryMonitor

    var body: some View {
        if monitor.isPresent {
            SectionCard {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Battery", icon: "battery.100", color: .batteryColor)

                    HStack {
                        AnimatedBattery(level: monitor.currentCapacity, isCharging: monitor.isCharging)
                            .frame(width: 44, height: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("\(monitor.currentCapacity)%")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))

                                if monitor.isCharging {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                        .pulse(when: true)
                                }
                            }
                            Text(monitor.powerSource)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(healthColor)
                                Text(String(format: "%.0f%%", monitor.health))
                                    .font(.system(size: 10, weight: .medium))
                            }
                            Text("\(monitor.cycleCount) cycles")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var healthColor: Color {
        if monitor.health > 80 { return .green }
        if monitor.health > 50 { return .orange }
        return .red
    }
}

struct AnimatedBattery: View {
    let level: Int
    let isCharging: Bool
    @State private var animatedLevel: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.primary.opacity(0.6), lineWidth: 1.5)

                RoundedRectangle(cornerRadius: 3)
                    .fill(batteryColor)
                    .frame(width: max(0, (geo.size.width - 6) * animatedLevel))
                    .padding(2)

                Rectangle()
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 3, height: geo.size.height * 0.4)
                    .offset(x: geo.size.width - 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedLevel = CGFloat(level) / 100
            }
        }
        .onChange(of: level) { newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedLevel = CGFloat(newValue) / 100
            }
        }
    }

    private var batteryColor: Color {
        if isCharging { return .green }
        if level <= 20 { return .red }
        if level <= 50 { return .yellow }
        return .green
    }
}

// MARK: - Sensor Section

struct SensorSection: View {
    @ObservedObject var monitor: SensorMonitor

    var body: some View {
        let hasData = monitor.cpuTemperature > 0 || monitor.gpuTemperature > 0 || !monitor.fanSpeeds.isEmpty

        if hasData {
            SectionCard {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Sensors", icon: "thermometer", color: .tempWarm)

                    HStack(spacing: 16) {
                        if monitor.cpuTemperature > 0 {
                            TempGauge(label: "CPU", temp: monitor.cpuTemperature)
                        }
                        if monitor.gpuTemperature > 0 {
                            TempGauge(label: "GPU", temp: monitor.gpuTemperature)
                        }
                        Spacer()
                    }

                    if !monitor.fanSpeeds.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(monitor.fanSpeeds) { fan in
                                HStack(spacing: 4) {
                                    Image(systemName: "fan.fill")
                                        .font(.caption2)
                                        .rotationEffect(.degrees(Double(fan.rpm) / 10))
                                    Text("\(fan.rpm) RPM")
                                        .font(.system(size: 10, design: .monospaced))
                                }
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

struct TempGauge: View {
    let label: String
    let temp: Double

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(tempColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 28, height: 28)

                Circle()
                    .trim(from: 0, to: min(temp / 100, 1.0))
                    .stroke(tempColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f", temp))
                    .font(.system(size: 8, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text("°C")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var tempColor: Color {
        if temp > 80 { return .tempHot }
        if temp > 60 { return .tempWarm }
        return .tempNormal
    }
}

// MARK: - Shared Components

struct SectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
    }
}

struct StatLabel: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(title) \(value)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

struct FooterView: View {
    @ObservedObject var theme: ThemeManager

    var body: some View {
        HStack {
            Menu {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    Button(action: { theme.currentTheme = t }) {
                        HStack {
                            Text(t.rawValue.capitalized)
                            if theme.currentTheme == t {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "paintbrush")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 20)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }
}
