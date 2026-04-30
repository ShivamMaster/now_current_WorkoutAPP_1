import SwiftUI

// MARK: - App Theme Mode
/// Represents the supported visual themes for the application.
enum AppThemeMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { self.rawValue }
    
    /// Maps the theme mode to a SwiftUI `ColorScheme`.
    /// Returns `nil` for `.system` to allow the OS to decide.
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

/// Manages the application's visual style, including theme mode (light/dark) and custom accent colors.
class ThemeManager: ObservableObject {
    // MARK: - Singleton
    /// Shared instance for global access.
    static let shared = ThemeManager()
    
    // MARK: - Published Properties
    /// Boolean indicating if dark mode is explicitly enabled.
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            let newMode: AppThemeMode = isDarkMode ? .dark : .light
            if themeMode != newMode {
                themeMode = newMode
            }
            // Trigger sync status check since theme changes are considered "state".
            DataManager.shared.scheduleHashCheck()
        }
    }

    /// The base color used for calendar indicators.
    @Published var calendarBoxColor: Color {
        didSet {
            if let hex = calendarBoxColor.toHex() {
                UserDefaults.standard.set(hex, forKey: "CalendarBoxColor")
            }
            DataManager.shared.scheduleHashCheck()
        }
    }

    /// The current theme selection (light, dark, or system).
    @Published var themeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "AppThemeMode")
            let shouldBeDark = themeMode == .dark
            if isDarkMode != shouldBeDark {
                isDarkMode = shouldBeDark
            }
            DataManager.shared.scheduleHashCheck()
        }
    }

    /// A dictionary mapping split IDs to their specific UI color.
    @Published var splitColors: [String: Color] {
        didSet {
            let hexDict = splitColors.compactMapValues { $0.toHex() }
            if let data = try? JSONEncoder().encode(hexDict) {
                UserDefaults.standard.set(data, forKey: "SplitColorsDict")
            }
            DataManager.shared.scheduleHashCheck()
        }
    }

    /// The color used to highlight days with multiple different splits in the calendar.
    @Published var multipleSplitsColor: Color {
        didSet {
            if let hex = multipleSplitsColor.toHex() {
                UserDefaults.standard.set(hex, forKey: "MultipleSplitsColor")
            }
            DataManager.shared.scheduleHashCheck()
        }
    }

    init() {
        // Load isDarkMode
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        // Load themeMode
        if let s = UserDefaults.standard.string(forKey: "AppThemeMode"),
           let t = AppThemeMode(rawValue: s) {
            self.themeMode = t
            self.isDarkMode = (t == .dark)
        } else {
            // Default to system
            let dark = UIScreen.main.traitCollection.userInterfaceStyle == .dark
            self.isDarkMode = dark
            self.themeMode = dark ? .dark : .light
        }
        
        // Load calendarBoxColor
        if let hex = UserDefaults.standard.string(forKey: "CalendarBoxColor"),
           let c = Color(hex: hex) {
            self.calendarBoxColor = c
        } else {
            self.calendarBoxColor = .blue
        }

        // Load multipleSplitsColor
        if let hex = UserDefaults.standard.string(forKey: "MultipleSplitsColor"),
           let c = Color(hex: hex) {
            self.multipleSplitsColor = c
        } else {
            self.multipleSplitsColor = .purple
        }

        // Load splitColors
        if let data = UserDefaults.standard.data(forKey: "SplitColorsDict"),
           let hexDict = try? JSONDecoder().decode([String: String].self, from: data) {
            self.splitColors = hexDict.compactMapValues { Color(hex: $0) }
        } else {
            self.splitColors = [:]
        }
    }
}

extension Color {
    func toHex() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
        #else
        return nil
        #endif
    }
    
    init?(hex: String) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        self.init(red: Double((rgb & 0xFF0000) >> 16)/255, green: Double((rgb & 0x00FF00) >> 8)/255, blue: Double(rgb & 0x0000FF)/255)
    }
}