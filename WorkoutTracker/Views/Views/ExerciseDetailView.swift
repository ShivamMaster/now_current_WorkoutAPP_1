import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("weightUnit") private var displayWeightUnit: String = "kg" // User's preferred unit

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
    @State private var editingWeightUnit: String // Unit for the editing field

    init(exercise: ExerciseModel) {
        self.exercise = exercise
        let preferredUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"

        // Initialize state variables with exercise values
        _name = State(initialValue: exercise.name)
        _selectedExerciseType = State(initialValue: exercise.exerciseTypeEnum)
        _sets = State(initialValue: "\(exercise.sets)")
        _reps = State(initialValue: "\(exercise.reps)")

        // Initialize weight based on preferred display unit
        let weightInKg = exercise.weight
        if preferredUnit == "lbs" {
            let weightInLbs = weightInKg * 2.20462
            _weight = State(initialValue: String(format: "%.1f", weightInLbs))
        } else {
            _weight = State(initialValue: String(format: "%.1f", weightInKg))
        }
        _editingWeightUnit = State(initialValue: preferredUnit) // Start editing with preferred unit

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
                        case "Weight (kg)": // This case label might be misleading now
                             VStack { // Use VStack for Picker + TextField
                                Picker("Unit", selection: $editingWeightUnit) {
                                    Text("kg").tag("kg")
                                    Text("lbs").tag("lbs")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: editingWeightUnit) { newUnit in
                                    // Convert weight value when unit changes during editing
                                    convertWeightForEditing(to: newUnit)
                                }

                                HStack {
                                    Text("Weight (\(editingWeightUnit))")
                                    Spacer()
                                    TextField("Weight", text: $weight)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
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
                    // Display Mode
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
                        case "Weight (kg)": // This case label might be misleading now
                            HStack {
                                Text("Weight")
                                Spacer()
                                // Display weight converted based on user preference
                                Text(displayWeightString(weightInKg: exercise.weight, unit: displayWeightUnit))
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
                        resetFields() // Reset fields to original display values
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Exercise" : exercise.name) // Dynamic title
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isEditing {
                    Button("Edit") {
                        // Prepare fields for editing using the preferred unit
                        prepareFieldsForEditing()
                        isEditing = true
                    }
                }
            }
        }
    }

    // Helper to format weight for display
    private func displayWeightString(weightInKg: Double, unit: String) -> String {
        if unit == "lbs" {
            let weightInLbs = weightInKg * 2.20462
            return String(format: "%.1f lbs", weightInLbs)
        } else {
            return String(format: "%.1f kg", weightInKg)
        }
    }

    // Helper to convert weight state when editing unit changes
    private func convertWeightForEditing(to newUnit: String) {
        guard let currentWeightValue = Double(weight) else { return }
        let oldUnit = (newUnit == "kg") ? "lbs" : "kg" // The unit we are converting FROM

        if oldUnit == "lbs" && newUnit == "kg" {
            // Convert lbs field value to kg
            weight = String(format: "%.1f", currentWeightValue * 0.453592)
        } else if oldUnit == "kg" && newUnit == "lbs" {
            // Convert kg field value to lbs
            weight = String(format: "%.1f", currentWeightValue * 2.20462)
        }
    }

     // Prepare state variables for the edit form
    private func prepareFieldsForEditing() {
        name = exercise.name
        selectedExerciseType = exercise.exerciseTypeEnum
        sets = "\(exercise.sets)"
        reps = "\(exercise.reps)"
        duration = "\(exercise.duration)"
        distance = String(format: "%.1f", exercise.distance)
        calories = "\(exercise.calories)"
        holdTime = "\(exercise.holdTime)"
        notes = exercise.notes ?? ""

        // Set weight field based on preferred unit for editing
        let weightInKg = exercise.weight
        editingWeightUnit = displayWeightUnit // Start editing with user's preference
        if editingWeightUnit == "lbs" {
            weight = String(format: "%.1f", weightInKg * 2.20462)
        } else {
            weight = String(format: "%.1f", weightInKg)
        }
    }


    private func saveChanges() {
        // Convert string inputs to appropriate types
        guard let setsValue = Int16(sets),
              let repsValue = Int16(reps),
              var weightValue = Double(weight), // Use var for conversion
              let durationValue = Int16(duration),
              let distanceValue = Double(distance),
              let caloriesValue = Int16(calories),
              let holdTimeValue = Int16(holdTime)
        else {
            // Handle potential conversion errors (e.g., show an alert)
            print("Error: Invalid input values.")
            return
        }

        // Convert weight back to KG if it was edited in LBS
        if editingWeightUnit == "lbs" {
            weightValue = weightValue * 0.453592 // Convert lbs to kg
        }

        // Update using DataManager (assuming an update function exists)
         dataManager.updateExercise(
             exercise: exercise,
             name: name,
             exerciseType: selectedExerciseType, // Pass the updated type
             sets: setsValue,
             reps: repsValue,
             weight: weightValue, // Pass the weight in KG
             duration: durationValue,
             distance: distanceValue,
             calories: caloriesValue,
             holdTime: holdTimeValue,
             notes: notes.isEmpty ? nil : notes
             // Pass weightUnit if your model supports it
         )

        isEditing = false
        // No need to call resetFields here, the view will update with saved data
    }

    // Reset fields back to the original display state (based on displayWeightUnit)
    private func resetFields() {
         name = exercise.name
         selectedExerciseType = exercise.exerciseTypeEnum
         sets = "\(exercise.sets)"
         reps = "\(exercise.reps)"
         duration = "\(exercise.duration)"
         distance = String(format: "%.1f", exercise.distance)
         calories = "\(exercise.calories)"
         holdTime = "\(exercise.holdTime)"
         notes = exercise.notes ?? ""

         // Reset weight field based on the *display* preference unit
         let weightInKg = exercise.weight
         if displayWeightUnit == "lbs" {
             weight = String(format: "%.1f", weightInKg * 2.20462)
         } else {
             weight = String(format: "%.1f", weightInKg)
         }
         editingWeightUnit = displayWeightUnit // Reset editing unit as well
    }
}