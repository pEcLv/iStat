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
        systemMonitor = SystemMonitorManager()
        setupMenuBar()
        systemMonitor.startMonitoring()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "⏳"
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MonitorView()
                .environmentObject(systemMonitor)
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
            button.title = String(format: "CPU %.0f%%", cpu)
        case .memoryOnly:
            button.title = String(format: "MEM %.0f%%", mem)
        case .cpuAndMemory:
            button.title = String(format: "%.0f%% | %.0f%%", cpu, mem)
        case .networkSpeed:
            button.title = "↓\(formatSpeed(down)) ↑\(formatSpeed(up))"
        case .compact:
            button.title = ""
            button.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "System Monitor")
        }
    }

    private func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 { return String(format: "%.0fB", bps) }
        if bps < 1024 * 1024 { return String(format: "%.0fK", bps / 1024) }
        return String(format: "%.1fM", bps / 1024 / 1024)
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
        }
    }

    @objc func openSettings() {
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
