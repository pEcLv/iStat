import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var settingsWindow: NSWindow?
    var systemMonitor: SystemMonitorManager!
    let themeManager = ThemeManager()
    var cancellables = Set<AnyCancellable>()

    @AppStorage("menuBarStyle") private var menuBarStyle: MenuBarStyle = .cpuAndMemory

    func applicationDidFinishLaunching(_ notification: Notification) {
        Analytics.initialize()
        systemMonitor = SystemMonitorManager()
        setupMenuBar()
        systemMonitor.startMonitoring()
    }

    private func setupMenuBar() {
        // 使用固定宽度避免菜单栏按钮位置变化导致 popover 抖动
        statusItem = NSStatusBar.system.statusItem(withLength: 90)

        if let button = statusItem.button {
            button.title = "⏳"
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            // 使用等宽字体确保数字宽度一致
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 480)
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(
            rootView: MonitorView()
                .environmentObject(systemMonitor)
                .environmentObject(themeManager)
        )

        setupMenuBarUpdates()
    }

    private func setupMenuBarUpdates() {
        Publishers.CombineLatest4(
            systemMonitor.cpuMonitor.$usage,
            systemMonitor.memoryMonitor.$usagePercent,
            systemMonitor.networkMonitor.$downloadSpeed,
            systemMonitor.networkMonitor.$uploadSpeed
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] cpu, mem, down, up in
            self?.updateMenuBarTitle(cpu: cpu, mem: mem, down: down, up: up)
        }
        .store(in: &cancellables)
    }

    private func updateMenuBarTitle(cpu: Double, mem: Double, down: Double, up: Double) {
        guard let button = statusItem.button else { return }

        switch menuBarStyle {
        case .cpuOnly:
            statusItem.length = 70
            button.title = String(format: "CPU %3.0f%%", cpu)
        case .memoryOnly:
            statusItem.length = 75
            button.title = String(format: "MEM %3.0f%%", mem)
        case .cpuAndMemory:
            statusItem.length = 90
            button.title = String(format: "%3.0f%% | %3.0f%%", cpu, mem)
        case .networkSpeed:
            statusItem.length = 140
            button.title = "↓\(formatSpeed(down)) ↑\(formatSpeed(up))"
        case .compact:
            statusItem.length = 30
            button.title = ""
            button.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "System Monitor")
        }
    }

    private func formatSpeed(_ bps: Double) -> String {
        // 固定宽度格式，避免文字宽度变化
        if bps < 1024 { return String(format: "%4.0f B/s", bps) }
        if bps < 1024 * 1024 { return String(format: "%5.1fK/s", bps / 1024) }
        return String(format: "%5.1fM/s", bps / 1024 / 1024)
    }

    @objc func handleClick(sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            Analytics.trackPopoverOpened()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Open Monitor", action: #selector(openMonitor), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())

        let styleMenu = NSMenu()
        for style in MenuBarStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(changeMenuBarStyle(_:)), keyEquivalent: "")
            item.representedObject = style
            item.state = menuBarStyle == style ? .on : .off
            styleMenu.addItem(item)
        }
        let styleItem = NSMenuItem(title: "Menu Bar Style", action: nil, keyEquivalent: "")
        styleItem.submenu = styleMenu
        menu.addItem(styleItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func openMonitor() {
        togglePopover()
    }

    @objc func changeMenuBarStyle(_ sender: NSMenuItem) {
        if let style = sender.representedObject as? MenuBarStyle {
            menuBarStyle = style
            Analytics.trackMenuBarStyleChanged(style.rawValue)
        }
    }

    @objc func openSettings() {
        Analytics.trackSettingsOpened()
        if settingsWindow == nil {
            let settingsView = SettingsView(theme: themeManager)
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "Settings"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
