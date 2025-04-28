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

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false { // Added isDarkMode property
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "AppThemeMode")
        }
    }
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "AppThemeMode"),
           let theme = AppThemeMode(rawValue: savedTheme) {
            self.themeMode = theme
            self.isDarkMode = theme == .dark // Initialize isDarkMode
        } else {
            self.isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
            self.themeMode = self.isDarkMode ? .dark : .light
        }
    }
    
    @Published var themeMode: AppThemeMode = .system {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "AppThemeMode")
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
struct CalendarView: View {
    @EnvironmentObject private var dataManager: DataManager
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.fixed(18), spacing: 4), count: 7)
    private let monthSymbols = Calendar.current.monthSymbols

    // Helper to get all workout days as startOfDay
    private var workoutDays: Set<Date> {
        Set(dataManager.workouts.map { calendar.startOfDay(for: $0.date) })
    }

    // Helper to get all days in a given month of the current year
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
                let year = calendar.component(.year, from: Date())
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
                            let days = daysInMonth(month: month, year: year)
                            if let first = days.first {
                                let weekday = calendar.component(.weekday, from: first)
                                ForEach(0..<(weekday - 1), id: \.self) { _ in
                                    Color.clear.frame(width: 18, height: 18)
                                }
                            }
                            // Day boxes
                            ForEach(days, id: \.self) { day in
                                Rectangle()
                                    .fill(workoutDays.contains(day) ? Color.blue : Color(.systemGray5))
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