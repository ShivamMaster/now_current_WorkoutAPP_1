import Foundation
import CoreData
import SwiftUI

class DataManager: ObservableObject {
    // Shared instance for easy access
    static let shared = DataManager()
    
    // Core Data stack
    let container: NSPersistentContainer
    
    @Published var workouts: [WorkoutModel] = []
    
    init() {
        // Use the simple initialization to avoid URL issues
        container = NSPersistentContainer(name: "WorkoutTracker")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error.localizedDescription)")
                // Print more detailed error info for debugging
                if let detailedError = error as NSError? {
                    print("Detailed error: \(detailedError.userInfo)")
                }
            } else {
                print("Core Data model loaded successfully")
            }
        }
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
            fetchWorkouts() // Refresh data
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
        save()
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
        save()
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
        save()
    }
    
    // Delete a workout
    func deleteWorkout(_ workout: WorkoutModel) {
        container.viewContext.delete(workout)
        save()
    }
    
    // Delete an exercise
    func deleteExercise(_ exercise: ExerciseModel) {
        container.viewContext.delete(exercise)
        save()
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
}