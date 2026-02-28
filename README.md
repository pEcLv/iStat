# macOS 系统监控应用开发指南

基于 iStat Menus 7 的功能分析，制作类似的 macOS 系统监控应用。

## 核心监控模块

| 模块 | 监控内容 | 技术实现 |
|------|----------|----------|
| **CPU** | 使用率、频率、进程、温度 | `host_processor_info()`, SMC |
| **GPU** | 使用率、温度、显存 | IOKit, Metal API |
| **内存** | 使用量、压力、Swap、进程 | `host_statistics64()` |
| **磁盘** | 读写速度、容量、S.M.A.R.T | IOKit, DiskArbitration |
| **网络** | 上传/下载速度、连接数 | `getifaddrs()`, Network.framework |
| **传感器** | CPU/GPU/SSD温度、风扇转速 | SMC (System Management Controller) |
| **电池** | 电量、健康度、充电状态、循环次数 | IOKit PowerSources |

## UI 组件

1. **Menu Bar Items** — 状态栏图标 + 实时数据显示
2. **Dropdown Menus** — 点击展开详细信息面板
3. **Graphs** — 历史数据图表（折线图、柱状图）
4. **Notifications** — 阈值告警通知

## 项目结构

```
SystemMonitor/
├── App/
│   └── SystemMonitorApp.swift
├── MenuBar/
│   ├── MenuBarController.swift      # NSStatusItem 管理
│   └── MenuBarView.swift            # SwiftUI 菜单视图
├── Monitors/
│   ├── CPUMonitor.swift             # CPU 监控
│   ├── MemoryMonitor.swift          # 内存监控
│   ├── DiskMonitor.swift            # 磁盘监控
│   ├── NetworkMonitor.swift         # 网络监控
│   ├── BatteryMonitor.swift         # 电池监控
│   └── SensorMonitor.swift          # 温度/风扇 (SMC)
├── Models/
│   └── SystemMetrics.swift          # 数据模型
├── Views/
│   ├── CPUDetailView.swift
│   ├── MemoryDetailView.swift
│   └── ...
└── Utilities/
    ├── SMCKit.swift                 # SMC 读取封装
    └── Extensions.swift
```

## 关键代码示例

### 1. Menu Bar 应用基础

```swift
import SwiftUI

@main
struct SystemMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "CPU: --%"
            button.action = #selector(togglePopover)
        }

        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: MonitorView())
        popover.behavior = .transient
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
```

### 2. CPU 监控

```swift
import Foundation

class CPUMonitor: ObservableObject {
    @Published var usage: Double = 0
    @Published var perCoreUsage: [Double] = []

    private var timer: Timer?
    private var previousInfo: host_cpu_load_info?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCPUUsage()
        }
    }

    private func updateCPUUsage() {
        var cpuInfo: host_cpu_load_info?
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS, let info = cpuInfo, let prev = previousInfo else {
            previousInfo = cpuInfo
            return
        }

        let userDiff = Double(info.cpu_ticks.0 - prev.cpu_ticks.0)
        let systemDiff = Double(info.cpu_ticks.1 - prev.cpu_ticks.1)
        let idleDiff = Double(info.cpu_ticks.2 - prev.cpu_ticks.2)
        let niceDiff = Double(info.cpu_ticks.3 - prev.cpu_ticks.3)

        let totalTicks = userDiff + systemDiff + idleDiff + niceDiff

        DispatchQueue.main.async {
            self.usage = totalTicks > 0 ? ((userDiff + systemDiff + niceDiff) / totalTicks) * 100 : 0
        }

        previousInfo = cpuInfo
    }
}
```

### 3. 内存监控

```swift
class MemoryMonitor: ObservableObject {
    @Published var usedMemory: UInt64 = 0
    @Published var freeMemory: UInt64 = 0
    @Published var totalMemory: UInt64 = 0
    @Published var pressure: Double = 0

    func update() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)

        totalMemory = ProcessInfo.processInfo.physicalMemory
        freeMemory = UInt64(stats.free_count) * pageSize
        usedMemory = totalMemory - freeMemory

        // Memory pressure
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        pressure = Double(compressed) / Double(totalMemory) * 100
    }
}
```

### 4. 网络监控

```swift
import SystemConfiguration

class NetworkMonitor: ObservableObject {
    @Published var downloadSpeed: Double = 0  // bytes/sec
    @Published var uploadSpeed: Double = 0

    private var previousDownload: UInt64 = 0
    private var previousUpload: UInt64 = 0
    private var lastUpdate = Date()

    func update() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var totalDownload: UInt64 = 0
        var totalUpload: UInt64 = 0

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)
            guard name.hasPrefix("en") || name.hasPrefix("lo") else { continue }

            if let data = ptr.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                totalDownload += UInt64(data.pointee.ifi_ibytes)
                totalUpload += UInt64(data.pointee.ifi_obytes)
            }
        }

        let now = Date()
        let interval = now.timeIntervalSince(lastUpdate)

        if previousDownload > 0 && interval > 0 {
            downloadSpeed = Double(totalDownload - previousDownload) / interval
            uploadSpeed = Double(totalUpload - previousUpload) / interval
        }

        previousDownload = totalDownload
        previousUpload = totalUpload
        lastUpdate = now
    }
}
```

## 开发难点与注意事项

| 难点 | 说明 | 解决方案 |
|------|------|----------|
| **SMC 访问** | 读取温度/风扇需要访问 SMC | 使用 IOKit 或开源库如 SMCKit |
| **沙盒限制** | App Store 应用无法访问底层硬件 | 需要在 App Store 外分发，或申请特殊权限 |
| **Apple Silicon** | M系列芯片的传感器 key 不同 | 需要适配不同芯片架构 |
| **性能开销** | 频繁轮询会消耗资源 | 使用合理的刷新间隔 (1-2秒) |
| **权限** | 某些功能需要 root 权限 | 使用 Helper Tool + SMJobBless |

## 开发建议

1. **先做 MVP** — 从 CPU + 内存监控开始，实现 Menu Bar 基础框架
2. **逐步添加模块** — 网络 → 磁盘 → 电池 → 传感器
3. **UI 打磨** — 图表、动画、主题支持
