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
    private var lastDiskUpdate = Date.distantPast
    private var lastBatteryUpdate = Date.distantPast
    private var lastSensorUpdate = Date.distantPast
    private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

    private let diskUpdateInterval: TimeInterval = 5
    private let batteryUpdateInterval: TimeInterval = 10
    private let sensorUpdateInterval: TimeInterval = 3

    @Published var refreshInterval: Double = 1.0 {
        didSet { restartTimer() }
    }

    init() {
        if let saved = UserDefaults.standard.object(forKey: "refreshInterval") as? Double {
            refreshInterval = saved
        }

        if !BuildConfig.supportsSensors {
            UserDefaults.standard.set(false, forKey: "showSensors")
        }

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadRefreshIntervalFromDefaults()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
                self.restartTimer()
            }
            .store(in: &cancellables)
    }

    func startMonitoring() {
        updateAll(forceHeavyModules: true)
        restartTimer()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: effectiveRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAll(forceHeavyModules: false)
            }
        }
    }

    private var effectiveRefreshInterval: Double {
        isLowPowerModeEnabled ? max(1.0, refreshInterval * 2.0) : refreshInterval
    }

    private func reloadRefreshIntervalFromDefaults() {
        let saved = UserDefaults.standard.object(forKey: "refreshInterval") as? Double ?? 1.0
        if saved != refreshInterval {
            refreshInterval = saved
        }
    }

    private func isModuleEnabled(_ key: String, defaultValue: Bool = true) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }

    private func updateAll(forceHeavyModules: Bool) {
        let now = Date()

        cpuMonitor.update()
        memoryMonitor.update()
        networkMonitor.update()

        if isModuleEnabled("showDisk"), forceHeavyModules || now.timeIntervalSince(lastDiskUpdate) >= diskUpdateInterval {
            diskMonitor.update()
            lastDiskUpdate = now
        }

        if isModuleEnabled("showBattery"), forceHeavyModules || now.timeIntervalSince(lastBatteryUpdate) >= batteryUpdateInterval {
            batteryMonitor.update()
            lastBatteryUpdate = now
        }

        if BuildConfig.supportsSensors,
           isModuleEnabled("showSensors", defaultValue: false),
           forceHeavyModules || now.timeIntervalSince(lastSensorUpdate) >= sensorUpdateInterval {
            sensorMonitor.update()
            lastSensorUpdate = now
        }
    }

    deinit {
        sensorMonitor.cleanup()
    }
}
