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
        guard let apiKey = KeychainHelper.standard.read(service: "firebase", account: kApiKey), !apiKey.isEmpty,
              let projectId = KeychainHelper.standard.read(service: "firebase", account: kProjectId), !projectId.isEmpty,
              let googleAppId = KeychainHelper.standard.read(service: "firebase", account: kGoogleAppId), !googleAppId.isEmpty,
              let gcmSenderId = KeychainHelper.standard.read(service: "firebase", account: kGcmSenderId), !gcmSenderId.isEmpty else {
            print("FirebaseConfigManager: Missing credentials in Keychain.")
            return false
        }
        
        return configure(apiKey: apiKey, projectId: projectId, googleAppId: googleAppId, gcmSenderId: gcmSenderId, saveToKeychain: false)
    }
    
    // Configure with specific credentials
    func configure(apiKey: String, projectId: String, googleAppId: String, gcmSenderId: String, saveToKeychain: Bool = false) -> Bool {
        if saveToKeychain {
            saveCredentials(apiKey: apiKey, projectId: projectId, googleAppId: googleAppId, gcmSenderId: gcmSenderId)
        }
        
        // If already configured, we might need to recreate the app or just return true
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
    
    func saveCredentials(apiKey: String, projectId: String, googleAppId: String, gcmSenderId: String) {
        KeychainHelper.standard.save(apiKey, service: "firebase", account: kApiKey)
        KeychainHelper.standard.save(projectId, service: "firebase", account: kProjectId)
        KeychainHelper.standard.save(googleAppId, service: "firebase", account: kGoogleAppId)
        KeychainHelper.standard.save(gcmSenderId, service: "firebase", account: kGcmSenderId)
    }
    
    func getStoredCredentials() -> (apiKey: String, projectId: String, googleAppId: String, gcmSenderId: String) {
        return (
            KeychainHelper.standard.read(service: "firebase", account: kApiKey) ?? "",
            KeychainHelper.standard.read(service: "firebase", account: kProjectId) ?? "",
            KeychainHelper.standard.read(service: "firebase", account: kGoogleAppId) ?? "",
            KeychainHelper.standard.read(service: "firebase", account: kGcmSenderId) ?? ""
        )
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    private let server = "firebase.google.com"

    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kCFBooleanTrue
        ] as CFDictionary

        let status = SecItemAdd(query, nil)

        if status == errSecDuplicateItem {
            let queryToUpdate = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrServer: server,
                kSecAttrAccount: account,
                kSecAttrSynchronizable: kCFBooleanTrue
            ] as CFDictionary

            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            SecItemUpdate(queryToUpdate, attributesToUpdate)
        }
    }

    func save(_ string: String, service: String, account: String) {
        if let data = string.data(using: .utf8) {
            save(data, service: service, account: account)
        }
    }

    func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kCFBooleanTrue,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            let fallbackQuery = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrServer: server,
                kSecAttrAccount: account,
                kSecReturnData: true
            ] as CFDictionary
            var fallbackResult: AnyObject?
            if SecItemCopyMatching(fallbackQuery, &fallbackResult) == errSecSuccess {
                return fallbackResult as? Data
            }
        }
        return nil
    }

    func read(service: String, account: String) -> String? {
        if let data = read(service: service, account: account) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
