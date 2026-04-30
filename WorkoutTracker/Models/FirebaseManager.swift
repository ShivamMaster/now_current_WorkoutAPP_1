// MARK: - Firebase Data Manager
/// Handles the high-level synchronization of workout data with Google Cloud Firestore.
/// This manager performs the actual upload and download of serialized JSON backups.

import Foundation
import FirebaseFirestore
import FirebaseCore
import UIKit

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // MARK: - Data Synchronization
    /// Uploads a unified JSON backup to Firestore for a specific user ID.
    /// - Parameters:
    ///   - json: The serialized `BackupData` string.
    ///   - userId: The unique identifier for the user's cloud storage slot.
    ///   - completion: Executed upon completion with the result of the network operation.
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
            "workoutData": json, // Now contains both workouts and settings
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
    
    /// Downloads the latest JSON backup for a specific user ID from Firestore.
    /// - Parameters:
    ///   - userId: The unique identifier for the user's cloud storage slot.
    ///   - completion: Executed upon completion, providing either the JSON backup string or an error.
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
