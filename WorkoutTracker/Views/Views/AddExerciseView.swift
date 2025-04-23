import SwiftUI

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
    
    private func saveExercise() {
        // Use the selected exercise name if available, otherwise use the custom name
        let exerciseName = selectedExercise.isEmpty ? name : selectedExercise
        
        // Convert string values to appropriate types with safe defaults
        let setsValue = Int16(sets) ?? 0
        let repsValue = Int16(reps) ?? 0
        let weightValue = Double(weight) ?? 0.0
        let durationValue = Int16(duration) ?? 0
        let distanceValue = Double(distance) ?? 0.0
        let caloriesValue = Int16(calories) ?? 0
        let holdTimeValue = Int16(holdTime) ?? 0
        
        let _ = ExerciseModel.createExercise(
            context: dataManager.container.viewContext,
            name: exerciseName,
            exerciseType: selectedExerciseType,
            sets: setsValue,
            reps: repsValue,
            weight: weightValue,
            duration: durationValue,
            distance: distanceValue,
            calories: caloriesValue,
            holdTime: holdTimeValue,
            order: Int16(workout.exerciseArray.count),
            notes: notes.isEmpty ? nil : notes,
            workout: workout
        )
        
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
                ForEach(ExerciseLibrary.exercises[exerciseType] ?? [], id: \.self) { exercise in
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