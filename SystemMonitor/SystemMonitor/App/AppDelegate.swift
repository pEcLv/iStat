import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var systemMonitor = SystemMonitorManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        systemMonitor.startMonitoring()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "CPU: --%"
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MonitorView().environmentObject(systemMonitor)
        )

        // 监听 CPU 使用率更新菜单栏
        systemMonitor.cpuMonitor.$usage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] usage in
                self?.statusItem.button?.title = String(format: "CPU: %.0f%%", usage)
            }
            .store(in: &systemMonitor.cancellables)
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
