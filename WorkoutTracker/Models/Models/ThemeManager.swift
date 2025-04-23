import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

class ThemeManager {
    static var isDarkMode: Bool = false
    static func toggleDarkMode() {
        isDarkMode.toggle()
    }
}
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var themeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "AppThemeMode")
        }
    }
    
    init() {
        // Load saved theme or default to system
        if let savedTheme = UserDefaults.standard.string(forKey: "AppThemeMode"),
           let theme = AppThemeMode(rawValue: savedTheme) {
            self.themeMode = theme
        } else {
            self.themeMode = .system
        }
    }
} 