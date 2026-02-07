import SwiftUI

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    @AppStorage("firebaseID") private var firebaseID: String = "" // Added Firebase ID storage
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Firebase Config States
    @State private var apiKey = ""
    @State private var projectId = ""
    @State private var googleAppId = ""
    @State private var gcmSenderId = ""
    @State private var isConfigExpanded = false // To toggle visibility of config details
    
    @State private var showingAlert = false
    @State private var showingConfirmation = false
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
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Confirm Restore"),
                    message: Text("This will OVERWRITE all current data on this device with data from the cloud. Are you sure?"),
                    primaryButton: .destructive(Text("Restore"), action: performRestore),
                    secondaryButton: .cancel()
                )
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
        
        // Auto-expand if keys are missing
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
            isConfigExpanded = false // Collapse on success
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to configure Firebase."
        }
        showingAlert = true
    }
    
    // Backup Data Function
    private func backupData() {
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
                    alertTitle = "Success"
                    alertMessage = "Data successfully backed up to the cloud."
                case .failure(let error):
                    alertTitle = "Backup Failed"
                    alertMessage = error.localizedDescription
                }
                showingAlert = true
            }
        }
    }
    
    // Restore Data Function
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
                            alertTitle = "Success"
                            alertMessage = "Data successfully restored from cloud."
                        } else {
                            alertTitle = "Error"
                            alertMessage = "Failed to import data."
                        }
                        showingAlert = true
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