import SwiftUI

// MARK: - Theme Management
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

extension Color {
    func toHex() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
        #else
        return nil
        #endif
    }
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        self.init(red: Double((rgb & 0xFF0000) >> 16)/255, green: Double((rgb & 0x00FF00) >> 8)/255, blue: Double(rgb & 0x0000FF)/255)
    }
}

// MARK: - ThemeManager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            let newMode: AppThemeMode = isDarkMode ? .dark : .light
            if themeMode != newMode { themeMode = newMode }
            // Feature 6: schedule a hash check instead of blindly marking unsynced
            DataManager.shared.scheduleHashCheck()
        }
    }
    @Published var calendarBoxColor: Color {
        didSet {
            if let hex = calendarBoxColor.toHex() { UserDefaults.standard.set(hex, forKey: "CalendarBoxColor") }
            DataManager.shared.scheduleHashCheck()
        }
    }
    @Published var themeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "AppThemeMode")
            let shouldBeDark = themeMode == .dark
            if isDarkMode != shouldBeDark { isDarkMode = shouldBeDark }
            DataManager.shared.scheduleHashCheck()
        }
    }

    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        if let s = UserDefaults.standard.string(forKey: "AppThemeMode"), let t = AppThemeMode(rawValue: s) {
            self.themeMode = t; self.isDarkMode = t == .dark
        } else {
            #if canImport(UIKit)
            let dark = UIScreen.main.traitCollection.userInterfaceStyle == .dark
            #else
            let dark = false
            #endif
            self.isDarkMode = dark; self.themeMode = dark ? .dark : .light
        }
        if let hex = UserDefaults.standard.string(forKey: "CalendarBoxColor"), let c = Color(hex: hex) {
            self.calendarBoxColor = c
        } else { self.calendarBoxColor = .blue }
    }
}