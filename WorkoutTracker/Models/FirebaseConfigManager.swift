// MARK: - Firebase Configuration Manager
/// Responsible for dynamic initialization of the Firebase SDK using project-specific credentials.
/// It integrates with the Keychain to ensure credentials persist across app installations.

import Foundation
import FirebaseCore

class FirebaseConfigManager: ObservableObject {
    static let shared = FirebaseConfigManager()
    
    /// Tracks whether the Firebase SDK has been successfully initialized.
    @Published var isConfigured: Bool = false
    
    // MARK: - Keychain Keys
    private let kApiKey = "firebase_apiKey"
    private let kProjectId = "firebase_projectId"
    private let kGoogleAppId = "firebase_googleAppId"
    private let kGcmSenderId = "firebase_gcmSenderId"
    
    // MARK: - Configuration Methods
    /// Attempts to automatically configure Firebase using credentials stored in the Keychain.
    /// - Returns: `true` if initialization succeeded, otherwise `false`.
    func attemptAutoConfigure() -> Bool {
        guard let apiKey = KeychainHelper.standard.readString(service: "firebase", account: kApiKey), !apiKey.isEmpty,
              let projectId = KeychainHelper.standard.readString(service: "firebase", account: kProjectId), !projectId.isEmpty,
              let googleAppId = KeychainHelper.standard.readString(service: "firebase", account: kGoogleAppId), !googleAppId.isEmpty,
              let gcmSenderId = KeychainHelper.standard.readString(service: "firebase", account: kGcmSenderId), !gcmSenderId.isEmpty else {
            print("FirebaseConfigManager: Missing credentials in Keychain.")
            return false
        }
        
        return configure(apiKey: apiKey, projectId: projectId, googleAppId: googleAppId, gcmSenderId: gcmSenderId, saveToKeychain: false)
    }
    
    /// Configures the Firebase environment with provided credentials.
    /// - Parameters:
    ///   - apiKey: The Firebase API Key.
    ///   - projectId: The Firebase Project ID.
    ///   - googleAppId: The Google App ID.
    ///   - gcmSenderId: The GCM Sender ID.
    ///   - saveToKeychain: If `true`, the credentials will be persisted to the device Keychain.
    /// - Returns: `true` if configuration was successful.
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
            KeychainHelper.standard.readString(service: "firebase", account: kApiKey) ?? "",
            KeychainHelper.standard.readString(service: "firebase", account: kProjectId) ?? "",
            KeychainHelper.standard.readString(service: "firebase", account: kGoogleAppId) ?? "",
            KeychainHelper.standard.readString(service: "firebase", account: kGcmSenderId) ?? ""
        )
    }
}

// MARK: - Keychain Helper
/// A utility class for securely storing and retrieving data from the system Keychain.
/// It uses `kSecClassInternetPassword` to ensure credentials appear in the Apple Passwords manager.
class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    private let server = "firebase.google.com"

    func save(_ data: Data, service: String, account: String) {
        // We use kSecClassInternetPassword and kSecAttrServer to make it show up in Apple Passwords (iCloud Keychain)
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kCFBooleanTrue! as Any,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary

        let status = SecItemAdd(query, nil)

        if status == errSecDuplicateItem {
            let queryToUpdate = [
                kSecClass: kSecClassInternetPassword,
                kSecAttrServer: server,
                kSecAttrAccount: account,
                kSecAttrSynchronizable: kCFBooleanTrue! as Any
            ] as CFDictionary

            let attributesToUpdate = [
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
            ] as CFDictionary
            
            let updateStatus = SecItemUpdate(queryToUpdate, attributesToUpdate)
            if updateStatus != errSecSuccess {
                print("KeychainHelper: Update failed with status \(updateStatus)")
            }
        } else if status != errSecSuccess {
            print("KeychainHelper: Save failed with status \(status)")
        } else {
            print("KeychainHelper: Successfully saved to Keychain (\(account))")
        }
    }

    func save(_ string: String, service: String, account: String) {
        if let data = string.data(using: .utf8) {
            save(data, service: service, account: account)
        }
    }

    func readData(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kCFBooleanTrue! as Any,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            // Fallback to non-synchronizable if it was saved without it (for backward compatibility if needed)
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

    func readString(service: String, account: String) -> String? {
        if let data = readData(service: service, account: account) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
