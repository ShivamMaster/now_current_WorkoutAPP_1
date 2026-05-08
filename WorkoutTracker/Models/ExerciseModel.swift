import Foundation
import CoreData
import SwiftUI

// MARK: - Exercise Type
/// Categorizes exercises to determine which metrics (reps, weight, distance, etc.) are relevant.
enum ExerciseType: String, CaseIterable, Identifiable, Codable {
    case strengthTraining = "Strength Training"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case bodyweight = "Bodyweight"
    case functional = "Functional"

    var id: String { self.rawValue }

    /// SF Symbol name associated with the exercise type.
    var icon: String {
        switch self {
        case .strengthTraining: return "dumbbell.fill"
        case .cardio: return "heart.circle.fill"
        case .flexibility: return "figure.yoga"
        case .bodyweight: return "figure.walk"
        case .functional: return "figure.cross.training"
        }
    }

    /// Primary color associated with the exercise type for UI differentiation.
    var color: Color {
        switch self {
        case .strengthTraining: return .blue
        case .cardio: return .red
        case .flexibility: return .purple
        case .bodyweight: return .green
        case .functional: return .orange
        }
    }

    /// List of field labels that should be displayed for this exercise type.
    var measurementFields: [String] {
        switch self {
        case .strengthTraining, .functional:
            return ["Sets", "Reps", "Weight (kg)"]
        case .cardio:
            return ["Duration (min)", "Distance (km)", "Calories"]
        case .flexibility:
            return ["Sets", "Duration (min)", "Hold Time (sec)"]
        case .bodyweight:
            return ["Sets", "Reps"]
        }
    }
}

// MARK: - Exercise Library
struct ExerciseLibrary {
    static let exercises: [ExerciseType: [String]] = [
        .strengthTraining: [
            "Bench Press", "Squat", "Deadlift", "Overhead Press",
            "Barbell Row", "Incline Bench Press", "Romanian Deadlift",
            "Leg Press", "Lateral Raise", "Bicep Curl", "Tricep Extension"
        ],
        .cardio: [
            "Running", "Cycling", "Swimming", "Rowing",
            "Jump Rope", "Stair Climber", "Elliptical"
        ],
        .flexibility: [
            "Hamstring Stretch", "Hip Flexor Stretch", "Shoulder Stretch",
            "Quad Stretch", "Calf Stretch", "Pigeon Pose", "Child's Pose"
        ],
        .bodyweight: [
            "Push-Ups", "Pull-Ups", "Dips", "Bodyweight Squats",
            "Lunges", "Plank", "Burpees", "Mountain Climbers"
        ],
        .functional: [
            "Kettlebell Swing", "Box Jump", "Battle Ropes", "TRX Row",
            "Medicine Ball Slam", "Farmers Walk", "Sled Push"
        ]
    ]
}

// MARK: - Exercise Entity
/// Core Data model representing an individual exercise within a workout.
class ExerciseModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var exerciseType: String?
    @NSManaged public var sets: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var weight: Double
    @NSManaged public var duration: Int16
    @NSManaged public var durationSeconds: Int16
    @NSManaged public var distance: Double
    @NSManaged public var calories: Int16
    @NSManaged public var holdTime: Int16
    @NSManaged public var order: Int16
    @NSManaged public var notes: String?
    @NSManaged public var workout: WorkoutModel?

    /// Helper to interact with the raw `exerciseType` string as a typed enum.
    var exerciseTypeEnum: ExerciseType {
        get { ExerciseType(rawValue: exerciseType ?? "") ?? .strengthTraining }
        set { exerciseType = newValue.rawValue }
    }

    /// Formatted string summarizing the primary performance metrics based on the exercise type.
    var primaryMetrics: String {
        switch exerciseTypeEnum {
        case .strengthTraining, .functional:
            return "\(sets) sets × \(reps) reps @ \(String(format: "%g", weight)) kg"
        case .cardio:
            var durationStr = "\(duration) min"
            if durationSeconds > 0 {
                durationStr += " \(durationSeconds) sec"
            }
            return "\(durationStr) · \(String(format: "%.1f", distance)) km · \(calories) kcal"
        case .flexibility:
            var durationStr = "\(duration) min"
            if durationSeconds > 0 {
                durationStr += " \(durationSeconds) sec"
            }
            return "\(sets) sets · \(durationStr) · \(holdTime)s hold"
        case .bodyweight:
            return "\(sets) sets × \(reps) reps"
        }
    }

    /// Factory method to create a new exercise instance in a given context.
    static func createExercise(
        context: NSManagedObjectContext,
        name: String,
        exerciseType: ExerciseType,
        sets: Int16 = 0,
        reps: Int16 = 0,
        weight: Double = 0.0,
        duration: Int16 = 0,
        durationSeconds: Int16 = 0,
        distance: Double = 0.0,
        calories: Int16 = 0,
        holdTime: Int16 = 0,
        order: Int16 = 0,
        notes: String? = nil,
        workout: WorkoutModel
    ) -> ExerciseModel {
        let exercise = ExerciseModel(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.exerciseType = exerciseType.rawValue
        exercise.sets = sets
        exercise.reps = reps
        exercise.weight = weight
        exercise.duration = duration
        exercise.durationSeconds = durationSeconds
        exercise.distance = distance
        exercise.calories = calories
        exercise.holdTime = holdTime
        exercise.order = order
        exercise.notes = notes
        exercise.workout = workout
        return exercise
    }
}