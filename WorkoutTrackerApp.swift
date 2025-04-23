import SwiftUI

@main
struct WorkoutTrackerApp: App {
    // Initialize DataManager as a StateObject to maintain state throughout the app
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
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
            .environmentObject(dataManager) // Make dataManager available to all views
        }
    }
} 