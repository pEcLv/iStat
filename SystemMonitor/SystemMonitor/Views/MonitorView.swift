import SwiftUI

struct MonitorView: View {
    @EnvironmentObject var monitor: SystemMonitorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                CPUSection(monitor: monitor.cpuMonitor)
                MemorySection(monitor: monitor.memoryMonitor)
                NetworkSection(monitor: monitor.networkMonitor)
                DiskSection(monitor: monitor.diskMonitor)
                BatterySection(monitor: monitor.batteryMonitor)
                SensorSection(monitor: monitor.sensorMonitor)
                QuitButton()
            }
            .padding(12)
        }
        .frame(width: 300, height: 420)
    }
}

// MARK: - CPU Section

struct CPUSection: View {
    @ObservedObject var monitor: CPUMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "CPU", icon: "cpu")
            HStack {
                CircularProgressView(value: monitor.usage / 100, color: .blue)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f%%", monitor.usage))
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text(String(format: "User %.0f%%", monitor.userUsage))
                        Text(String(format: "Sys %.0f%%", monitor.systemUsage))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Memory Section

struct MemorySection: View {
    @ObservedObject var monitor: MemoryMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Memory", icon: "memorychip")
            HStack {
                CircularProgressView(value: monitor.usagePercent / 100, color: .green)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f%%", monitor.usagePercent))
                        .font(.headline)
                    Text("\(formatBytes(monitor.usedMemory)) / \(formatBytes(monitor.totalMemory))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

// MARK: - Network Section

struct NetworkSection: View {
    @ObservedObject var monitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Network", icon: "network")
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(NetworkMonitor.formatSpeed(monitor.downloadSpeed))
                        .font(.caption)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(NetworkMonitor.formatSpeed(monitor.uploadSpeed))
                        .font(.caption)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Disk Section

struct DiskSection: View {
    @ObservedObject var monitor: DiskMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Disk", icon: "internaldrive")
            ForEach(monitor.disks) { disk in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(disk.name).font(.caption).fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.0f%%", disk.usagePercent))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    ProgressView(value: disk.usagePercent / 100)
                        .tint(disk.usagePercent > 90 ? .red : .purple)
                        .scaleEffect(y: 0.6)
                    Text("\(DiskMonitor.formatBytes(disk.freeSpace)) free")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Battery Section

struct BatterySection: View {
    @ObservedObject var monitor: BatteryMonitor

    var body: some View {
        if monitor.isPresent {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "Battery", icon: "battery.100")
                HStack {
                    BatteryIcon(level: monitor.currentCapacity, isCharging: monitor.isCharging)
                        .frame(width: 36, height: 18)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text("\(monitor.currentCapacity)%").font(.headline)
                            if monitor.isCharging {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow).font(.caption2)
                            }
                        }
                        Text(monitor.powerSource).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Health \(String(format: "%.0f%%", monitor.health))")
                        Text("Cycles \(monitor.cycleCount)")
                    }
                    .font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Sensor Section

struct SensorSection: View {
    @ObservedObject var monitor: SensorMonitor

    var body: some View {
        let hasData = monitor.cpuTemperature > 0 || monitor.gpuTemperature > 0 || !monitor.fanSpeeds.isEmpty

        if hasData {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "Sensors", icon: "thermometer")
                HStack(spacing: 16) {
                    if monitor.cpuTemperature > 0 {
                        HStack(spacing: 4) {
                            Text("CPU").font(.caption2).foregroundColor(.secondary)
                            Text(String(format: "%.0f°C", monitor.cpuTemperature))
                                .font(.caption).foregroundColor(tempColor(monitor.cpuTemperature))
                        }
                    }
                    if monitor.gpuTemperature > 0 {
                        HStack(spacing: 4) {
                            Text("GPU").font(.caption2).foregroundColor(.secondary)
                            Text(String(format: "%.0f°C", monitor.gpuTemperature))
                                .font(.caption).foregroundColor(tempColor(monitor.gpuTemperature))
                        }
                    }
                    Spacer()
                }
                if !monitor.fanSpeeds.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(monitor.fanSpeeds) { fan in
                            HStack(spacing: 3) {
                                Image(systemName: "fan").font(.caption2)
                                Text("\(fan.rpm) RPM").font(.caption2)
                            }
                        }
                        Spacer()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp > 80 { return .red }
        if temp > 60 { return .orange }
        return .primary
    }
}

// MARK: - Shared Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption)
            Text(title).font(.subheadline.bold())
        }
    }
}

struct CircularProgressView: View {
    let value: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(value, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.0f", value * 100))
                .font(.system(size: 9, weight: .bold))
        }
    }
}

struct BatteryIcon: View {
    let level: Int
    let isCharging: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.primary, lineWidth: 1)
                RoundedRectangle(cornerRadius: 2)
                    .fill(batteryColor)
                    .frame(width: max(0, geo.size.width * CGFloat(level) / 100 - 3))
                    .padding(1.5)
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2, height: geo.size.height * 0.4)
                    .offset(x: geo.size.width - 1)
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

struct QuitButton: View {
    var body: some View {
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .font(.caption)
            .foregroundColor(.secondary)
            .buttonStyle(.plain)
    }
}
