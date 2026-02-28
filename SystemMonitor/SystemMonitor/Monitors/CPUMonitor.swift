import Foundation
import Combine

@MainActor
class CPUMonitor: ObservableObject {
    @Published var usage: Double = 0
    @Published var userUsage: Double = 0
    @Published var systemUsage: Double = 0
    @Published var idleUsage: Double = 0
    @Published var history: [Double] = Array(repeating: 0, count: 60)

    private var previousInfo: host_cpu_load_info?

    func update() {
        var cpuLoadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        guard let prev = previousInfo else {
            previousInfo = cpuLoadInfo
            return
        }

        let userDiff = Double(cpuLoadInfo.cpu_ticks.0 - prev.cpu_ticks.0)
        let systemDiff = Double(cpuLoadInfo.cpu_ticks.1 - prev.cpu_ticks.1)
        let idleDiff = Double(cpuLoadInfo.cpu_ticks.2 - prev.cpu_ticks.2)
        let niceDiff = Double(cpuLoadInfo.cpu_ticks.3 - prev.cpu_ticks.3)

        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff

        if totalTicks > 0 {
            userUsage = (userDiff / totalTicks) * 100
            systemUsage = (systemDiff / totalTicks) * 100
            idleUsage = (idleDiff / totalTicks) * 100
            usage = ((userDiff + systemDiff + niceDiff) / totalTicks) * 100

            history.removeFirst()
            history.append(usage)
        }

        previousInfo = cpuLoadInfo
    }
}
