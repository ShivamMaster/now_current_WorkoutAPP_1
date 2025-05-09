import SwiftUI

// Helper for user exercise library
// Moved this struct OUTSIDE of AddExerciseView
struct UserExerciseLibrary {
    static let keyPrefix = "userExercises_"

    static func getExercises(for type: ExerciseType, dataManager: DataManager = DataManager.shared) -> [String] {
        // Get default exercises for this type
        let defaultExercises = ExerciseLibrary.exercises[type] ?? []

        // Get all exercises from workouts for this type
        let workoutExercises = dataManager.workouts.flatMap { $0.exerciseArray }
            .filter { $0.exerciseTypeEnum == type }
            .map { $0.name }

        // Get custom exercises from UserDefaults
        let key = keyPrefix + type.rawValue
        let userExercises = UserDefaults.standard.stringArray(forKey: key) ?? []

        // Only keep custom exercises that are still present in workouts
        let validCustomExercises = userExercises.filter { workoutExercises.contains($0) }

        // Combine default and valid custom exercises, removing duplicates
        let allExercises = Array(Set(defaultExercises + validCustomExercises)).sorted()
        return allExercises
    }

    // Updated addExercise:
    // Adds an exercise to the user's custom library for a given type,
    // only if it's not part of the default library and not already in the user's list.
    static func addExercise(_ exerciseName: String, for type: ExerciseType) {
        let defaultExercises = ExerciseLibrary.exercises[type] ?? []
        if defaultExercises.contains(exerciseName) {
            return // Do not add if it's a default exercise
        }

        let key = keyPrefix + type.rawValue
        var userExercisesForType = getExercises(for: type)
        if !userExercisesForType.contains(exerciseName) {
            userExercisesForType.append(exerciseName)
            UserDefaults.standard.set(userExercisesForType, forKey: key)
        }
    }

    // New removeExercise function:
    // Removes an exercise from the user's custom library for a given type.
    static func removeExercise(_ exerciseName: String, for type: ExerciseType) {
        let key = keyPrefix + type.rawValue
        var userExercisesForType = getExercises(for: type)
        if let index = userExercisesForType.firstIndex(of: exerciseName) {
            userExercisesForType.remove(at: index)
            UserDefaults.standard.set(userExercisesForType, forKey: key)
        }
    }
}

struct AddExerciseView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("weightUnit") private var defaultWeightUnit: String = "kg"
    @State private var weightUnit: String
    
    let workout: WorkoutModel
    
    @State private var name = ""
    @State private var selectedExerciseType: ExerciseType
    @State private var selectedExercise = ""
    
    // Fields for all exercise types
    @State private var sets = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var duration = ""
    @State private var distance = ""
    @State private var calories = ""
    @State private var holdTime = ""
    @State private var notes = ""
    
    @State private var showingExerciseList = false
    
    // Add initializer to accept preselected type
    init(workout: WorkoutModel, preselectedType: ExerciseType? = nil) {
        self.workout = workout
        _selectedExerciseType = State(initialValue: preselectedType ?? .strengthTraining)
        _weightUnit = State(initialValue: UserDefaults.standard.string(forKey: "weightUnit") ?? "kg")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Type")) {
                    Picker("Type", selection: $selectedExerciseType) {
                        ForEach(ExerciseType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: selectedExerciseType) { _ in
                        // Clear the selected exercise when type changes
                        selectedExercise = ""
                    }
                }
                
                Section(header: Text("Exercise")) {
                    if selectedExercise.isEmpty {
                        TextField("Custom Exercise Name", text: $name)
                    } else {
                        HStack {
                            Text(selectedExercise)
                            Spacer()
                            Button("Change") {
                                showingExerciseList = true
                            }
                        }
                    }
                    
                    Button(selectedExercise.isEmpty ? "Select from library" : "Choose different exercise") {
                        showingExerciseList = true
                    }
                    .sheet(isPresented: $showingExerciseList) {
                        ExerciseListView(
                            exerciseType: selectedExerciseType,
                            selectedExercise: $selectedExercise,
                            isPresented: $showingExerciseList
                        )
                    }
                }
                
                // Dynamic section based on selected exercise type
                Section(header: Text("Exercise Details")) {
                    // Add unit picker before weight field
                    Picker("Unit", selection: $weightUnit) {
                        Text("kg").tag("kg")
                        Text("lbs").tag("lbs")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    ForEach(selectedExerciseType.measurementFields, id: \.self) { field in
                        switch field {
                        case "Sets":
                            HStack {
                                Text("Sets")
                                Spacer()
                                TextField("Sets", text: $sets)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        case "Reps":
                            HStack {
                                Text("Reps")
                                Spacer()
                                TextField("Reps", text: $reps)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        case "Weight (kg)":
                            HStack {
                                Text("Weight (\(weightUnit))")
                                Spacer()
                                TextField("Weight", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        case "Duration (min)":
                            HStack {
                                Text("Duration (min)")
                                Spacer()
                                TextField("Minutes", text: $duration)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        case "Distance (km)":
                            HStack {
                                Text("Distance (km)")
                                Spacer()
                                TextField("Kilometers", text: $distance)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        case "Calories":
                            HStack {
                                Text("Calories")
                                Spacer()
                                TextField("Calories", text: $calories)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        case "Hold Time (sec)":
                            HStack {
                                Text("Hold Time (sec)")
                                Spacer()
                                TextField("Seconds", text: $holdTime)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        default:
                            EmptyView()
                        }
                    }
                    
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(5)
                }
                
                Section {
                    Button("Save") {
                        saveExercise()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var isFormValid: Bool {
        // Exercise name is required
        let hasName = !selectedExercise.isEmpty || !name.isEmpty
        
        // Validate required fields based on exercise type
        switch selectedExerciseType {
        case .strengthTraining, .functional:
            return hasName && !sets.isEmpty && !reps.isEmpty && !weight.isEmpty
        case .cardio:
            return hasName && !duration.isEmpty
        case .flexibility:
            return hasName && !duration.isEmpty && !sets.isEmpty && !holdTime.isEmpty
        case .bodyweight:
            return hasName && !sets.isEmpty && !reps.isEmpty
        }
    }
    
    // Helper for user exercise library
    // Move this struct OUTSIDE of AddExerciseView
    // UserExerciseLibrary struct has been moved to the top of the file.

    private func saveExercise() {
        // Use the selected exercise name if available, otherwise use the custom name
        let exerciseName = selectedExercise.isEmpty ? name : selectedExercise
    
        // Updated logic for adding custom exercise:
        // If a custom name was typed, try to add it to the user library.
        // The UserExerciseLibrary.addExercise function now handles all necessary checks.
        if selectedExercise.isEmpty && !exerciseName.isEmpty {
            UserExerciseLibrary.addExercise(exerciseName, for: selectedExerciseType)
        }
    
        // Convert string values to appropriate types with safe defaults
        let setsValue = Int16(sets) ?? 0
        let repsValue = Int16(reps) ?? 0
        var weightValue = Double(weight) ?? 0.0 // Keep as var for potential conversion
        let durationValue = Int16(duration) ?? 0
        let distanceValue = Double(distance) ?? 0.0
        let caloriesValue = Int16(calories) ?? 0
        let holdTimeValue = Int16(holdTime) ?? 0
    
        // Convert weight to KG if the user entered it in LBS
        if weightUnit == "lbs" {
            // Convert lbs to kg - the user entered the weight in lbs, so we need to convert to kg for storage
            weightValue = weightValue / 2.20462 // Convert lbs to kg (more precise than multiplying by 0.453592)
        }
        // If weightUnit is already "kg", no conversion needed as the user entered in kg
    
        let _ = ExerciseModel.createExercise(
            context: dataManager.container.viewContext,
            name: exerciseName,
            exerciseType: selectedExerciseType,
            sets: setsValue,
            reps: repsValue,
            weight: weightValue, // Save the (potentially converted) kg value
            duration: durationValue,
            distance: distanceValue,
            calories: caloriesValue,
            holdTime: holdTimeValue,
            order: Int16(workout.exerciseArray.count),
            notes: notes.isEmpty ? nil : notes,
            workout: workout
        )
    
        // Save the user's preferred weight unit
        UserDefaults.standard.set(weightUnit, forKey: "weightUnit")
        
        dataManager.save()
        presentationMode.wrappedValue.dismiss()
    }
}

// View for selecting an exercise from the library
struct ExerciseListView: View {
    let exerciseType: ExerciseType
    @Binding var selectedExercise: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                // Merge default and user exercises, removing duplicates
                let defaultExercises = ExerciseLibrary.exercises[exerciseType] ?? []
                let userExercises = UserExerciseLibrary.getExercises(for: exerciseType)
                let allExercises = Array(Set(defaultExercises + userExercises)).sorted()
                
                ForEach(allExercises, id: \.self) { exercise in
                    Button {
                        selectedExercise = exercise
                        isPresented = false
                    } label: {
                        Text(exercise)
                    }
                }
            }
            .navigationTitle("Select \(exerciseType.rawValue)")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}
