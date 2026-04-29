import SwiftUI
import FirebaseCore
import FirebaseFirestore
import WidgetKit
import CoreData
import Lottie
import CryptoKit

// MARK: - Main App
@main
struct WorkoutTrackerApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    init() { _ = FirebaseConfigManager.shared.attemptAutoConfigure() }

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(dataManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.themeMode.colorScheme)
        }
    }
}
