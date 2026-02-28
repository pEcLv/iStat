import Foundation
import Combine
import IOKit.ps

class BatteryMonitor: ObservableObject {
    @Published var isPresent: Bool = false
    @Published var isCharging: Bool = false
    @Published var currentCapacity: Int = 0
    @Published var maxCapacity: Int = 0
    @Published var designCapacity: Int = 0
    @Published var cycleCount: Int = 0
    @Published var health: Double = 0
    @Published var timeRemaining: Int = -1  // 分钟，-1 表示未知
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

            if let charging = info[kIOPSIsChargingKey] as? Bool {
                isCharging = charging
            }

            if let current = info[kIOPSCurrentCapacityKey] as? Int {
                currentCapacity = current
            }

            if let max = info[kIOPSMaxCapacityKey] as? Int {
                maxCapacity = max
            }

            if let design = info[kIOPSDesignCapacityKey] as? Int {
                designCapacity = design
                if design > 0 && maxCapacity > 0 {
                    health = Double(maxCapacity) / Double(design) * 100
                }
            }

            if let cycles = info["CycleCount"] as? Int {
                cycleCount = cycles
            }

            if let time = info[kIOPSTimeToEmptyKey] as? Int, time > 0 {
                timeRemaining = time
            } else if let time = info[kIOPSTimeToFullChargeKey] as? Int, time > 0 {
                timeRemaining = time
            }

            if let source = info[kIOPSPowerSourceStateKey] as? String {
                powerSource = source == kIOPSACPowerValue ? "AC Power" : "Battery"
            }
        }
    }

    func formatTimeRemaining() -> String {
        guard timeRemaining > 0 else { return "Calculating..." }
        let hours = timeRemaining / 60
        let minutes = timeRemaining % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
