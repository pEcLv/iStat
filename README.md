# System Monitor

一款轻量级 macOS 系统监控应用，类似 iStat Menus。

## 功能特性

- **CPU 监控** — 使用率、用户/系统占比、60秒历史图表
- **内存监控** — 使用率、Active/Wired/Compressed 分类、历史图表
- **网络监控** — 实时上传/下载速度、双线图表
- **磁盘监控** — 容量、使用率、剩余空间
- **电池监控** — 电量、健康度、循环次数、充电状态
- **传感器监控** — CPU/GPU 温度、风扇转速 (需要非沙盒环境)

## 界面预览

- Menu Bar 实时显示 CPU/内存使用率
- 点击弹出详细监控面板
- 右键菜单快速切换显示样式
- 支持 Light/Dark/System 主题

## 项目结构

```
SystemMonitor/
├── App/
│   ├── SystemMonitorApp.swift    # 应用入口
│   └── AppDelegate.swift         # Menu Bar 控制
├── Monitors/
│   ├── CPUMonitor.swift          # CPU 监控
│   ├── MemoryMonitor.swift       # 内存监控
│   ├── NetworkMonitor.swift      # 网络监控
│   ├── DiskMonitor.swift         # 磁盘监控
│   ├── BatteryMonitor.swift      # 电池监控
│   └── SensorMonitor.swift       # 温度/风扇
├── Models/
│   └── SystemMetrics.swift       # 监控管理器
├── Views/
│   ├── MonitorView.swift         # 主监控面板
│   ├── Charts.swift              # 图表组件
│   └── SettingsView.swift        # 设置界面
├── Utilities/
│   ├── Extensions.swift          # 扩展方法
│   └── Theme.swift               # 主题管理
└── Assets.xcassets
```

## 技术实现

| 模块 | API |
|------|-----|
| CPU | `host_statistics()` + `HOST_CPU_LOAD_INFO` |
| 内存 | `host_statistics64()` + `HOST_VM_INFO64` |
| 网络 | `getifaddrs()` + `if_data` |
| 磁盘 | `FileManager.mountedVolumeURLs()` |
| 电池 | `IOPSCopyPowerSourcesInfo()` |
| 温度 | `IOServiceOpen("AppleSMC")` |

## 构建运行

```bash
# 用 Xcode 打开项目
open SystemMonitor/SystemMonitor.xcodeproj

# 或命令行构建
xcodebuild -project SystemMonitor/SystemMonitor.xcodeproj -scheme SystemMonitor build
```

要求：
- macOS 13.0+
- Xcode 15.0+
- Swift 5.0+

## 设置选项

- **刷新间隔** — 0.5s / 1s / 2s / 5s
- **Menu Bar 样式** — CPU Only / Memory Only / CPU & Memory / Network / Compact
- **模块开关** — 可单独开关各监控模块
- **主题** — System / Light / Dark

## 注意事项

- 温度/风扇监控需要禁用 App Sandbox
- Apple Silicon 芯片的 SMC key 与 Intel 不同
- 建议刷新间隔设为 1-2 秒以平衡性能

## License

MIT
