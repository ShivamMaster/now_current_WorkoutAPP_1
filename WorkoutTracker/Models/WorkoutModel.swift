import Foundation
import CoreData

// MARK: - Workout Entity
/// Core Data model representing a single workout session.
/// A workout contains multiple exercises and optionally belongs to a specific split.
class WorkoutModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var name: String
    @NSManaged public var notes: String?
    @NSManaged public var duration: Int16
    @NSManaged public var dayName: String?
    @NSManaged public var exercises: NSSet?
    @NSManaged public var split: WorkoutSplitModel?

    // MARK: - Computed Properties
    /// Returns the associated exercises as an array, sorted by their defined order.
    var exerciseArray: [ExerciseModel] {
        let set = exercises as? Set<ExerciseModel> ?? []
        return set.sorted {
            $0.order < $1.order
        }
    }

    // MARK: - Factory Methods
    /// Creates and returns a new workout instance in the provided context.
    static func createWorkout(context: NSManagedObjectContext, name: String, date: Date, duration: Int16, notes: String? = nil, dayName: String? = nil, split: WorkoutSplitModel? = nil) -> WorkoutModel {
        let workout = WorkoutModel(context: context)
        workout.id = UUID()
        workout.name = name
        workout.date = date
        workout.duration = duration
        workout.notes = notes
        workout.dayName = dayName
        workout.split = split
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