import SwiftUI
import FirebaseCore
import FirebaseFirestore
import WidgetKit
import CoreData

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
    
    @Published var isDarkMode: Bool {
        didSet {
            // Save dark mode toggle and theme mode
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            // Update themeMode accordingly
            let newMode: AppThemeMode = isDarkMode ? .dark : .light
            if themeMode != newMode {
                themeMode = newMode
            }
        }
    }
    @Published var calendarBoxColor: Color {
        didSet {
            if let hex = calendarBoxColor.toHex() {
                UserDefaults.standard.set(hex, forKey: "CalendarBoxColor")
            }
        }
    }
    @Published var themeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: "AppThemeMode")
            // Update isDarkMode accordingly
            let shouldBeDark = themeMode == .dark
            if isDarkMode != shouldBeDark {
                isDarkMode = shouldBeDark
            }
        }
    }

    init() {
        // Set default values first
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
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
        } else {
            self.calendarBoxColor = .blue
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

// MARK: - Settings View with Firebase Config
struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    @AppStorage("firebaseID") private var firebaseID: String = ""
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Firebase Config States
    @State private var apiKey = ""
    @State private var projectId = ""
    @State private var googleAppId = ""
    @State private var gcmSenderId = ""
    @State private var isConfigExpanded = false
    
    @State private var showingAlert = false
    @State private var showingConfirmation = false
    @State private var showingBackupConfirmation = false
    @State private var showSuccessAnimation = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    let weightUnits = ["kg", "lbs"]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Cloud Backup Configuration")) {
                    DisclosureGroup("Firebase Project Credentials", isExpanded: $isConfigExpanded) {
                        VStack(alignment: .leading, spacing: 10) {
                            SecureField("API Key", text: $apiKey)
                            TextField("Project ID", text: $projectId)
                            TextField("Google App ID", text: $googleAppId)
                            TextField("GCM Sender ID", text: $gcmSenderId)
                            
                            Button("Save & Connect") {
                                saveAndConnect()
                            }
                            .disabled(apiKey.isEmpty || projectId.isEmpty || googleAppId.isEmpty || gcmSenderId.isEmpty)
                            .padding(.top, 5)
                            
                            if FirebaseConfigManager.shared.isConfigured {
                                Text("Connected!")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    TextField("Enter User Unique ID", text: $firebaseID)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: backupData) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Backup Data to Cloud")
                        }
                    }
                    .disabled(firebaseID.isEmpty || !FirebaseConfigManager.shared.isConfigured)
                    
                    Button(action: restoreData) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("Restore Data from Cloud")
                        }
                        .foregroundColor(.red)
                    }
                    .disabled(firebaseID.isEmpty || !FirebaseConfigManager.shared.isConfigured)
                }
                
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
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .confirmationDialog("Confirm Backup", isPresented: $showingBackupConfirmation, titleVisibility: .visible) {
                Button("Backup") {
                    performBackup()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will upload your workout data to the cloud, overwriting any previous backup for this User ID.")
            }
            .confirmationDialog("Confirm Restore", isPresented: $showingConfirmation, titleVisibility: .visible) {
                Button("Restore", role: .destructive) {
                    performRestore()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will OVERWRITE all current data on this device with data from the cloud. Are you sure?")
            }
            .overlay {
                if showSuccessAnimation {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: showSuccessAnimation)
                            
                            Text("Success!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onAppear {
                loadCredentials()
            }
        }
    }
    
    private func loadCredentials() {
        let creds = FirebaseConfigManager.shared.getStoredCredentials()
        self.apiKey = creds.apiKey
        self.projectId = creds.projectId
        self.googleAppId = creds.googleAppId
        self.gcmSenderId = creds.gcmSenderId
        
        if apiKey.isEmpty || projectId.isEmpty {
            isConfigExpanded = true
        }
    }
    
    private func saveAndConnect() {
        let success = FirebaseConfigManager.shared.configure(
            apiKey: apiKey,
            projectId: projectId,
            googleAppId: googleAppId,
            gcmSenderId: gcmSenderId
        )
        
        if success {
            alertTitle = "Success"
            alertMessage = "Firebase Configured Successfully."
            isConfigExpanded = false
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to configure Firebase."
        }
        showingAlert = true
    }
    
    private func backupData() {
        showingBackupConfirmation = true
    }
    
    private func performBackup() {
        guard let jsonString = DataManager.shared.exportDataJSON() else {
            alertTitle = "Error"
            alertMessage = "Failed to prepare data for backup."
            showingAlert = true
            return
        }
        
        let id = firebaseID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        FirebaseManager.shared.uploadData(json: jsonString, userId: id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Show success animation
                    showSuccessAnimation = true
                    
                    // Hide after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSuccessAnimation = false
                    }
                case .failure(let error):
                    alertTitle = "Backup Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func restoreData() {
        showingConfirmation = true
    }
    
    private func performRestore() {
        let id = firebaseID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        FirebaseManager.shared.downloadData(userId: id) { result in
            switch result {
            case .success(let jsonString):
                DataManager.shared.importDataJSON(json: jsonString) { success in
                    DispatchQueue.main.async {
                        if success {
                            // Show success animation
                            showSuccessAnimation = true
                            
                            // Hide after 1.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showSuccessAnimation = false
                            }
                        } else {
                            alertTitle = "Error"
                            alertMessage = "Failed to import data."
                            showingAlert = true
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    alertTitle = "Restore Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
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

// MARK: - Data Serialization
struct SerializedExercise: Codable {
    let name: String
    let type: String
    let sets: Int16
    let reps: Int16
    let weight: Double
    let duration: Int16
    let distance: Double
    let calories: Int16
    let holdTime: Int16
    let notes: String?
    let order: Int16
}

struct SerializedWorkout: Codable {
    let name: String
    let date: Date
    let duration: Int16
    let notes: String?
    let exercises: [SerializedExercise]
}

extension DataManager {
    // Export all data to a JSON string
    func exportDataJSON() -> String? {
        fetchWorkouts()
        
        let serializedWorkouts = workouts.map { workout -> SerializedWorkout in
            let exercises = (workout.exerciseArray).map { exercise -> SerializedExercise in
                return SerializedExercise(
                    name: exercise.name,
                    type: exercise.exerciseType ?? "strength",
                    sets: exercise.sets,
                    reps: exercise.reps,
                    weight: exercise.weight,
                    duration: exercise.duration,
                    distance: exercise.distance,
                    calories: exercise.calories,
                    holdTime: exercise.holdTime,
                    notes: exercise.notes,
                    order: exercise.order
                )
            }
            
            return SerializedWorkout(
                name: workout.name,
                date: workout.date,
                duration: workout.duration,
                notes: workout.notes,
                exercises: exercises
            )
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(serializedWorkouts)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to encode workouts: \(error)")
            return nil
        }
    }
    
    // Import data from JSON string (Overwrites existing data)
    func importDataJSON(json: String, completion: @escaping (Bool) -> Void) {
        guard let data = json.data(using: .utf8) else {
            print("Failed to convert string to data")
            completion(false)
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let serializedWorkouts = try decoder.decode([SerializedWorkout].self, from: data)
            
            container.performBackgroundTask { context in
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Workout")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteRequest)
                    
                    for sWorkout in serializedWorkouts {
                        let workout = WorkoutModel(context: context)
                        workout.id = UUID()
                        workout.name = sWorkout.name
                        workout.date = sWorkout.date
                        workout.duration = sWorkout.duration
                        workout.notes = sWorkout.notes
                        
                        for sExercise in sWorkout.exercises {
                            let exercise = ExerciseModel(context: context)
                            exercise.id = UUID()
                            exercise.name = sExercise.name
                            exercise.exerciseType = sExercise.type
                            exercise.sets = sExercise.sets
                            exercise.reps = sExercise.reps
                            exercise.weight = sExercise.weight
                            exercise.duration = sExercise.duration
                            exercise.distance = sExercise.distance
                            exercise.calories = sExercise.calories
                            exercise.holdTime = sExercise.holdTime
                            exercise.notes = sExercise.notes
                            exercise.order = sExercise.order
                            exercise.workout = workout
                        }
                    }
                    
                    try context.save()
                    
                    DispatchQueue.main.async {
                        self.fetchWorkouts()
                        WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutCalendarWidget")
                        completion(true)
                    }
                    
                } catch {
                    print("Error importing data: \(error)")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
            
        } catch {
            print("Failed to decode workouts: \(error)")
            completion(false)
        }
    }
}

// MARK: - Firebase Manager
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // Upload serialized JSON data to Firestore
    func uploadData(json: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 503, userInfo: [NSLocalizedDescriptionKey: "Firebase is not configured. Please enter credentials in Settings."])))
            return
        }
        
        if userId.isEmpty {
            completion(.failure(NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])))
            return
        }
        
        // Structure the data to save
        let data: [String: Any] = [
            "timestamp": FieldValue.serverTimestamp(),
            "workoutData": json,
            "deviceModel": UIDevice.current.name
        ]
        
        db.collection("backups").document(userId).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Download serialized JSON data from Firestore
    func downloadData(userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 503, userInfo: [NSLocalizedDescriptionKey: "Firebase is not configured. Please enter credentials in Settings."])))
            return
        }

        if userId.isEmpty {
            completion(.failure(NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])))
            return
        }
        
        db.collection("backups").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists,
                  let data = snapshot.data(),
                  let jsonString = data["workoutData"] as? String else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No backup found for this ID"])))
                return
            }
            
            completion(.success(jsonString))
        }
    }
}

// MARK: - Firebase Configuration Manager
class FirebaseConfigManager: ObservableObject {
    static let shared = FirebaseConfigManager()
    
    @Published var isConfigured: Bool = false
    
    private let kApiKey = "firebase_apiKey"
    private let kProjectId = "firebase_projectId"
    private let kGoogleAppId = "firebase_googleAppId"
    private let kGcmSenderId = "firebase_gcmSenderId"
    
    // Attempt to configure using saved credentials
    func attemptAutoConfigure() -> Bool {
        let defaults = UserDefaults.standard
        guard let apiKey = defaults.string(forKey: kApiKey), !apiKey.isEmpty,
              let projectId = defaults.string(forKey: kProjectId), !projectId.isEmpty,
              let googleAppId = defaults.string(forKey: kGoogleAppId), !googleAppId.isEmpty,
              let gcmSenderId = defaults.string(forKey: kGcmSenderId), !gcmSenderId.isEmpty else {
            print("FirebaseConfigManager: Missing credentials in UserDefaults.")
            return false
        }
        
        return configure(apiKey: apiKey, projectId: projectId, googleAppId: googleAppId, gcmSenderId: gcmSenderId)
    }
    
    // Configure with specific credentials
    func configure(apiKey: String, projectId: String, googleAppId: String, gcmSenderId: String) -> Bool {
        // Save to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(apiKey, forKey: kApiKey)
        defaults.set(projectId, forKey: kProjectId)
        defaults.set(googleAppId, forKey: kGoogleAppId)
        defaults.set(gcmSenderId, forKey: kGcmSenderId)
        
        // If already configured, we might need to recreate the app or just return true
        // Firebase doesn't support re-configuring the default app easily at runtime.
        // We check if it's already configured.
        if FirebaseApp.app() != nil {
            print("FirebaseConfigManager: Firebase already configured.")
            self.isConfigured = true
            return true
        }
        
        let options = FirebaseOptions(googleAppID: googleAppId, gcmSenderID: gcmSenderId)
        options.apiKey = apiKey
        options.projectID = projectId
        
        FirebaseApp.configure(options: options)
        print("FirebaseConfigManager: Firebase configured successfully.")
        self.isConfigured = true
        return true
    }
    
    func getStoredCredentials() -> (apiKey: String, projectId: String, googleAppId: String, gcmSenderId: String) {
        let defaults = UserDefaults.standard
        return (
            defaults.string(forKey: kApiKey) ?? "",
            defaults.string(forKey: kProjectId) ?? "",
            defaults.string(forKey: kGoogleAppId) ?? "",
            defaults.string(forKey: kGcmSenderId) ?? ""
        )
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
    @FocusState private var isYearFieldFocused: Bool
    @State private var tempYearInput: String = ""

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
                // Centered, editable year input with box and buttons
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Year:")
                                .font(.headline)
                            TextField("Year", text: $yearInput)
                                .keyboardType(.numberPad)
                                .frame(width: 70)
                                .multilineTextAlignment(.center)
                                .focused($isYearFieldFocused)
                                .onTapGesture {
                                    tempYearInput = yearInput
                                }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                        if isYearFieldFocused {
                            HStack(spacing: 16) {
                                Button("Done") {
                                    if let year = Int(yearInput), year > 0 {
                                        selectedYear = year
                                    }
                                    isYearFieldFocused = false
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Cancel") {
                                    yearInput = tempYearInput
                                    isYearFieldFocused = false
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 4)
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
    
    init() {
        // Attempt to configure Firebase with stored credentials on launch
        _ = FirebaseConfigManager.shared.attemptAutoConfigure()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(dataManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.themeMode.colorScheme)
        }
    }
}