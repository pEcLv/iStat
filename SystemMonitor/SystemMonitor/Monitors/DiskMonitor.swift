import Foundation
import Combine

class DiskMonitor: ObservableObject {
    @Published var disks: [DiskInfo] = []

    struct DiskInfo: Identifiable {
        let id = UUID()
        let name: String
        let mountPoint: String
        let totalSpace: UInt64
        let freeSpace: UInt64
        var usedSpace: UInt64 { totalSpace - freeSpace }
        var usagePercent: Double {
            totalSpace > 0 ? Double(usedSpace) / Double(totalSpace) * 100 : 0
        }
    }

    func update() {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey]

        guard let volumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return
        }

        var newDisks: [DiskInfo] = []
        for url in volumes {
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  let name = values.volumeName,
                  let total = values.volumeTotalCapacity,
                  let free = values.volumeAvailableCapacity else {
                continue
            }

            newDisks.append(DiskInfo(
                name: name,
                mountPoint: url.path,
                totalSpace: UInt64(total),
                freeSpace: UInt64(free)
            ))
        }

        DispatchQueue.main.async {
            self.disks = newDisks
        }
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
