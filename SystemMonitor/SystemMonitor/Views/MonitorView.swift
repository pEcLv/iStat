import SwiftUI

struct MonitorView: View {
    @EnvironmentObject var monitor: SystemMonitorManager

    var body: some View {
        VStack(spacing: 12) {
            CPUSection(monitor: monitor.cpuMonitor)
            MemorySection(monitor: monitor.memoryMonitor)
            Spacer()
            QuitButton()
        }
        .padding()
        .frame(width: 280, height: 260)
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
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f%%", monitor.usage))
                        .font(.title3.bold())
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
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Memory", icon: "memorychip")

            HStack {
                CircularProgressView(value: monitor.usagePercent / 100, color: .green)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f%%", monitor.usagePercent))
                        .font(.title3.bold())
                    Text("\(formatBytes(monitor.usedMemory)) / \(formatBytes(monitor.totalMemory))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                MemoryLabel(title: "Active", value: monitor.activeMemory, color: .yellow)
                MemoryLabel(title: "Wired", value: monitor.wiredMemory, color: .red)
                MemoryLabel(title: "Compressed", value: monitor.compressedMemory, color: .orange)
            }
            .font(.caption2)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
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
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(title): \(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory))")
        }
    }
}

// MARK: - Shared Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.subheadline.bold())
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
                .stroke(color.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: min(value, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.0f", value * 100))
                .font(.system(size: 10, weight: .bold))
        }
    }
}

struct QuitButton: View {
    var body: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            Text("Quit")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
}
