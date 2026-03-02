import Foundation
import Combine
import Darwin

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

    func update() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var currentDownload: UInt64 = 0
        var currentUpload: UInt64 = 0

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            if shouldIncludeInterface(current.pointee),
               let data = current.pointee.ifa_data {
                let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                currentDownload += UInt64(networkData.ifi_ibytes)
                currentUpload += UInt64(networkData.ifi_obytes)
            }
            ptr = current.pointee.ifa_next
        }

        let now = Date()
        let interval = now.timeIntervalSince(lastUpdate)

        if previousDownload > 0 && interval > 0 {
            let downloadDelta = currentDownload >= previousDownload ? (currentDownload - previousDownload) : 0
            let uploadDelta = currentUpload >= previousUpload ? (currentUpload - previousUpload) : 0
            downloadSpeed = Double(downloadDelta) / interval
            uploadSpeed = Double(uploadDelta) / interval
        }

        totalDownload = currentDownload
        totalUpload = currentUpload
        previousDownload = currentDownload
        previousUpload = currentUpload
        lastUpdate = now

        downloadHistory.removeFirst()
        downloadHistory.append(downloadSpeed)
        uploadHistory.removeFirst()
        uploadHistory.append(uploadSpeed)
    }

    private func shouldIncludeInterface(_ interface: ifaddrs) -> Bool {
        guard let address = interface.ifa_addr else { return false }
        guard address.pointee.sa_family == UInt8(AF_LINK) else { return false }

        let flags = Int32(interface.ifa_flags)
        let isUp = (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0
        let isLoopback = (flags & IFF_LOOPBACK) != 0
        return isUp && !isLoopback
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
