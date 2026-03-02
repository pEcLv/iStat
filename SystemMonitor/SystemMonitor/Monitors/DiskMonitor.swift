import Foundation
import Combine

@MainActor
class DiskMonitor: ObservableObject {
    @Published var disks: [DiskInfo] = []

    struct DiskInfo: Identifiable {
        var id: String { mountPoint }
        let name: String
        let mountPoint: String
        let totalSpace: UInt64
        let freeSpace: UInt64
        let isInternal: Bool
        var usedSpace: UInt64 { totalSpace - freeSpace }
        var usagePercent: Double {
            totalSpace > 0 ? Double(usedSpace) / Double(totalSpace) * 100 : 0
        }
    }

    func update() {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsLocalKey,
            .volumeIsInternalKey
        ]

        guard let volumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return
        }

        var newDisks: [DiskInfo] = []
        for url in volumes {
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  let name = values.volumeName,
                  let total = values.volumeTotalCapacity,
                  (values.volumeIsLocal ?? false) else {
                continue
            }

            let available = values.volumeAvailableCapacityForImportantUsage
                ?? Int64(values.volumeAvailableCapacity ?? 0)
            let free = max(0, available)

            newDisks.append(DiskInfo(
                name: name,
                mountPoint: url.path,
                totalSpace: UInt64(total),
                freeSpace: UInt64(free),
                isInternal: values.volumeIsInternal ?? false
            ))
        }

        disks = newDisks.sorted { lhs, rhs in
            if lhs.isInternal != rhs.isInternal {
                return lhs.isInternal && !rhs.isInternal
            }
            return lhs.mountPoint < rhs.mountPoint
        }
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
