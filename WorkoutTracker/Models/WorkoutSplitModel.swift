import Foundation
import CoreData

// MARK: - WorkoutSplit Core Data Model
class WorkoutSplitModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var createdAt: Date
    @NSManaged public var workouts: NSSet?

    /// Returns workouts sorted by date ascending
    var workoutArray: [WorkoutModel] {
        let set = workouts as? Set<WorkoutModel> ?? []
        return set.sorted { $0.date < $1.date }
    }

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
