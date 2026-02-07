import Foundation
import FirebaseFirestore
import FirebaseCore

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
