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
        // Create a description pointing to the correct file path
        let modelURL = Bundle.main.url(forResource: "WorkoutTracker", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        
        // Initialize the container with the model
        container = NSPersistentContainer(name: "WorkoutTracker", managedObjectModel: managedObjectModel)
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error.localizedDescription)")
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
    
    // Add a new exercise to a workout
    func addExercise(to workout: WorkoutModel, name: String, sets: Int16, reps: Int16, weight: Double, notes: String? = nil) {
        let order = Int16(workout.exerciseArray.count)
        let _ = ExerciseModel.createExercise(
            context: container.viewContext,
            name: name,
            sets: sets,
            reps: reps,
            weight: weight,
            order: order,
            notes: notes,
            workout: workout
        )
        save()
    }
    
    // Update an exercise
    func updateExercise(exercise: ExerciseModel, name: String? = nil, sets: Int16? = nil, reps: Int16? = nil, weight: Double? = nil, notes: String? = nil) {
        if let name = name {
            exercise.name = name
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
} 