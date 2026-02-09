import Foundation
import CoreData
import SwiftUI
import WidgetKit // Import WidgetKit

class DataManager: ObservableObject {
    // Shared instance for easy access
    static let shared = DataManager()
    
    // Core Data stack
    let container: NSPersistentContainer
    
    @Published var workouts: [WorkoutModel] = []
    @Published var hasUnsyncedChanges: Bool = UserDefaults.standard.bool(forKey: "hasUnsyncedChanges") {
        didSet {
            UserDefaults.standard.set(hasUnsyncedChanges, forKey: "hasUnsyncedChanges")
        }
    }
    
    init() {
        // Use the simple initialization to avoid URL issues
        container = NSPersistentContainer(name: "WorkoutTracker")
        // --- Modification Start ---
        // Get the URL for the shared App Group container
        guard let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.HiraGoel.WorkoutTracker") else {
            fatalError("Failed to get App Group container URL.") // Use fatalError in the main app for critical setup
        }
        // Define the store URL within the App Group container
        let storeURL = groupContainerURL.appendingPathComponent("WorkoutTracker.sqlite") // Match your store file name
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        // --- Modification End ---
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error.localizedDescription)")
                // Print more detailed error info for debugging
                if let detailedError = error as NSError? {
                    print("Detailed error: \(detailedError.userInfo)")
                }
                // Consider more robust error handling for production
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            } else {
                print("Core Data model loaded successfully from App Group: \(storeURL.path)")
            }
        }
        // Ensure viewContext automatically merges changes from background contexts (like the one potentially used by the widget)
        container.viewContext.automaticallyMergesChangesFromParent = true
        fetchWorkouts()
    }
    
    // MARK: - CRUD Operations
    
    // Fetch all workouts
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
    
    // Save changes to Core Data
    func save() {
        do {
            try container.viewContext.save()
            hasUnsyncedChanges = true
            fetchWorkouts() // Refresh data
            saveWorkoutDatesToUserDefaults() // Call the function here
            WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutCalendarWidget") // Reload widget timeline
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    // Add a new workout
    func addWorkout(name: String, date: Date, duration: Int16, notes: String? = nil) {
        let newWorkout = WorkoutModel.createWorkout(
            context: container.viewContext,
            name: name,
            date: date,
            duration: duration,
            notes: notes
        )
        save() // This will now also call saveWorkoutDatesToUserDefaults
    }
    
    // Add a new exercise to a workout with enhanced type support
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
        save() // This will now also call saveWorkoutDatesToUserDefaults
    }
    
    // Update an exercise with enhanced type support
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
        if let name = name {
            exercise.name = name
        }
        if let exerciseType = exerciseType {
            exercise.exerciseType = exerciseType.rawValue
        }
        if let sets = sets {
            exercise.sets = sets
        }
        if let reps = reps {
            exercise.reps = reps
        }
        if let weight = weight {
            exercise.weight = weight
        }
        if let duration = duration {
            exercise.duration = duration
        }
        if let distance = distance {
            exercise.distance = distance
        }
        if let calories = calories {
            exercise.calories = calories
        }
        if let holdTime = holdTime {
            exercise.holdTime = holdTime
        }
        if let notes = notes {
            exercise.notes = notes
        }
        save() // This will now also call saveWorkoutDatesToUserDefaults
    }
    
    // Update a workout
    func updateWorkout(workout: WorkoutModel, name: String, date: Date, duration: Int16, notes: String?) {
         workout.name = name
         workout.date = date
         workout.duration = duration
         workout.notes = notes
         save() // This will now also call saveWorkoutDatesToUserDefaults
     }
    
    // Delete a workout
    func deleteWorkout(_ workout: WorkoutModel) {
        container.viewContext.delete(workout)
        save() // This will now also call saveWorkoutDatesToUserDefaults
    }
    
    // Delete an exercise
    func deleteExercise(_ exercise: ExerciseModel) {
        container.viewContext.delete(exercise)
        save() // This will now also call saveWorkoutDatesToUserDefaults
    }
    
    // Get workout data for a specific exercise for charts
    func getProgressData(for exerciseName: String, timeFrame: Int = 90) -> [(date: Date, weight: Double, reps: Int16, sets: Int16)] {
        let fromDate = Calendar.current.date(byAdding: .day, value: -timeFrame, to: Date()) ?? Date()
        
        // Create fetch request for workouts within timeframe
        let request: NSFetchRequest<WorkoutModel> = NSFetchRequest<WorkoutModel>(entityName: "Workout")
        request.predicate = NSPredicate(format: "date >= %@", fromDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutModel.date, ascending: true)]
        
        var progressData: [(date: Date, weight: Double, reps: Int16, sets: Int16)] = []
        
        do {
            let workouts = try container.viewContext.fetch(request)
            
            // Find exercises matching the name
            for workout in workouts {
                for exercise in workout.exerciseArray where exercise.name == exerciseName {
                    progressData.append((
                        date: workout.date,
                        weight: exercise.weight,
                        reps: exercise.reps,
                        sets: exercise.sets
                    ))
                }
            }
        } catch {
            print("Error fetching progress data: \(error.localizedDescription)")
        }
        
        return progressData
    }
    
    // Get advanced progress data including all measurement types
    func getAdvancedProgressData(
        for exerciseName: String,
        timeFrame: Int = 90
    ) -> [(date: Date, exercise: ExerciseModel)] {
        let fromDate = Calendar.current.date(byAdding: .day, value: -timeFrame, to: Date()) ?? Date()
        
        // Create fetch request for workouts within timeframe
        let request: NSFetchRequest<WorkoutModel> = NSFetchRequest<WorkoutModel>(entityName: "Workout")
        request.predicate = NSPredicate(format: "date >= %@", fromDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutModel.date, ascending: true)]
        
        var progressData: [(date: Date, exercise: ExerciseModel)] = []
        
        do {
            let workouts = try container.viewContext.fetch(request)
            
            // Find exercises matching the name
            for workout in workouts {
                for exercise in workout.exerciseArray where exercise.name == exerciseName {
                    progressData.append((
                        date: workout.date,
                        exercise: exercise
                    ))
                }
            }
        } catch {
            print("Error fetching progress data: \(error.localizedDescription)")
        }
        
        return progressData
    }
    
    func updateWorkout(
        workout: WorkoutModel,
        name: String? = nil,
        date: Date? = nil,
        duration: Int16? = nil,
        notes: String? = nil
    ) {
        if let name = name {
            workout.name = name
        }
        if let date = date {
            workout.date = date
        }
        if let duration = duration {
            workout.duration = duration
        }
        if let notes = notes {
            workout.notes = notes
        }
        save()
    }
    
    // Function to save all workout dates to UserDefaults for the widget
    private func saveWorkoutDatesToUserDefaults() {
        // Ensure workouts are fetched if not already loaded
        if workouts.isEmpty {
            fetchWorkouts()
        }
    
        let allWorkoutDates = workouts.map { $0.date }
        let formatter = ISO8601DateFormatter()
        let isoStrings = allWorkoutDates.map { formatter.string(from: $0) }
    
        if let userDefaults = UserDefaults(suiteName: "group.com.HiraGoel.WorkoutTracker") {
            userDefaults.set(isoStrings, forKey: "allWorkoutDatesForWidget")
            print("DataManager saved \(isoStrings.count) workout dates to UserDefaults.")
        } else {
            print("DataManager could not access UserDefaults suite.")
        }
    }
    
    // Duplicate a workout (deep copy including exercises)
    func duplicateWorkout(_ workout: WorkoutModel) {
        let context = container.viewContext
        let newWorkout = WorkoutModel.createWorkout(
            context: context,
            name: workout.name ?? "",
            date: Date(), // Use current date for the duplicate
            duration: workout.duration,
            notes: workout.notes
        )
        // Duplicate exercises
        for exercise in workout.exerciseArray {
            let _ = ExerciseModel.createExercise(
                context: context,
                name: exercise.name ?? "",
                exerciseType: ExerciseType(rawValue: exercise.exerciseType ?? "") ?? .strengthTraining, // <-- changed from .other
                sets: exercise.sets,
                reps: exercise.reps,
                weight: exercise.weight,
                duration: exercise.duration,
                distance: exercise.distance,
                calories: exercise.calories,
                holdTime: exercise.holdTime,
                order: exercise.order,
                notes: exercise.notes,
                workout: newWorkout
            )
        }
        save()
    }

    // Duplicate an exercise within the same workout
    func duplicateExercise(_ exercise: ExerciseModel, in workout: WorkoutModel) {
        let context = container.viewContext
        let _ = ExerciseModel.createExercise(
            context: context,
            name: exercise.name ?? "",
            exerciseType: ExerciseType(rawValue: exercise.exerciseType ?? "") ?? .strengthTraining, // <-- changed from .other
            sets: exercise.sets,
            reps: exercise.reps,
            weight: exercise.weight,
            duration: exercise.duration,
            distance: exercise.distance,
            calories: exercise.calories,
            holdTime: exercise.holdTime,
            order: Int16(workout.exerciseArray.count),
            notes: exercise.notes,
            workout: workout
        )
        save()
    }

    // Mark that data has been successfully backed up to the cloud
    func markAsSynced() {
        hasUnsyncedChanges = false
    }
}

extension DataManager {
    /// Returns all exercise names for a given type:
    /// - All default exercises
    /// - All unique exercise names in all workouts for that type
    func getAvailableExercises(for type: ExerciseType) -> [String] {
        // 1. Get default exercises for this type
        let defaultExercises = ExerciseLibrary.exercises[type] ?? []

        // 2. Get all unique exercise names for this type from all workouts
        var customExercises = Set<String>()
        for workout in workouts {
            for exercise in workout.exerciseArray {
                if exercise.exerciseTypeEnum == type {
                    customExercises.insert(exercise.name)
                }
            }
        }

        // 3. Combine and sort, removing duplicates
        let allExercises = Set(defaultExercises).union(customExercises)
        return Array(allExercises).sorted()
    }
}