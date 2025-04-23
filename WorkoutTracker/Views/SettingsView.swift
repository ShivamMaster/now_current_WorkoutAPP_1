import SwiftUI

// View that displays the app settings
struct SettingsView: View {
    @State private var weightUnit = "kg"
    @State private var notificationsEnabled = true
    @State private var reminderTime = Date()
    @State private var darkModeOn = false
    
    let weightUnits = ["kg", "lbs"]
    
    var body: some View {
            NavigationView {
                Form {
                    Section {
                        Picker("Weight Unit", selection: $weightUnit) {
                            ForEach(weightUnits, id: \.self) {
                                Text($0)
                            }
                        }
                        
                        Toggle("Dark Mode", isOn: $darkModeOn)
                        
                        
                    }header: {
                        Text("Preferences")
                    }
                    
                    Section{
                        Button("Clear All Workout Data") {
                            //add clear data function
                        }
                    }
                    
                    
                    Section{
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
                    }header: {
                        Text("About")
                    }
                    
                    
                    
                    
                }
                .navigationTitle("Settings")
            
            
            }.padding(.bottom, 10)
        
    }
}








// View that provides privacy information
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