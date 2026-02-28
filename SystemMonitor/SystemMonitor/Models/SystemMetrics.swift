import Foundation
import Combine

class SystemMonitorManager: ObservableObject {
    let cpuMonitor = CPUMonitor()
    let memoryMonitor = MemoryMonitor()
    let networkMonitor = NetworkMonitor()
    let diskMonitor = DiskMonitor()
    let batteryMonitor = BatteryMonitor()
    let sensorMonitor = SensorMonitor()

    var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    func startMonitoring() {
        updateAll()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAll()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateAll() {
        cpuMonitor.update()
        memoryMonitor.update()
        networkMonitor.update()
        diskMonitor.update()
        batteryMonitor.update()
        sensorMonitor.update()
    }
}
