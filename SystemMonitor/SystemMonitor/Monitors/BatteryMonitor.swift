import Foundation
import Combine
import IOKit.ps

class BatteryMonitor: ObservableObject {
    @Published var isPresent: Bool = false
    @Published var isCharging: Bool = false
    @Published var currentCapacity: Int = 0
    @Published var maxCapacity: Int = 0
    @Published var health: Double = 0
    @Published var cycleCount: Int = 0
    @Published var powerSource: String = "Unknown"

    func update() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            isPresent = false
            return
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            isPresent = true
            isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
            currentCapacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0

            if let max = info[kIOPSMaxCapacityKey] as? Int {
                maxCapacity = max
            }
            if let design = info[kIOPSDesignCapacityKey] as? Int, design > 0, maxCapacity > 0 {
                health = Double(maxCapacity) / Double(design) * 100
            }
            if let cycles = info["CycleCount"] as? Int {
                cycleCount = cycles
            }
            if let source = info[kIOPSPowerSourceStateKey] as? String {
                powerSource = source == kIOPSACPowerValue ? "AC Power" : "Battery"
            }
        }
    }
}
