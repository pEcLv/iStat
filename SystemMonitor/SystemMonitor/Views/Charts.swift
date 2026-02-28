import SwiftUI

// MARK: - Line Chart

struct LineChart: View {
    let data: [Double]
    let color: Color
    let maxValue: Double
    let showGradient: Bool

    init(data: [Double], color: Color, maxValue: Double = 100, showGradient: Bool = true) {
        self.data = data
        self.color = color
        self.maxValue = maxValue
        self.showGradient = showGradient
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if showGradient {
                    gradientFill(in: geo.size)
                }
                linePath(in: geo.size)
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func linePath(in size: CGSize) -> Path {
        Path { path in
            guard data.count > 1 else { return }

            let step = size.width / CGFloat(data.count - 1)

            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * step
                let y = size.height - (CGFloat(value / maxValue) * size.height)
                let point = CGPoint(x: x, y: min(max(y, 0), size.height))

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }

    private func gradientFill(in size: CGSize) -> some View {
        Path { path in
            guard data.count > 1 else { return }

            let step = size.width / CGFloat(data.count - 1)

            path.move(to: CGPoint(x: 0, y: size.height))

            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * step
                let y = size.height - (CGFloat(value / maxValue) * size.height)
                path.addLine(to: CGPoint(x: x, y: min(max(y, 0), size.height)))
            }

            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [color.opacity(0.3), color.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Speed Indicator

struct SpeedIndicator: View {
    let download: Double
    let upload: Double

    var body: some View {
        HStack(spacing: 12) {
            speedItem(
                icon: "arrow.down.circle.fill",
                color: .networkDownColor,
                label: formatSpeed(download)
            )
            speedItem(
                icon: "arrow.up.circle.fill",
                color: .networkUpColor,
                label: formatSpeed(upload)
            )
        }
    }

    private func speedItem(icon: String, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
    }

    private func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 { return String(format: "%3.0f B/s", bps) }
        if bps < 1024 * 1024 { return String(format: "%5.1f KB/s", bps / 1024) }
        return String(format: "%5.2f MB/s", bps / 1024 / 1024)
    }
}
