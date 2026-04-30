import SwiftUI
import Lottie

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
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
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.scenePhase) var scenePhase
    @State private var showUnsyncedAlert = false
    @State private var selectedTab = 0
    @State private var lastTapTime: Date = Date()
    @State private var tapCount: Int = 0
    
    var body: some View {
        let selectionBinding = Binding<Int>(
            get: { self.selectedTab },
            set: { newValue in
                if newValue == self.selectedTab {
                    // Tapped already selected tab
                    handleRepeatTap()
                } else {
                    // Switched tabs
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
        .onChange(of: scenePhase) { newPhase in
            if (newPhase == .inactive || newPhase == .active) && dataManager.hasUnsyncedChanges {
                showUnsyncedAlert = true
            }
        }
        .fullScreenCover(isPresented: $showUnsyncedAlert) {
            SyncWarningView(selectedTab: $selectedTab)
                .environmentObject(dataManager)
        }
    }
    
    private func handleRepeatTap() {
        guard dataManager.clickBackEnabled else { return }
        
        let now = Date()
        let diff = now.timeIntervalSince(lastTapTime)
        lastTapTime = now
        
        if dataManager.clickBackDepth == 1 {
            // Instant pop to root
            triggerPop()
        } else {
            // 2 clicks required
            if diff < 0.5 { // Within 500ms
                tapCount += 1
                if tapCount >= 1 { // Second tap (initial state was 0)
                    triggerPop()
                    tapCount = 0
                }
            } else {
                tapCount = 0
            }
        }
    }
    
    private func triggerPop() {
        switch selectedTab {
        case 0: dataManager.popToRootWorkout += 1
        case 1: dataManager.popToRootProgress += 1
        case 2: dataManager.popToRootCalendar += 1
        case 3: dataManager.popToRootSettings += 1
        default: break
        }
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