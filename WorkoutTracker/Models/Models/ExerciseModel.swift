import Foundation
import CoreData

// Exercise type enum to categorize different exercises
enum ExerciseType: String, CaseIterable, Identifiable {
    case strengthTraining = "Strength Training"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case bodyweight = "Bodyweight"
    case functional = "Functional"
    
    var id: String { self.rawValue }
    
    // Return appropriate measurement fields for each type
    var measurementFields: [String] {
        switch self {
        case .strengthTraining:
            return ["Sets", "Reps", "Weight (kg)"]
        case .cardio:
            return ["Duration (min)", "Distance (km)", "Calories"]
        case .flexibility:
            return ["Duration (min)", "Sets", "Hold Time (sec)"]
        case .bodyweight:
            return ["Set^s", "Reps"]
        case .functional:
            return ["Sets", "Reps", "Weight (kg)"]
        }
    }
}

// Dictionary of common exercises categorized by type
struct ExerciseLibrary {
    static let exercises: [ExerciseType: [String]] = [
        .strengthTraining: [
            "Bench Press",
            "Squat",
            "Deadlift",
            "Shoulder Press",
            "Lat Pulldown",
            "Bicep Curl",
            "Tricep Extension",
            "Leg Press",
            "Leg Extension",
            "Leg Curl",
            "Chest Fly",
            "Chest Row",
            "T-Bar Row",
            "Cable Row",
            "Barbell Row"
        ],
        .cardio: [
            "Treadmill",
            "Elliptical",
            "Stair Climber",
            "Exercise Bike",
            "Rowing Machine",
            "Jump Rope",
            "Swimming",
            "Running",
            "Cycling"
        ],
        .flexibility: [
            "Hamstring Stretch",
            "Quad Stretch",
            "Shoulder Stretch",
            "Hip Flexor Stretch",
            "Calf Stretch",
            "Yoga",
            "Pilates"
        ],
        .bodyweight: [
            "Push-up",
            "Pull-up",
            "Dip",
            "Plank",
            "Sit-up",
            "Crunch",
            "Burpee",
            "Lunge",
            "Squat Jump",
            "Mountain Climber"
        ],
        .functional: [
            "Kettlebell Swing",
            "Battle Ropes",
            "Box Jump",
            "Medicine Ball Throw",
            "TRX Suspension Training",
            "Sled Push/Pull",
            "Farmer's Walk"
        ]
    ]
}

class ExerciseModel: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var sets: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var weight: Double
    @NSManaged public var order: Int16
    @NSManaged public var notes: String?
    @NSManaged public var workout: WorkoutModel?
    
    // Additional fields for different exercise types
    @NSManaged public var exerciseType: String
    @NSManaged public var duration: Int16
    @NSManaged public var distance: Double
    @NSManaged public var calories: Int16
    @NSManaged public var holdTime: Int16
    
    // Factory method to create an exercise
    static func createExercise(
        context: NSManagedObjectContext,
        name: String,
        exerciseType: ExerciseType,
        sets: Int16 = 0,
        reps: Int16 = 0,
        weight: Double = 0.0,
        duration: Int16 = 0,
        distance: Double = 0.0,
        calories: Int16 = 0,
        holdTime: Int16 = 0,
        order: Int16,
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
        exercise.distance = distance
        exercise.calories = calories
        exercise.holdTime = holdTime
        exercise.order = order
        exercise.notes = notes
        exercise.workout = workout
        return exercise
    }
    
    // Helper method to get the exercise type enum
    var exerciseTypeEnum: ExerciseType {
        return ExerciseType(rawValue: exerciseType) ?? .strengthTraining
    }
    
    // Get appropriate display string based on exercise type
    var primaryMetrics: String {
        switch exerciseTypeEnum {
        case .strengthTraining, .functional:
            return "\(sets) sets × \(reps) reps × \(String(format: "%.1f", weight)) kg"
        case .cardio:
            return "\(duration) min, \(String(format: "%.1f", distance)) km, \(calories) cal"
        case .flexibility:
            return "\(duration) min, \(sets) sets, \(holdTime) sec hold"
        case .bodyweight:
            return "\(sets) sets × \(reps) reps"
        }
    }
} 
