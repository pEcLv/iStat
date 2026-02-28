import SwiftUI

@main
struct SystemMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        Settings {
            SettingsView(theme: theme)
        }
    }
}
