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
            DispatchQueue.main.async {
                self.isPresent = false
            }
            return
        }

        var present = false
        var charging = false
        var capacity = 0
        var max = 0
        var healthPercent: Double = 0
        var cycles = 0
        var source = "Unknown"

        for src in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, src)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            present = true
            charging = info[kIOPSIsChargingKey] as? Bool ?? false
            capacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0

            if let m = info[kIOPSMaxCapacityKey] as? Int {
                max = m
            }
            if let design = info[kIOPSDesignCapacityKey] as? Int, design > 0, max > 0 {
                healthPercent = Double(max) / Double(design) * 100
            }
            if let c = info["CycleCount"] as? Int {
                cycles = c
            }
            if let s = info[kIOPSPowerSourceStateKey] as? String {
                source = s == kIOPSACPowerValue ? "AC Power" : "Battery"
            }
        }

        DispatchQueue.main.async {
            self.isPresent = present
            self.isCharging = charging
            self.currentCapacity = capacity
            self.maxCapacity = max
            self.health = healthPercent
            self.cycleCount = cycles
            self.powerSource = source
        }
    }
}
