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
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(Color.blue)
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