import Foundation
import Combine

@MainActor
class SystemMonitorManager: ObservableObject {
    let cpuMonitor = CPUMonitor()
    let memoryMonitor = MemoryMonitor()
    let networkMonitor = NetworkMonitor()
    let diskMonitor = DiskMonitor()
    let batteryMonitor = BatteryMonitor()
    let sensorMonitor = SensorMonitor()

    var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    @Published var refreshInterval: Double = 1.0 {
        didSet { restartTimer() }
    }

    init() {
        if let saved = UserDefaults.standard.object(forKey: "refreshInterval") as? Double {
            refreshInterval = saved
        }
    }

    func startMonitoring() {
        updateAll()
        restartTimer()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAll()
            }
        }
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
