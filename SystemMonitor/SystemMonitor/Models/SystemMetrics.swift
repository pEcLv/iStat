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
            self?.updateAll()
        }
    }

    private func updateAll() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }

            self.cpuMonitor.update()
            self.memoryMonitor.update()
            self.networkMonitor.update()
            self.diskMonitor.update()
            self.batteryMonitor.update()
            self.sensorMonitor.update()
        }
    }
}
