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

// MARK: - Animated Ring

struct AnimatedRing: View {
    let value: Double
    let color: Color
    let lineWidth: CGFloat
    let showLabel: Bool

    @State private var animatedValue: Double = 0

    init(value: Double, color: Color, lineWidth: CGFloat = 5, showLabel: Bool = true) {
        self.value = value
        self.color = color
        self.lineWidth = lineWidth
        self.showLabel = showLabel
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedValue)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.8), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedValue)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showLabel {
                Text(String(format: "%.0f", animatedValue * 100))
                    .font(.system(size: lineWidth * 1.8, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedValue = min(value, 1.0)
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeOut(duration: 0.3)) {
                animatedValue = min(newValue, 1.0)
            }
        }
    }
}

// MARK: - Bar Chart

struct BarChart: View {
    let values: [(String, Double, Color)]
    let maxValue: Double

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(values.indices, id: \.self) { index in
                let item = values[index]
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.2)
                        .frame(height: max(2, CGFloat(item.1 / maxValue) * 40))

                    Text(item.0)
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Speed Indicator

struct SpeedIndicator: View {
    let download: Double
    let upload: Double

    @State private var downloadAnim: Double = 0
    @State private var uploadAnim: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            speedItem(
                icon: "arrow.down.circle.fill",
                value: downloadAnim,
                color: .networkDownColor,
                label: formatSpeed(download)
            )
            speedItem(
                icon: "arrow.up.circle.fill",
                value: uploadAnim,
                color: .networkUpColor,
                label: formatSpeed(upload)
            )
        }
        .onAppear { updateAnimations() }
        .onChange(of: download) { _ in updateAnimations() }
        .onChange(of: upload) { _ in updateAnimations() }
    }

    private func speedItem(icon: String, value: Double, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .scaleEffect(value > 0 ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: value)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
    }

    private func updateAnimations() {
        withAnimation(.easeOut(duration: 0.3)) {
            downloadAnim = download
            uploadAnim = upload
        }
    }

    private func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 { return String(format: "%3.0f B/s", bps) }
        if bps < 1024 * 1024 { return String(format: "%5.1f KB/s", bps / 1024) }
        return String(format: "%5.2f MB/s", bps / 1024 / 1024)
    }
}

// MARK: - Pulse Animation

struct PulseEffect: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: isActive) { active in
                if active {
                    withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                        scale = 1.1
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1.0
                    }
                }
            }
    }
}

extension View {
    func pulse(when active: Bool) -> some View {
        modifier(PulseEffect(isActive: active))
    }
}
