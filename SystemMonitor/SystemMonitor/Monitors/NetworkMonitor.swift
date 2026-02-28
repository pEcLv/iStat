import Foundation
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var totalDownload: UInt64 = 0
    @Published var totalUpload: UInt64 = 0
    @Published var downloadHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var uploadHistory: [Double] = Array(repeating: 0, count: 60)

    private var previousDownload: UInt64 = 0
    private var previousUpload: UInt64 = 0
    private var lastUpdate = Date()

    nonisolated func update() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var currentDownload: UInt64 = 0
        var currentUpload: UInt64 = 0

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            if name.hasPrefix("en") || name.hasPrefix("lo") {
                if let data = current.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    currentDownload += UInt64(networkData.ifi_ibytes)
                    currentUpload += UInt64(networkData.ifi_obytes)
                }
            }
            ptr = current.pointee.ifa_next
        }

        let now = Date()
        let prevDown = previousDownload
        let prevUp = previousUpload
        let lastTime = lastUpdate

        previousDownload = currentDownload
        previousUpload = currentUpload
        lastUpdate = now

        let interval = now.timeIntervalSince(lastTime)
        var downSpeed: Double = 0
        var upSpeed: Double = 0

        if prevDown > 0 && interval > 0 {
            downSpeed = Double(currentDownload - prevDown) / interval
            upSpeed = Double(currentUpload - prevUp) / interval
        }

        Task { @MainActor in
            self.totalDownload = currentDownload
            self.totalUpload = currentUpload
            self.downloadSpeed = downSpeed
            self.uploadSpeed = upSpeed
            self.downloadHistory.removeFirst()
            self.downloadHistory.append(downSpeed)
            self.uploadHistory.removeFirst()
            self.uploadHistory.append(upSpeed)
        }
    }

    static func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.2f MB/s", bytesPerSecond / 1024 / 1024)
        }
    }
}
