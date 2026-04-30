import Foundation
import CoreData
import SwiftUI
import WidgetKit
import CryptoKit

// MARK: - Data Retention Policy
enum DataRetentionPolicy: String, CaseIterable, Identifiable {
    case week = "Last Week"
    case month = "Last Month"
    case year = "Last Year"
    case allTime = "All Time"
    
    var id: String { rawValue }
    
    var cutoffDate: Date? {
        let cal = Calendar.current
        switch self {
        case .week:   return cal.date(byAdding: .weekOfYear, value: -1, to: Date())
        case .month:  return cal.date(byAdding: .month, value: -1, to: Date())
        case .year:   return cal.date(byAdding: .year, value: -1, to: Date())
        case .allTime: return nil
        }
    }
}

// Structs for JSON Serialization
struct SerializedExercise: Codable {
    let name: String
    let type: String
    let sets: Int16
    let reps: Int16
    let weight: Double
    let duration: Int16
    let distance: Double
    let calories: Int16
    let holdTime: Int16
    let notes: String?
    let order: Int16
}

struct SerializedWorkout: Codable {
    let name: String
    let date: Date
    let duration: Int16
    let notes: String?
    let dayName: String?
    let exercises: [SerializedExercise]
}

struct SerializedSplit: Codable {
    let name: String
    let createdAt: Date
    let workouts: [SerializedWorkout]
}

class DataManager: ObservableObject {
    // Shared instance for easy access
    static let shared = DataManager()

    // Core Data stack
    let container: NSPersistentContainer

    @Published var workouts: [WorkoutModel] = []
    @Published var splits: [WorkoutSplitModel] = []
    
    // MARK: - Hash-Based Sync Status (Feature 6)
    @Published var hasUnsyncedChanges: Bool = false {
        didSet {
            UserDefaults.standard.set(hasUnsyncedChanges, forKey: "hasUnsyncedChanges")
        }
    }
    
    private var hashCheckWorkItem: DispatchWorkItem?
    
    /// The SHA-256 hash of the last successfully synced backup JSON
    private var lastSyncedHash: String? {
        get { UserDefaults.standard.string(forKey: "lastSyncedDataHash") }
        set { UserDefaults.standard.set(newValue, forKey: "lastSyncedDataHash") }
    }
    
    // Feature 8: Click back settings
    @Published var clickBackEnabled: Bool = UserDefaults.standard.bool(forKey: "clickBackEnabled") {
        didSet {
            UserDefaults.standard.set(clickBackEnabled, forKey: "clickBackEnabled")
            scheduleHashCheck()
        }
    }
    @Published var clickBackDepth: Int = UserDefaults.standard.integer(forKey: "clickBackDepth") == 0 ? 1 : UserDefaults.standard.integer(forKey: "clickBackDepth") {
        didSet {
            UserDefaults.standard.set(clickBackDepth, forKey: "clickBackDepth")
            scheduleHashCheck()
        }
    }
    
    // Navigation triggers for popping to root
    @Published var popToRootWorkout: Int = 0
    @Published var popToRootProgress: Int = 0
    @Published var popToRootCalendar: Int = 0
    @Published var popToRootSettings: Int = 0

    init() {
        container = NSPersistentContainer(name: "WorkoutTracker")

        guard let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.HiraGoel.WorkoutTracker") else {
            fatalError("Failed to get App Group container URL.")
        }

        let storeURL = groupContainerURL.appendingPathComponent("WorkoutTracker.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        // Enable lightweight migration for new entities
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error.localizedDescription)")
                if let detailedError = error as NSError? {
                    print("Detailed error: \(detailedError.userInfo)")
                }
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            } else {
                print("Core Data model loaded successfully from App Group: \(storeURL.path)")
                let entityNames = self.container.managedObjectModel.entities.map { $0.name ?? "Unknown" }
                print("Loaded entities: \(entityNames.joined(separator: ", "))")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        fetchWorkouts()
        fetchSplits()
        
        // Restore persisted sync status
        hasUnsyncedChanges = UserDefaults.standard.bool(forKey: "hasUnsyncedChanges")
    }

    // MARK: - CRUD Operations

    func fetchWorkouts() {
        let request: NSFetchRequest<WorkoutModel> = NSFetchRequest<WorkoutModel>(entityName: "Workout")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutModel.date, ascending: false)]
        do {
            workouts = try container.viewContext.fetch(request)
            print("Fetched \(workouts.count) workouts")
        } catch {
            print("Error fetching workouts: \(error.localizedDescription)")
        }
    }
    
    func fetchSplits() {
        let request: NSFetchRequest<WorkoutSplitModel> = NSFetchRequest<WorkoutSplitModel>(entityName: "WorkoutSplit")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSplitModel.createdAt, ascending: true)]
        do {
            splits = try container.viewContext.fetch(request)
            print("Fetched \(splits.count) splits")
        } catch {
            print("Error fetching splits: \(error.localizedDescription)")
        }
    }

    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
                fetchWorkouts()
                fetchSplits()
                WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutCalendarWidget")
                print("Context saved and widget timeline reloaded.")
                // Feature 6: Schedule hash check after save
                scheduleHashCheck()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        } else {
            print("No changes to save in the context.")
        }
    }

    // MARK: - Split CRUD
    
    func addSplit(name: String) {
        let _ = WorkoutSplitModel.createSplit(context: container.viewContext, name: name)
        save()
    }
    
    func deleteSplit(_ split: WorkoutSplitModel) {
        container.viewContext.delete(split)
        save()
    }
    
    func renameSplit(_ split: WorkoutSplitModel, newName: String) {
        split.name = newName
        save()
    }

    // MARK: - Workout CRUD (now aware of splits)

    func addWorkout(name: String, date: Date, duration: Int16, notes: String? = nil, dayName: String? = nil, split: WorkoutSplitModel? = nil) {
        let newWorkout = WorkoutModel.createWorkout(
            context: container.viewContext,
            name: name,
            date: date,
            duration: duration,
            notes: notes,
            dayName: dayName,
            split: split
        )
        _ = newWorkout
        save()
    }

    func addExercise(
        to workout: WorkoutModel,
        name: String,
        exerciseType: ExerciseType,
        sets: Int16 = 0,
        reps: Int16 = 0,
        weight: Double = 0.0,
        duration: Int16 = 0,
        distance: Double = 0.0,
        calories: Int16 = 0,
        holdTime: Int16 = 0,
        notes: String? = nil
    ) {
        let order = Int16(workout.exerciseArray.count)
        let _ = ExerciseModel.createExercise(
            context: container.viewContext,
            name: name,
            exerciseType: exerciseType,
            sets: sets,
            reps: reps,
            weight: weight,
            duration: duration,
            distance: distance,
            calories: calories,
            holdTime: holdTime,
            order: order,
            notes: notes,
            workout: workout
        )
        save()
    }

    func updateExercise(
        exercise: ExerciseModel,
        name: String? = nil,
        exerciseType: ExerciseType? = nil,
        sets: Int16? = nil,
        reps: Int16? = nil,
        weight: Double? = nil,
        duration: Int16? = nil,
        distance: Double? = nil,
        calories: Int16? = nil,
        holdTime: Int16? = nil,
        notes: String? = nil
    ) {
        let context = exercise.managedObjectContext ?? container.viewContext
        context.performAndWait {
            if let name = name { exercise.name = name }
            if let exerciseType = exerciseType { exercise.exerciseType = exerciseType.rawValue }
            if let sets = sets { exercise.sets = sets }
            if let reps = reps { exercise.reps = reps }
            if let weight = weight { exercise.weight = weight }
            if let duration = duration { exercise.duration = duration }
            if let distance = distance { exercise.distance = distance }
            if let calories = calories { exercise.calories = calories }
            if let holdTime = holdTime { exercise.holdTime = holdTime }
            if notes != nil { exercise.notes = notes }
        }
        save()
    }

    func updateWorkout(
        workout: WorkoutModel,
        name: String? = nil,
        date: Date? = nil,
        duration: Int16? = nil,
        notes: String? = nil,
        dayName: String? = nil
    ) {
        let context = workout.managedObjectContext ?? container.viewContext
        context.performAndWait {
            if let name = name { workout.name = name }
            if let date = date { workout.date = date }
            if let duration = duration { workout.duration = duration }
            if notes != nil { workout.notes = notes }
            if dayName != nil { workout.dayName = dayName }
        }
        save()
    }

    func deleteWorkout(_ workout: WorkoutModel) {
        container.viewContext.delete(workout)
        save()
    }

    func deleteExercise(_ exercise: ExerciseModel) {
        container.viewContext.delete(exercise)
        save()
    }
    
    // Duplicate an exercise within the same workout
    func duplicateExercise(_ exercise: ExerciseModel, in workout: WorkoutModel) {
        let newExercise = ExerciseModel(context: container.viewContext)
        newExercise.id = UUID()
        newExercise.name = exercise.name
        newExercise.exerciseType = exercise.exerciseType
        newExercise.sets = exercise.sets
        newExercise.reps = exercise.reps
        newExercise.weight = exercise.weight
        newExercise.duration = exercise.duration
        newExercise.distance = exercise.distance
        newExercise.calories = exercise.calories
        newExercise.holdTime = exercise.holdTime
        newExercise.notes = exercise.notes
        newExercise.order = Int16(workout.exerciseArray.count)
        newExercise.workout = workout
        save()
    }
    
    // Duplicate a workout
    func duplicateWorkout(_ workout: WorkoutModel) {
        let newWorkout = WorkoutModel(context: container.viewContext)
        newWorkout.id = UUID()
        newWorkout.name = workout.name + " (Copy)"
        newWorkout.date = Date()
        newWorkout.duration = workout.duration
        newWorkout.notes = workout.notes
        newWorkout.dayName = workout.dayName
        newWorkout.split = workout.split
        for exercise in workout.exerciseArray {
            let newEx = ExerciseModel(context: container.viewContext)
            newEx.id = UUID()
            newEx.name = exercise.name
            newEx.exerciseType = exercise.exerciseType
            newEx.sets = exercise.sets
            newEx.reps = exercise.reps
            newEx.weight = exercise.weight
            newEx.duration = exercise.duration
            newEx.distance = exercise.distance
            newEx.calories = exercise.calories
            newEx.holdTime = exercise.holdTime
            newEx.notes = exercise.notes
            newEx.order = exercise.order
            newEx.workout = newWorkout
        }
        save()
    }

    // Get workout data for a specific exercise for charts
    func getProgressData(for exerciseName: String, timeFrame: Int = 90) -> [(date: Date, weight: Double, reps: Int16, sets: Int16)] {
        let fromDate = Calendar.current.date(byAdding: .day, value: -timeFrame, to: Date()) ?? Date()
        let request: NSFetchRequest<WorkoutModel> = NSFetchRequest<WorkoutModel>(entityName: "Workout")
        request.predicate = NSPredicate(format: "date >= %@", fromDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutModel.date, ascending: true)]
        var progressData: [(date: Date, weight: Double, reps: Int16, sets: Int16)] = []
        do {
            let workouts = try container.viewContext.fetch(request)
            for workout in workouts {
                for exercise in workout.exerciseArray where exercise.name == exerciseName {
                    progressData.append((date: workout.date, weight: exercise.weight, reps: exercise.reps, sets: exercise.sets))
                }
            }
        } catch {
            print("Error fetching progress data: \(error.localizedDescription)")
        }
        return progressData
    }
    
    func getAdvancedProgressData(for exerciseName: String, timeFrame: Int = 90) -> [(date: Date, exercise: ExerciseModel)] {
        let fromDate = Calendar.current.date(byAdding: .day, value: -timeFrame, to: Date()) ?? Date()
        let request: NSFetchRequest<WorkoutModel> = NSFetchRequest<WorkoutModel>(entityName: "Workout")
        request.predicate = NSPredicate(format: "date >= %@", fromDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutModel.date, ascending: true)]
        var data: [(date: Date, exercise: ExerciseModel)] = []
        do {
            let fetched = try container.viewContext.fetch(request)
            for workout in fetched {
                for exercise in workout.exerciseArray where exercise.name == exerciseName {
                    data.append((date: workout.date, exercise: exercise))
                }
            }
        } catch {
            print("Error fetching advanced progress data: \(error.localizedDescription)")
        }
        return data
    }

    // MARK: - Feature 6: Hash-Based Sync Status
    
    /// Computes SHA-256 of current exportable data. Returns nil if export fails.
    func computeCurrentHash() -> String? {
        guard let json = exportDataJSON() else { return nil }
        let inputData = Data(json.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Schedule a debounced hash check (0.5s) to update sync status
    func scheduleHashCheck() {
        hashCheckWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.updateSyncStatus()
        }
        hashCheckWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    /// Compare current hash with synced hash and update hasUnsyncedChanges
    func updateSyncStatus() {
        guard let storedHash = lastSyncedHash else {
            // No backup ever made — mark unsynced only if there's data
            hasUnsyncedChanges = !workouts.isEmpty || !splits.isEmpty
            return
        }
        guard let currentHash = computeCurrentHash() else { return }
        DispatchQueue.main.async {
            self.hasUnsyncedChanges = currentHash != storedHash
        }
    }
    
    /// Mark data as synced by saving the current hash
    func markAsSynced() {
        if let hash = computeCurrentHash() {
            lastSyncedHash = hash
        }
        hasUnsyncedChanges = false
    }
    
    // MARK: - Feature 5: Data Retention Policy
    
    var dataRetentionPolicy: DataRetentionPolicy {
        get {
            let raw = UserDefaults.standard.string(forKey: "dataRetentionPolicy") ?? DataRetentionPolicy.allTime.rawValue
            return DataRetentionPolicy(rawValue: raw) ?? .allTime
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "dataRetentionPolicy")
            scheduleHashCheck()
        }
    }
    
    /// Delete workouts older than the current retention window locally.
    /// Should only be called AFTER a successful cloud backup.
    func applyRetentionPolicy() {
        guard let cutoff = dataRetentionPolicy.cutoffDate else { return } // allTime: nothing to delete
        let toDelete = workouts.filter { $0.date < cutoff }
        for workout in toDelete {
            container.viewContext.delete(workout)
        }
        if !toDelete.isEmpty {
            do {
                try container.viewContext.save()
                fetchWorkouts()
                fetchSplits()
                print("Retention policy applied: deleted \(toDelete.count) old workouts locally.")
            } catch {
                print("Error applying retention policy: \(error)")
            }
        }
    }
}