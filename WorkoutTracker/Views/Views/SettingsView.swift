import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    @AppStorage("firebaseID") private var firebaseID: String = ""
    @ObservedObject private var themeManager = ThemeManager.shared
    @EnvironmentObject private var dataManager: DataManager

    // Firebase Config
    @State private var apiKey = ""
    @State private var projectId = ""
    @State private var googleAppId = ""
    @State private var gcmSenderId = ""
    @State private var isConfigExpanded = false

    // Alerts & Animation
    @State private var showingAlert = false
    @State private var showingBackupConfirmation = false
    @State private var showingConfirmation = false
    @State private var showSuccessAnimation = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingKeychainPrompt = false
    @State private var navigationId = UUID()

    // Keyboard focus state for Done button
    @FocusState private var isFocused: Bool

    // Feature 5: Retention
    @State private var selectedRetention: DataRetentionPolicy = DataManager.shared.dataRetentionPolicy
    @State private var showingRetentionConfirm = false

    let weightUnits = ["kg", "lbs"]

    var body: some View {
        NavigationView {
            List {
                cloudBackupSection
                localStorageSection
                preferencesSection
                calendarColorSection
                aboutSection
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .onAppear { loadCredentials() }
            .background(alertsView)
            .overlay {
                successOverlay
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
        }
        .id(navigationId)
        .onReceive(dataManager.$popToRootSettings) { _ in
            navigationId = UUID()
        }
    }

    @ViewBuilder
    private var alertsView: some View {
        Color.clear
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Save to Keychain?", isPresented: $showingKeychainPrompt) {
                Button("Save", role: .none) {
                    FirebaseConfigManager.shared.saveCredentials(apiKey: apiKey, projectId: projectId, googleAppId: googleAppId, gcmSenderId: gcmSenderId)
                    showSuccessAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSuccessAnimation = false
                    }
                }
                Button("No Thanks", role: .cancel) { }
            } message: {
                Text("Would you like to securely save these credentials to your device Keychain? They will be preserved even if you delete the app, allowing automatic sign-in later.")
            }
            .confirmationDialog("Confirm Backup", isPresented: $showingBackupConfirmation, titleVisibility: .visible) {
                Button("Backup") { performBackup() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will upload your workout data to the cloud, overwriting any previous backup for this User ID.")
            }
            .confirmationDialog("Confirm Restore", isPresented: $showingConfirmation, titleVisibility: .visible) {
                Button("Restore", role: .destructive) { performRestore() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will OVERWRITE all current data on this device with data from the cloud. Are you sure?")
            }
            .confirmationDialog("Apply Retention Policy?", isPresented: $showingRetentionConfirm, titleVisibility: .visible) {
                Button("Apply — \(selectedRetention.rawValue)", role: .destructive) {
                    dataManager.dataRetentionPolicy = selectedRetention
                    dataManager.applyRetentionPolicy()
                }
                Button("Cancel", role: .cancel) {
                    selectedRetention = dataManager.dataRetentionPolicy
                }
            } message: {
                Text("Local workouts older than \(selectedRetention.rawValue.lowercased()) will be deleted from this device. They remain safely in your cloud backup.")
            }
    }

    @ViewBuilder
    private var cloudBackupSection: some View {
        Section(header: Text("Cloud Backup Configuration")) {
            DisclosureGroup("Firebase Project Credentials", isExpanded: $isConfigExpanded) {
                VStack(alignment: .leading, spacing: 10) {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                    TextField("Project ID", text: $projectId)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                    TextField("Google App ID", text: $googleAppId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                    TextField("GCM Sender ID", text: $gcmSenderId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)

                    Button("Save & Connect") { saveAndConnect() }
                        .disabled(apiKey.isEmpty || projectId.isEmpty || googleAppId.isEmpty || gcmSenderId.isEmpty)
                        .padding(.top, 5)

                    if FirebaseConfigManager.shared.isConfigured {
                        Text("✓ Connected!")
                            .foregroundColor(.green).font(.caption)
                    }
                }
            }

            TextField("Enter User Unique ID", text: $firebaseID)
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)

            Button(action: { showingBackupConfirmation = true }) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Backup Data to Cloud")
                }
            }
            .disabled(firebaseID.isEmpty || !FirebaseConfigManager.shared.isConfigured)

            Button(action: { showingConfirmation = true }) {
                HStack {
                    Image(systemName: "icloud.and.arrow.down")
                    Text("Restore Data from Cloud")
                }
                .foregroundColor(.red)
            }
            .disabled(firebaseID.isEmpty || !FirebaseConfigManager.shared.isConfigured)
            
            Button(action: {
                FirebaseConfigManager.shared.saveCredentials(apiKey: apiKey, projectId: projectId, googleAppId: googleAppId, gcmSenderId: gcmSenderId)
                showSuccessAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showSuccessAnimation = false }
            }) {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Manually Save to Apple Passwords")
                }
            }
            .disabled(apiKey.isEmpty || projectId.isEmpty)
        }
    }

    @ViewBuilder
    private var localStorageSection: some View {
        Section(header: Text("Local Storage"), footer: Text("Workouts older than the selected window are deleted from this device after backup, but remain in the cloud.")) {
            Picker("Keep Local Data", selection: $selectedRetention) {
                ForEach(DataRetentionPolicy.allCases) { policy in
                    Text(policy.rawValue).tag(policy)
                }
            }
            .onChange(of: selectedRetention) { newValue in
                if newValue != .allTime {
                    showingRetentionConfirm = true
                } else {
                    dataManager.dataRetentionPolicy = newValue
                }
            }
        }
    }

    @ViewBuilder
    private var preferencesSection: some View {
        Section(header: Text("Preferences")) {
            Picker("Weight Unit", selection: $weightUnit) {
                ForEach(weightUnits, id: \.self) { Text($0) }
            }
            .onChange(of: weightUnit) { _ in dataManager.scheduleHashCheck() }

            Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                .onChange(of: themeManager.isDarkMode) { value in
                    themeManager.themeMode = value ? .dark : .light
                }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle("Click Back", isOn: $dataManager.clickBackEnabled)
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .help("Tapping the active tab icon will navigate back to the initial page.")
                    // For iOS, help is not visible easily, let's use a small description below
                }
                
                if dataManager.clickBackEnabled {
                    Picker("Back Depth", selection: $dataManager.clickBackDepth) {
                        Text("1 Click").tag(1)
                        Text("2 Clicks").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                Text("Tapping the active tab icon will instantly navigate you back to the main starting page of that tab.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var calendarColorSection: some View {
        Section(header: Text("Calendar Color")) {
            NavigationLink(destination: SplitColorsView()) {
                Text("Customize Split Colors")
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version"); Spacer()
                Text("1.0.0").foregroundColor(.secondary)
            }
            NavigationLink(destination: PrivacyPolicyView()) {
                Text("Privacy Policy")
            }
        }
    }

    @ViewBuilder
    private var successOverlay: some View {
        if showSuccessAnimation {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 20) {
                    AppLottieView(animationName: "success-animation")
                        .frame(width: 200, height: 200)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccessAnimation)
                    Text("Success!")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                }
            }
        }
    }

    private func loadCredentials() {
        let creds = FirebaseConfigManager.shared.getStoredCredentials()
        apiKey = creds.apiKey; projectId = creds.projectId
        googleAppId = creds.googleAppId; gcmSenderId = creds.gcmSenderId
        if apiKey.isEmpty || projectId.isEmpty { isConfigExpanded = true }
        selectedRetention = dataManager.dataRetentionPolicy
    }

    private func saveAndConnect() {
        let success = FirebaseConfigManager.shared.configure(
            apiKey: apiKey, projectId: projectId,
            googleAppId: googleAppId, gcmSenderId: gcmSenderId
        )
        if success {
            isConfigExpanded = false
            showingKeychainPrompt = true
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to configure Firebase."
            showingAlert = true
        }
    }

    private func performBackup() {
        guard let json = dataManager.exportDataJSON() else {
            alertTitle = "Error"; alertMessage = "Failed to prepare data for backup."
            showingAlert = true; return
        }
        let id = firebaseID.trimmingCharacters(in: .whitespacesAndNewlines)
        FirebaseManager.shared.uploadData(json: json, userId: id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    showSuccessAnimation = true
                    // Feature 6: save hash so sync indicator turns green
                    dataManager.markAsSynced()
                    // Feature 5: optionally apply retention policy after backup
                    if dataManager.dataRetentionPolicy != .allTime {
                        dataManager.applyRetentionPolicy()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSuccessAnimation = false
                    }
                case .failure(let error):
                    alertTitle = "Backup Failed"; alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }

    private func performRestore() {
        let id = firebaseID.trimmingCharacters(in: .whitespacesAndNewlines)
        FirebaseManager.shared.downloadData(userId: id) { result in
            switch result {
            case .success(let json):
                dataManager.importDataJSON(json: json) { success in
                    DispatchQueue.main.async {
                        if success {
                            showSuccessAnimation = true
                            // Feature 6: after restore, mark as synced
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                dataManager.markAsSynced()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showSuccessAnimation = false
                            }
                        } else {
                            alertTitle = "Error"; alertMessage = "Failed to import data."
                            showingAlert = true
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    alertTitle = "Restore Failed"; alertMessage = error.localizedDescription
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
                Text("This app does not collect any personal data. All workout information is stored locally on your device and is not transmitted to any external servers unless you choose to back up.")
                Text("Workout data is only used within the app to display your progress and workout history.")
                Text("The app does not use any analytics services, advertising frameworks, or other tracking mechanisms.")
                Text("If you have any questions about our privacy practices, please contact us.")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}