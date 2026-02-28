import Foundation
import Combine

class MemoryMonitor: ObservableObject {
    @Published var totalMemory: UInt64 = 0
    @Published var usedMemory: UInt64 = 0
    @Published var freeMemory: UInt64 = 0
    @Published var activeMemory: UInt64 = 0
    @Published var inactiveMemory: UInt64 = 0
    @Published var wiredMemory: UInt64 = 0
    @Published var compressedMemory: UInt64 = 0
    @Published var usagePercent: Double = 0
    @Published var history: [Double] = Array(repeating: 0, count: 60)

    func update() {
        totalMemory = ProcessInfo.processInfo.physicalMemory

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)

        activeMemory = UInt64(stats.active_count) * pageSize
        inactiveMemory = UInt64(stats.inactive_count) * pageSize
        wiredMemory = UInt64(stats.wire_count) * pageSize
        compressedMemory = UInt64(stats.compressor_page_count) * pageSize
        freeMemory = UInt64(stats.free_count) * pageSize

        usedMemory = activeMemory + wiredMemory + compressedMemory
        usagePercent = Double(usedMemory) / Double(totalMemory) * 100

        history.removeFirst()
        history.append(usagePercent)
    }
}
