// MARK: - Data Manager Serialization
/// This file extends `DataManager` with functionality for exporting and importing workout data as JSON.
/// it also manages global user settings persistence and provides the models for cloud-synchronized backups.

import Foundation
import CoreData
import SwiftUI
import WidgetKit

// MARK: - User Settings Model
/// Represents the global application preferences that are synchronized alongside workout data.
struct UserSettings: Codable {
    var weightUnit: String
    var notificationsEnabled: Bool
    var reminderTime: Date
    var darkModeEnabled: Bool
    var calendarBoxColorHex: String?
    
    // MARK: Navigation Preferences
    var clickBackEnabled: Bool?
    var clickBackDepth: Int?
    
    // MARK: Retention Preferences
    var dataRetentionPolicy: String?
}

// MARK: - Backup Serialization Models
/// Intermediate representation of a training split for JSON serialization.
struct SerializedBackupSplit: Codable {
    let name: String
    let createdAt: Date
    let workouts: [SerializedWorkout]
}

/// The top-level container for all data exported or imported from the cloud.
struct BackupData: Codable {
    /// List of organized splits and their workouts.
    let splits: [SerializedBackupSplit]?
    /// List of workouts not associated with any specific split (legacy or individual sessions).
    let workouts: [SerializedWorkout]?
    /// The application settings to be restored.
    let settings: UserSettings
}

// MARK: - User Settings Manager
/// A singleton responsible for managing and persisting global application preferences locally.
class UserSettingsManager: ObservableObject {
    static let shared = UserSettingsManager()
    
    @Published var weightUnit: String = "kg" { didSet { saveUserSettings() } }
    @Published var notificationsEnabled: Bool = false { didSet { saveUserSettings() } }
    @Published var reminderTime: Date = Date() { didSet { saveUserSettings() } }
    @Published var darkModeEnabled: Bool = false { didSet { saveUserSettings() } }

    private init() {
        if let s = UserSettingsManager.loadUserSettings() {
            weightUnit = s.weightUnit; notificationsEnabled = s.notificationsEnabled
            reminderTime = s.reminderTime; darkModeEnabled = s.darkModeEnabled
        }
    }
    
    private static func settingsFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Settings.json")
    }
    
    /// Loads user settings from the local file system.
    static func loadUserSettings() -> UserSettings? {
        guard let data = try? Data(contentsOf: settingsFileURL()) else { return nil }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(UserSettings.self, from: data)
    }
    
    /// Persists current user settings to a JSON file in the document directory.
    private func saveUserSettings() {
        let s = UserSettings(
            weightUnit: weightUnit, notificationsEnabled: notificationsEnabled,
            reminderTime: reminderTime, darkModeEnabled: darkModeEnabled,
            calendarBoxColorHex: ThemeManager.shared.calendarBoxColor.toHex()
        )
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(s) {
            try? data.write(to: UserSettingsManager.settingsFileURL())
        }
    }
    
    /// Applies a set of `UserSettings` to the current application state.
    /// This is typically called after a cloud restore operation.
    func applyUserSettings(_ settings: UserSettings) {
        DispatchQueue.main.async {
            UserDefaults.standard.set(settings.weightUnit, forKey: "weightUnit")
            self.weightUnit = settings.weightUnit
            self.notificationsEnabled = settings.notificationsEnabled
            self.reminderTime = settings.reminderTime
            ThemeManager.shared.isDarkMode = settings.darkModeEnabled
            if let hex = settings.calendarBoxColorHex, let c = Color(hex: hex) {
                ThemeManager.shared.calendarBoxColor = c
            }
            if let cb = settings.clickBackEnabled { DataManager.shared.clickBackEnabled = cb }
            if let cd = settings.clickBackDepth { DataManager.shared.clickBackDepth = cd }
            if let drp = settings.dataRetentionPolicy, let policy = DataRetentionPolicy(rawValue: drp) {
                DataManager.shared.dataRetentionPolicy = policy
            }
        }
    }
}

// MARK: - DataManager Export / Import
extension DataManager {

    // MARK: - Data Export
    /// Serializes all workouts, training splits, and user settings into a JSON string for cloud backup.
    /// - Returns: A pretty-printed JSON string if successful, otherwise `nil`.
    func exportDataJSON() -> String? {
        fetchWorkouts(); fetchSplits()

        // Serialize splits (with nested workouts)
        let serializedSplits: [SerializedBackupSplit] = splits.map { split in
            SerializedBackupSplit(
                name: split.name,
                createdAt: split.createdAt,
                workouts: split.workoutArray.map { serializeWorkout($0) }
            )
        }

        // Workouts not belonging to any split
        let unsplitWorkouts = workouts.filter { $0.split == nil }.map { serializeWorkout($0) }

        let weightUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"
        let settings = UserSettings(
            weightUnit: weightUnit,
            notificationsEnabled: UserSettingsManager.shared.notificationsEnabled,
            reminderTime: UserSettingsManager.shared.reminderTime,
            darkModeEnabled: ThemeManager.shared.isDarkMode,
            calendarBoxColorHex: ThemeManager.shared.calendarBoxColor.toHex(),
            clickBackEnabled: self.clickBackEnabled,
            clickBackDepth: self.clickBackDepth,
            dataRetentionPolicy: self.dataRetentionPolicy.rawValue
        )

        let backup = BackupData(
            splits: serializedSplits.isEmpty ? nil : serializedSplits,
            workouts: unsplitWorkouts.isEmpty ? nil : unsplitWorkouts,
            settings: settings
        )

        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.sortedKeys, .prettyPrinted] // Ensure deterministic output for hash verification
        guard let data = try? enc.encode(backup) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func serializeWorkout(_ workout: WorkoutModel) -> SerializedWorkout {
        SerializedWorkout(
            name: workout.name,
            date: workout.date,
            duration: workout.duration,
            notes: workout.notes,
            dayName: workout.dayName,
            exercises: workout.exerciseArray.map { ex in
                SerializedExercise(
                    name: ex.name,
                    type: ex.exerciseType ?? "Strength Training",
                    sets: ex.sets, reps: ex.reps, weight: ex.weight,
                    duration: ex.duration, distance: ex.distance,
                    calories: ex.calories, holdTime: ex.holdTime,
                    notes: ex.notes, order: ex.order
                )
            }
        )
    }

    // MARK: - Data Import
    /// Parses a JSON string and restores the application state, including workouts, splits, and settings.
    /// - Parameters:
    ///   - json: The JSON string to parse.
    ///   - completion: A block executed on the main thread with the result of the operation.
    func importDataJSON(json: String, completion: @escaping (Bool) -> Void) {
        guard let data = json.data(using: .utf8) else { completion(false); return }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601

        if let backup = try? dec.decode(BackupData.self, from: data) {
            UserSettingsManager.shared.applyUserSettings(backup.settings)
            restoreFromBackup(backup, completion: completion)
        } else if let legacy = try? dec.decode([SerializedWorkout].self, from: data) {
            restoreWorksouts(legacy, splitName: nil, completion: completion)
        } else {
            completion(false)
        }
    }

    private func restoreFromBackup(_ backup: BackupData, completion: @escaping (Bool) -> Void) {
        container.performBackgroundTask { context in
            // Delete all existing data
            for entity in ["Workout", "Exercise", "WorkoutSplit"] {
                let fr: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
                _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: fr))
            }

            // Restore splits
            for sSplit in backup.splits ?? [] {
                let split = WorkoutSplitModel(context: context)
                split.id = UUID(); split.name = sSplit.name; split.createdAt = sSplit.createdAt
                for sWorkout in sSplit.workouts {
                    let workout = self.createWorkout(from: sWorkout, in: context)
                    workout.split = split
                }
            }

            // Restore split-less workouts
            for sWorkout in backup.workouts ?? [] {
                let _ = self.createWorkout(from: sWorkout, in: context)
            }

            do {
                try context.save()
                DispatchQueue.main.async {
                    self.fetchWorkouts(); self.fetchSplits()
                    WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutCalendarWidget")
                    completion(true)
                }
            } catch {
                print("Import error: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    private func restoreWorksouts(_ workouts: [SerializedWorkout], splitName: String?, completion: @escaping (Bool) -> Void) {
        container.performBackgroundTask { context in
            let fr: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Workout")
            _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: fr))
            for sWorkout in workouts { let _ = self.createWorkout(from: sWorkout, in: context) }
            do {
                try context.save()
                DispatchQueue.main.async { self.fetchWorkouts(); completion(true) }
            } catch { DispatchQueue.main.async { completion(false) } }
        }
    }

    @discardableResult
    private func createWorkout(from s: SerializedWorkout, in context: NSManagedObjectContext) -> WorkoutModel {
        let workout = WorkoutModel(context: context)
        workout.id = UUID(); workout.name = s.name; workout.date = s.date
        workout.duration = s.duration; workout.notes = s.notes; workout.dayName = s.dayName
        for sEx in s.exercises {
            let ex = ExerciseModel(context: context)
            ex.id = UUID(); ex.name = sEx.name; ex.exerciseType = sEx.type
            ex.sets = sEx.sets; ex.reps = sEx.reps; ex.weight = sEx.weight
            ex.duration = sEx.duration; ex.distance = sEx.distance
            ex.calories = sEx.calories; ex.holdTime = sEx.holdTime
            ex.notes = sEx.notes; ex.order = sEx.order; ex.workout = workout
        }
        return workout
    }
}
