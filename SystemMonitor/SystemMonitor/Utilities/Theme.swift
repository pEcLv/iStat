import SwiftUI
import Combine

// MARK: - Theme

enum AppTheme: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var currentTheme: AppTheme = .system

    var colorScheme: ColorScheme? { currentTheme.colorScheme }
}

// MARK: - Colors

extension Color {
    static let cpuColor = Color.blue
    static let memoryColor = Color.green
    static let networkDownColor = Color.cyan
    static let networkUpColor = Color.orange
    static let diskColor = Color.purple
    static let batteryColor = Color.yellow
    static let tempNormal = Color.green
    static let tempWarm = Color.orange
    static let tempHot = Color.red
}
