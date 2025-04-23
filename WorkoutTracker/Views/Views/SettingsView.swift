import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    
    let weightUnits = ["kg", "lbs"]
    
    var body: some View {
        NavigationView {
            List {
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
                    Button("Rate the App") {
                        // Link to App Store review
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
        }
    }
    
    struct PrivacyPolicyView: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 10)
                    
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
}
