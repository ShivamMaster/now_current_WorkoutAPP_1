import SwiftUI
import Lottie
import UserNotifications

// MARK: - Splash Screen
/// The initial view shown when the app launches.
/// Handles the transition from a branded splash screen to the main tab interface.
struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            // Transition to the main application interface once loading is complete.
            MainTabView()
        } else {
            ZStack {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(20)
                    
                    Text("ProgressBuddy")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    // Trigger entry animations.
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                // Request notification permissions for sync alerts.
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                
                // Pause for 2 seconds before entering the app.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

// MARK: - Main Tab Interface
/// The primary navigation container for the application, organizing the main features into tabs.
struct MainTabView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.scenePhase) var scenePhase
    
    /// Controls the visibility of the mandatory sync warning overlay.
    @State private var showUnsyncedAlert = false
    
    /// Tracks the currently selected tab.
    @State private var selectedTab = 0
    
    // MARK: - Click Back Properties
    @State private var lastTapTime: Date = Date()
    @State private var tapCount: Int = 0
    
    var body: some View {
        // Custom binding to detect repeat taps on the same tab (for "Click Back" feature).
        let selectionBinding = Binding<Int>(
            get: { self.selectedTab },
            set: { newValue in
                if newValue == self.selectedTab {
                    handleRepeatTap()
                } else {
                    self.selectedTab = newValue
                    self.tapCount = 0
                }
            }
        )
        
        return TabView(selection: selectionBinding) {
            WorkoutListView()
                .tabItem {
                    Label("Workouts", systemImage: "list.bullet")
                }
                .tag(0)
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Handle app lifecycle events for data safety.
            if (newPhase == .inactive || newPhase == .active) && dataManager.hasUnsyncedChanges {
                showUnsyncedAlert = true
                // Prevent the device from sleeping while in the sync warning state.
                UIApplication.shared.isIdleTimerDisabled = true
                
                if newPhase == .inactive {
                    sendUnsyncedNotification()
                }
            } else if newPhase == .active {
                UIApplication.shared.isIdleTimerDisabled = false
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Aggressive guard against backgrounding with unsynced changes.
            if dataManager.hasUnsyncedChanges {
                showUnsyncedAlert = true
            }
        }
        .fullScreenCover(isPresented: $showUnsyncedAlert) {
            SyncWarningView(selectedTab: $selectedTab)
                .environmentObject(dataManager)
        }
        // Conditionally defer system gestures to prevent accidental backgrounding when unsynced.
        .defersSystemGestures(on: dataManager.hasUnsyncedChanges ? .bottom : [])
    }
    
    // MARK: - Logic
    
    /// Handles repeated taps on an active tab to trigger a "Pop to Root" navigation event.
    private func handleRepeatTap() {
        guard dataManager.clickBackEnabled else { return }
        
        let now = Date()
        let diff = now.timeIntervalSince(lastTapTime)
        lastTapTime = now
        
        if dataManager.clickBackDepth == 1 {
            triggerPop()
        } else {
            // Requires two rapid taps (double-click style).
            if diff < 0.5 {
                tapCount += 1
                if tapCount >= 1 {
                    triggerPop()
                    tapCount = 0
                }
            } else {
                tapCount = 0
            }
        }
    }
    
    /// Increments the trigger counter for the current tab to signal a navigation reset.
    private func triggerPop() {
        switch selectedTab {
        case 0: dataManager.popToRootWorkout += 1
        case 1: dataManager.popToRootProgress += 1
        case 2: dataManager.popToRootCalendar += 1
        case 3: dataManager.popToRootSettings += 1
        default: break
        }
    }

    /// Sends a local notification to the user if they background the app with unsynced data.
    private func sendUnsyncedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Unsynced Data!"
        content.body = "You have unsaved changes. Please return to the app to sync your data."
        content.sound = .defaultCritical
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Blocking Sync Warning View
struct SyncWarningView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int

    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .shadow(radius: 5)

                Text("Unsynced Changes")
                    .font(.title.bold())

                Text("You have workout data that hasn't been backed up to the cloud yet. We recommend syncing before you leave to ensure your data is safe.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(spacing: 15) {
                    Button(action: {
                        selectedTab = 3 // Settings
                        dismiss()
                    }) {
                        Text("Go to Settings & Sync")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }

                    Button(action: {
                        dismiss()
                    }) {
                        Text("I'll do it later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Task 11: Actually prevent leaving until answered
        }
    }
}

// MARK: - Lottie View Support
struct AppLottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode

    init(animationName: String, 
         loopMode: LottieLoopMode = .playOnce, 
         animationSpeed: CGFloat = 1.0, 
         contentMode: ContentMode = .fit) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
        self.contentMode = contentMode == .fit ? .scaleAspectFit : .scaleAspectFill
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.animation = LottieAnimation.named(animationName)
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = contentMode
        animationView.play()
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if !uiView.isAnimationPlaying {
            uiView.play()
        }
    }
}