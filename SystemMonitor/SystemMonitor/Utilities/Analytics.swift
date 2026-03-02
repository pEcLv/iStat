import Foundation
import TelemetryDeck

enum Analytics {
    // TODO: 替换为你的 TelemetryDeck App ID
    private static let appID = "YOUR_APP_ID_HERE"

    static func initialize() {
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)

        // 发送启动事件
        send("app.launched")
    }

    static func send(_ signalName: String, parameters: [String: String] = [:]) {
        TelemetryDeck.signal(signalName, parameters: parameters)
    }

    // MARK: - 预定义事件

    static func trackAppLaunched() {
        send("app.launched")
    }

    static func trackPopoverOpened() {
        send("popover.opened")
    }

    static func trackSettingsOpened() {
        send("settings.opened")
    }

    static func trackThemeChanged(_ theme: String) {
        send("theme.changed", parameters: ["theme": theme])
    }

    static func trackMenuBarStyleChanged(_ style: String) {
        send("menubar.style.changed", parameters: ["style": style])
    }

    static func trackModuleToggled(_ module: String, enabled: Bool) {
        send("module.toggled", parameters: [
            "module": module,
            "enabled": enabled ? "true" : "false"
        ])
    }
}
