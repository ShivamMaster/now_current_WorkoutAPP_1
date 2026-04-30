import Foundation
import CoreData

// MARK: - Workout Split Entity
/// Core Data model representing a workout "split" (e.g., "Push/Pull/Legs" or "Full Body").
/// A split serves as a container for organizing multiple workouts.
class WorkoutSplitModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var createdAt: Date
    @NSManaged public var workouts: NSSet?

    // MARK: - Computed Properties
    /// Returns the associated workouts as an array, sorted by date in ascending order.
    var workoutArray: [WorkoutModel] {
        let set = workouts as? Set<WorkoutModel> ?? []
        return set.sorted { $0.date < $1.date }
    }

    // MARK: - Factory Methods
    /// Creates and returns a new workout split instance in the provided context.
    static func createSplit(context: NSManagedObjectContext, name: String) -> WorkoutSplitModel {
        let split = WorkoutSplitModel(context: context)
        split.id = UUID()
        split.name = name
        split.createdAt = Date()
        return split
    }
}

// MARK: - Generated accessors for workouts
extension WorkoutSplitModel {
    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: WorkoutModel)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: WorkoutModel)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSSet)
}
