import SwiftUI

// Theme management code
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
    // Convert Color to hex string
    func toHex() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        let rgb: Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        return String(format:"#%06x", rgb)
        #else
        return nil
        #endif
    }
    
    // Create Color from hex string
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool
    @Published var calendarBoxColor: Color
    @Published var themeMode: AppThemeMode

    init() {
        // Set default values first
        self.isDarkMode = false
        self.themeMode = .system
        self.calendarBoxColor = .blue

        // Now safely use self to update properties
        if let savedTheme = UserDefaults.standard.string(forKey: "AppThemeMode"),
           let theme = AppThemeMode(rawValue: savedTheme) {
            self.themeMode = theme
            self.isDarkMode = theme == .dark
        } else {
            let dark = UIScreen.main.traitCollection.userInterfaceStyle == .dark
            self.isDarkMode = dark
            self.themeMode = dark ? .dark : .light
        }
        if let hex = UserDefaults.standard.string(forKey: "CalendarBoxColor"),
           let color = Color(hex: hex) {
            self.calendarBoxColor = color
        }
    }
}

// Splash screen implementation
struct SplashScreen: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            MainTabView()
        } else {
            VStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("ProgressBuddy")
                    .font(.largeTitle)
                    .bold()
                
                // ProgressView has been removed from here
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isActive = true
                }
            }
        }
    }
}

// Main tab view for the app
struct MainTabView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        TabView {
            WorkoutListView()
                .tabItem {
                    Label("Workouts", systemImage: "list.bullet")
                }
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(Color.blue)
    }
}

// Add this new view inside the same file
struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    @ObservedObject private var themeManager = ThemeManager.shared

    let weightUnits = ["kg", "lbs"]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preferences")) {
                    Picker("Weight Unit", selection: $weightUnit) {
                        ForEach(weightUnits, id: \.self) { unit in
                            Text(unit)
                        }
                    }
                    Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                        .onChange(of: themeManager.isDarkMode) { value in
                            themeManager.themeMode = value ? .dark : .light
                        }
                }
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                }
                Section(header: Text("Calendar Color")) {
                    ColorPicker("Workout Day Color", selection: $themeManager.calendarBoxColor)
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("This app does not collect any personal data. All workout information is stored locally on your device and is not transmitted to any external servers.")
                Text("Workout data is only used within the app to display your progress and workout history.")
                Text("The app does not use any analytics services, advertising frameworks, or other tracking mechanisms.")
                Text("If you have any questions about our privacy practices, please contact us.")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct CalendarView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.fixed(18), spacing: 4), count: 7)
    private let monthSymbols = Calendar.current.monthSymbols

    @State private var yearInput: String = "\(Calendar.current.component(.year, from: Date()))"
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // Helper to get all workout days as startOfDay for the selected year
    private var workoutDays: Set<Date> {
        Set(
            dataManager.workouts
                .filter { calendar.component(.year, from: $0.date) == selectedYear }
                .map { calendar.startOfDay(for: $0.date) }
        )
    }

    // Helper to get all days in a given month of the selected year
    private func daysInMonth(month: Int, year: Int) -> [Date] {
        var days: [Date] = []
        let components = DateComponents(year: year, month: month)
        guard let monthStart = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return days }
        for day in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(date)
            }
        }
        return days
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Centered, editable year input
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Text("Year:")
                            .font(.headline)
                        TextField("Year", text: $yearInput)
                            .keyboardType(.numberPad)
                            .frame(width: 70)
                            .multilineTextAlignment(.center)
                            .onSubmit {
                                if let year = Int(yearInput), year > 0 {
                                    selectedYear = year
                                }
                            }
                            .onChange(of: yearInput) { newValue in
                                if let year = Int(newValue), year > 0 {
                                    selectedYear = year
                                }
                            }
                    }
                    Spacer()
                }
                .padding(.bottom, 8)

                ForEach(1...12, id: \.self) { month in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(monthSymbols[month - 1])
                            .font(.headline)
                            .padding(.leading, 8)
                        LazyVGrid(columns: columns, spacing: 4) {
                            // Weekday headers
                            ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                                Text(symbol.prefix(1))
                                    .font(.caption2)
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.secondary)
                            }
                            // Padding for first weekday
                            let days = daysInMonth(month: month, year: selectedYear)
                            if let first = days.first {
                                let weekday = calendar.component(.weekday, from: first)
                                ForEach(0..<(weekday - 1), id: \.self) { _ in
                                    Color.clear.frame(width: 18, height: 18)
                                }
                            }
                            // Day boxes
                            ForEach(days, id: \.self) { day in
                                Rectangle()
                                    .fill(workoutDays.contains(day) ? themeManager.calendarBoxColor : Color(.systemGray5))
                                    .frame(width: 18, height: 18)
                                    .cornerRadius(3)
                                    .overlay(
                                        Text("\(calendar.component(.day, from: day))")
                                            .font(.system(size: 8))
                                            .foregroundColor(.primary)
                                    )
                                    .accessibilityLabel(Text("\(formattedDate(day)): \(workoutDays.contains(day) ? "Workout logged" : "No workout")"))
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

@main
struct WorkoutTrackerApp: App {
    // Initialize DataManager as a StateObject to maintain state throughout the app
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(dataManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.themeMode.colorScheme)
        }
    }
}