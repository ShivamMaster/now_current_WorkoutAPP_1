import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    let exercise: ExerciseModel
    
    @State private var name: String
    @State private var selectedExerciseType: ExerciseType
    
    // Fields for all exercise types
    @State private var sets: String
    @State private var reps: String
    @State private var weight: String
    @State private var duration: String
    @State private var distance: String
    @State private var calories: String
    @State private var holdTime: String
    @State private var notes: String
    
    @State private var isEditing = false
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        
        // Initialize state variables with exercise values
        _name = State(initialValue: exercise.name)
        _selectedExerciseType = State(initialValue: exercise.exerciseTypeEnum)
        _sets = State(initialValue: "\(exercise.sets)")
        _reps = State(initialValue: "\(exercise.reps)")
        _weight = State(initialValue: String(format: "%.1f", exercise.weight))
        _duration = State(initialValue: "\(exercise.duration)")
        _distance = State(initialValue: String(format: "%.1f", exercise.distance))
        _calories = State(initialValue: "\(exercise.calories)")
        _holdTime = State(initialValue: "\(exercise.holdTime)")
        _notes = State(initialValue: exercise.notes ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Exercise Details")) {
                if isEditing {
                    TextField("Name", text: $name)
                    
                    Picker("Type", selection: $selectedExerciseType) {
                        ForEach(ExerciseType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    // Dynamic fields based on exercise type
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
                                Text("Weight (kg)")
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
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5)
                } else {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(exercise.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(exercise.exerciseTypeEnum.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    // Display appropriate fields based on exercise type
                    ForEach(exercise.exerciseTypeEnum.measurementFields, id: \.self) { field in
                        switch field {
                        case "Sets":
                            HStack {
                                Text("Sets")
                                Spacer()
                                Text("\(exercise.sets)")
                                    .foregroundColor(.secondary)
                            }
                        case "Reps":
                            HStack {
                                Text("Reps")
                                Spacer()
                                Text("\(exercise.reps)")
                                    .foregroundColor(.secondary)
                            }
                        case "Weight (kg)":
                            HStack {
                                Text("Weight")
                                Spacer()
                                Text("\(String(format: "%.1f", exercise.weight)) kg")
                                    .foregroundColor(.secondary)
                            }
                        case "Duration (min)":
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(exercise.duration) min")
                                    .foregroundColor(.secondary)
                            }
                        case "Distance (km)":
                            HStack {
                                Text("Distance")
                                Spacer()
                                Text("\(String(format: "%.1f", exercise.distance)) km")
                                    .foregroundColor(.secondary)
                            }
                        case "Calories":
                            HStack {
                                Text("Calories")
                                Spacer()
                                Text("\(exercise.calories)")
                                    .foregroundColor(.secondary)
                            }
                        case "Hold Time (sec)":
                            HStack {
                                Text("Hold Time")
                                Spacer()
                                Text("\(exercise.holdTime) sec")
                                    .foregroundColor(.secondary)
                            }
                        default:
                            EmptyView()
                        }
                    }
                    
                    if let notes = exercise.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Notes")
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if isEditing {
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                    
                    Button("Cancel") {
                        isEditing = false
                        resetFields()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(exercise.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isEditing {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        // Convert string inputs to appropriate types
        let setsValue = Int16(sets) ?? 0
        let repsValue = Int16(reps) ?? 0
        let weightValue = Double(weight) ?? 0.0
        let durationValue = Int16(duration) ?? 0
        let distanceValue = Double(distance) ?? 0.0
        let caloriesValue = Int16(calories) ?? 0
        let holdTimeValue = Int16(holdTime) ?? 0
        
        dataManager.updateExercise(
            exercise: exercise,
            name: name,
            exerciseType: selectedExerciseType,
            sets: setsValue,
            reps: repsValue,
            weight: weightValue,
            duration: durationValue,
            distance: distanceValue,
            calories: caloriesValue,
            holdTime: holdTimeValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        isEditing = false
    }
    
    private func resetFields() {
        name = exercise.name
        selectedExerciseType = exercise.exerciseTypeEnum
        sets = "\(exercise.sets)"
        reps = "\(exercise.reps)"
        weight = String(format: "%.1f", exercise.weight)
        duration = "\(exercise.duration)"
        distance = String(format: "%.1f", exercise.distance)
        calories = "\(exercise.calories)"
        holdTime = "\(exercise.holdTime)"
        notes = exercise.notes ?? ""
    }
} 