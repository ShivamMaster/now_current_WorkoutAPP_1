import Foundation
import CoreData

class ExerciseModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var sets: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var weight: Double
    @NSManaged public var order: Int16
    @NSManaged public var notes: String?
    @NSManaged public var workout: WorkoutModel?
    
    // Factory method to create an exercise
    static func createExercise(context: NSManagedObjectContext, name: String, sets: Int16, reps: Int16, weight: Double, order: Int16, notes: String? = nil, workout: WorkoutModel) -> ExerciseModel {
        let exercise = ExerciseModel(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.sets = sets
        exercise.reps = reps
        exercise.weight = weight
        exercise.order = order
        exercise.notes = notes
        exercise.workout = workout
        return exercise
    }
} 