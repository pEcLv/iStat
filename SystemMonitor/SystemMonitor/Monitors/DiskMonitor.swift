import Foundation
import Combine

class DiskMonitor: ObservableObject {
    @Published var disks: [DiskInfo] = []
    @Published var readSpeed: Double = 0
    @Published var writeSpeed: Double = 0

    private var previousRead: UInt64 = 0
    private var previousWrite: UInt64 = 0
    private var lastUpdate = Date()

    struct DiskInfo: Identifiable {
        let id = UUID()
        let name: String
        let mountPoint: String
        let totalSpace: UInt64
        let freeSpace: UInt64
        let usedSpace: UInt64
        var usagePercent: Double {
            totalSpace > 0 ? Double(usedSpace) / Double(totalSpace) * 100 : 0
        }
    }

    func update() {
        updateDiskSpace()
        updateDiskIO()
    }

    private func updateDiskSpace() {
        var newDisks: [DiskInfo] = []

        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey]

        guard let mountedVolumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return
        }

        for volumeURL in mountedVolumes {
            guard let resourceValues = try? volumeURL.resourceValues(forKeys: Set(keys)),
                  let name = resourceValues.volumeName,
                  let totalCapacity = resourceValues.volumeTotalCapacity,
                  let availableCapacity = resourceValues.volumeAvailableCapacity else {
                continue
            }

            let total = UInt64(totalCapacity)
            let free = UInt64(availableCapacity)
            let used = total - free

            let disk = DiskInfo(
                name: name,
                mountPoint: volumeURL.path,
                totalSpace: total,
                freeSpace: free,
                usedSpace: used
            )
            newDisks.append(disk)
        }

        disks = newDisks
    }

    private func updateDiskIO() {
        // 磁盘 IO 统计需要通过 IOKit 获取，这里简化处理
        // 完整实现需要使用 IOServiceMatching("IOBlockStorageDriver")
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
