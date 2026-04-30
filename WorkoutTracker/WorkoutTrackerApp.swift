import SwiftUI
import FirebaseCore
import FirebaseFirestore
import WidgetKit
import CoreData
import Lottie
import CryptoKit

// MARK: - App Entry Point
/// The main entry point for the WorkoutTracker application.
/// It initializes core services like Firebase and manages global state objects.
@main
struct WorkoutTrackerApp: App {
    // MARK: - State Objects
    /// Central data manager for handling CoreData persistence and sync logic.
    @StateObject private var dataManager = DataManager.shared
    
    /// Global theme manager for handling light/dark mode and custom accent colors.
    @StateObject private var themeManager = ThemeManager.shared

    // MARK: - Initialization
    init() {
        // Attempt to auto-configure Firebase for cloud sync functionality.
        _ = FirebaseConfigManager.shared.attemptAutoConfigure()
    }

    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            // Start with the SplashScreen which handles initial loading and tab navigation.
            SplashScreen()
                .environmentObject(dataManager)
                .environmentObject(themeManager)
                // Apply the user's preferred color scheme globally.
                .preferredColorScheme(themeManager.themeMode.colorScheme)
        }
    }
}
