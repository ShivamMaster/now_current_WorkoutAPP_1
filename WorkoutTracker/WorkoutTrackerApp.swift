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

// MARK: - Splash Screen
struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    var body: some View {
        if isActive { MainTabView() }
        else {
            ZStack {
                Color.black.opacity(0.1).ignoresSafeArea()
                VStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable().scaledToFit().frame(width: 100, height: 100)
                        .foregroundColor(.blue).padding(20)
                    Text("ProgressBuddy")
                        .font(.system(size: 32, weight: .bold)).foregroundColor(.primary)
                }
                .scaleEffect(size).opacity(opacity)
                .onAppear { withAnimation(.easeIn(duration: 1.2)) { size = 1.0; opacity = 1.0 } }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { isActive = true }
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject private var dataManager: DataManager
    var body: some View {
        TabView {
            WorkoutListView()
                .tabItem { Label("Workouts", systemImage: "list.bullet") }
            ProgressView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .accentColor(.blue)
    }
}

// MARK: - Lottie View
struct AppLottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode
    init(animationName: String, loopMode: LottieLoopMode = .playOnce, animationSpeed: CGFloat = 1.0, contentMode: ContentMode = .fit) {
        self.animationName = animationName; self.loopMode = loopMode; self.animationSpeed = animationSpeed
        self.contentMode = contentMode == .fit ? .scaleAspectFit : .scaleAspectFill
    }
    func makeUIView(context: Context) -> LottieAnimationView {
        let v = LottieAnimationView()
        v.animation = LottieAnimation.named(animationName)
        v.loopMode = loopMode; v.animationSpeed = animationSpeed; v.contentMode = contentMode
        v.play(); return v
    }
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if !uiView.isAnimationPlaying { uiView.play() }
    }
}

extension String {
    func sha256() -> String {
        let hashed = SHA256.hash(data: Data(self.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
