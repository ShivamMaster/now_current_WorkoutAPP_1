import Foundation
import CoreData

class WorkoutModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var name: String
    @NSManaged public var notes: String?
    @NSManaged public var duration: Int16
    @NSManaged public var exercises: NSSet?
    
    // Computed property to get exercises as an array
    var exerciseArray: [ExerciseModel] {
        let set = exercises as? Set<ExerciseModel> ?? []
        return set.sorted {
            $0.order < $1.order
        }
    }
    
    // Factory method to create a workout
    static func createWorkout(context: NSManagedObjectContext, name: String, date: Date, duration: Int16, notes: String? = nil) -> WorkoutModel {
        let workout = WorkoutModel(context: context)
        workout.id = UUID()
        workout.name = name
        workout.date = date
        workout.duration = duration
        workout.notes = notes
        return workout
    }
}

// MARK: - Generated accessors for exercises
extension WorkoutModel {
    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: ExerciseModel)
    
    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: ExerciseModel)
    
    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)
    
    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)
} 