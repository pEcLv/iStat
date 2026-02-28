import SwiftUI

struct MonitorView: View {
    @EnvironmentObject var monitor: SystemMonitorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CPUSection(monitor: monitor.cpuMonitor)
                MemorySection(monitor: monitor.memoryMonitor)
                NetworkSection(monitor: monitor.networkMonitor)
                DiskSection(monitor: monitor.diskMonitor)
                BatterySection(monitor: monitor.batteryMonitor)
            }
            .padding()
        }
        .frame(width: 320, height: 400)
    }
}

// MARK: - CPU Section

struct CPUSection: View {
    @ObservedObject var monitor: CPUMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "CPU", icon: "cpu")

            HStack {
                CircularProgressView(value: monitor.usage / 100, color: .blue)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f%%", monitor.usage))
                        .font(.title2.bold())
                    HStack(spacing: 12) {
                        Label(String(format: "User: %.1f%%", monitor.userUsage), systemImage: "person")
                        Label(String(format: "Sys: %.1f%%", monitor.systemUsage), systemImage: "gearshape")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Memory Section

struct MemorySection: View {
    @ObservedObject var monitor: MemoryMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Memory", icon: "memorychip")

            HStack {
                CircularProgressView(value: monitor.usagePercent / 100, color: .green)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f%%", monitor.usagePercent))
                        .font(.title2.bold())
                    Text("\(formatBytes(monitor.usedMemory)) / \(formatBytes(monitor.totalMemory))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 16) {
                MemoryLabel(title: "Active", value: monitor.activeMemory, color: .yellow)
                MemoryLabel(title: "Wired", value: monitor.wiredMemory, color: .red)
                MemoryLabel(title: "Compressed", value: monitor.compressedMemory, color: .orange)
            }
            .font(.caption2)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

struct MemoryLabel: View {
    let title: String
    let value: UInt64
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(title): \(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory))")
        }
    }
}

// MARK: - Network Section

struct NetworkSection: View {
    @ObservedObject var monitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Network", icon: "network")

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                    Text(NetworkMonitor.formatSpeed(monitor.downloadSpeed))
                        .font(.title3.bold())
                }

                VStack(alignment: .leading) {
                    Label("Upload", systemImage: "arrow.up.circle.fill")
                        .foregroundColor(.orange)
                    Text(NetworkMonitor.formatSpeed(monitor.uploadSpeed))
                        .font(.title3.bold())
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Disk Section

struct DiskSection: View {
    @ObservedObject var monitor: DiskMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Disk", icon: "internaldrive")

            ForEach(monitor.disks) { disk in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(disk.name)
                            .font(.subheadline.bold())
                        Spacer()
                        Text(String(format: "%.1f%%", disk.usagePercent))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: disk.usagePercent / 100)
                        .tint(disk.usagePercent > 90 ? .red : .purple)

                    Text("\(DiskMonitor.formatBytes(disk.freeSpace)) free of \(DiskMonitor.formatBytes(disk.totalSpace))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Battery Section

struct BatterySection: View {
    @ObservedObject var monitor: BatteryMonitor

    var body: some View {
        if monitor.isPresent {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Battery", icon: "battery.100")

                HStack {
                    BatteryIcon(level: monitor.currentCapacity, isCharging: monitor.isCharging)
                        .frame(width: 50, height: 25)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(monitor.currentCapacity)%")
                                .font(.title2.bold())
                            if monitor.isCharging {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text(monitor.powerSource)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Health: \(String(format: "%.0f%%", monitor.health))")
                        Text("Cycles: \(monitor.cycleCount)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }
}

// MARK: - Shared Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.primary)
    }
}

struct CircularProgressView: View {
    let value: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text(String(format: "%.0f", value * 100))
                .font(.caption2.bold())
        }
    }
}

struct BatteryIcon: View {
    let level: Int
    let isCharging: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.primary, lineWidth: 1.5)

                RoundedRectangle(cornerRadius: 2)
                    .fill(batteryColor)
                    .frame(width: max(0, geo.size.width * CGFloat(level) / 100 - 4))
                    .padding(2)

                // Battery tip
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 3, height: geo.size.height * 0.4)
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
