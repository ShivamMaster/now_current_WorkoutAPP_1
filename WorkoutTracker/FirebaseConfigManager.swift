import Foundation
import FirebaseCore

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
