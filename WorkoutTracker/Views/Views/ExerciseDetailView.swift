import SwiftUI
import Foundation // Import Foundation for Decimal

struct ExerciseDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("weightUnit") private var displayWeightUnit: String = "kg" // User's preferred unit

    let exercise: ExerciseModel

    // State for editing fields
    @State private var name: String
    @State private var selectedExerciseType: ExerciseType
    @State private var sets: String
    @State private var reps: String
    // State for the TextField binding
    @State private var weightInputString: String
    @State private var duration: String
    @State private var distance: String
    @State private var calories: String
    @State private var holdTime: String
    @State private var notes: String

    @State private var isEditing = false
    // State for the unit picker during editing
    @State private var editingWeightUnit: String

    // Store the definitive weight value internally, always in KG
    // We'll initialize this in init/prepareFieldsForEditing
    @State private var internalWeightKg: Decimal

    // Conversion factors as Decimals for better precision
    private let kgToLbsFactor: Decimal = 2.20462
    private let lbsToKgFactor: Decimal = 0.453592

    init(exercise: ExerciseModel) {
        self.exercise = exercise
        let preferredUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"

        // Initialize non-weight state
        _name = State(initialValue: exercise.name)
        _selectedExerciseType = State(initialValue: exercise.exerciseTypeEnum)
        _sets = State(initialValue: "\(exercise.sets)")
        _reps = State(initialValue: "\(exercise.reps)")
        _duration = State(initialValue: "\(exercise.duration)")
        _distance = State(initialValue: String(format: "%.1f", exercise.distance))
        _calories = State(initialValue: "\(exercise.calories)")
        _holdTime = State(initialValue: "\(exercise.holdTime)")
        _notes = State(initialValue: exercise.notes ?? "")

        // Initialize weight-related state
        _internalWeightKg = State(initialValue: Decimal(exercise.weight)) // Store base KG value as Decimal
        _editingWeightUnit = State(initialValue: preferredUnit) // Start editing unit with preference

        // --- Calculate the initial string value BEFORE initializing the State ---
        var initialDisplayWeight: Decimal
        if preferredUnit == "lbs" {
            initialDisplayWeight = Decimal(exercise.weight) * kgToLbsFactor
        } else {
            initialDisplayWeight = Decimal(exercise.weight)
        }
        // Call the STATIC formatWeight function
        let initialFormattedString = ExerciseDetailView.formatWeight(initialDisplayWeight)
        // --- Now initialize the State with the pre-calculated string ---
        _weightInputString = State(initialValue: initialFormattedString)
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
                             VStack {
                                Picker("Unit", selection: $editingWeightUnit) {
                                    Text("kg").tag("kg")
                                    Text("lbs").tag("lbs")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: editingWeightUnit) { newUnit in
                                    // Update the display string when unit changes, based on internal KG value
                                    updateWeightInputString(for: newUnit)
                                }

                                HStack {
                                    Text("Weight (\(editingWeightUnit))")
                                    Spacer()
                                    // Bind TextField to weightInputString
                                    TextField("Weight", text: $weightInputString)
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
                    // Display Mode (uses displayWeightString which reads exercise.weight)
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
                                // Use the existing display helper which reads the stored KG value
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
                        saveChanges() // Call site at line ~241
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
        .navigationTitle(isEditing ? "Edit Exercise" : exercise.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isEditing {
                    Button("Edit") {
                        prepareFieldsForEditing()
                        isEditing = true
                    }
                }
            }
        }
    }

    // Helper to format weight for display (using Double for compatibility)
    // Note: This one still needs access to the static formatter
    private func displayWeightString(weightInKg: Double, unit: String) -> String {
        let weightDecimal = Decimal(weightInKg)
        var displayValue: Decimal
        var displayUnit: String

        if unit == "lbs" {
            displayValue = weightDecimal * kgToLbsFactor
            displayUnit = "lbs"
        } else {
            displayValue = weightDecimal
            displayUnit = "kg"
        }
        // Call the static formatter here as well
        return "\(ExerciseDetailView.formatWeight(displayValue)) \(displayUnit)"
    }

    // Make the formatter static
    static private func formatWeight(_ weight: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .halfUp
        return formatter.string(from: weight as NSDecimalNumber) ?? "\(weight)"
    }

    // Updates the TextField string based on the internal KG value and the selected unit
    private func updateWeightInputString(for unit: String) {
        var displayValue: Decimal
        if unit == "lbs" {
            displayValue = internalWeightKg * kgToLbsFactor
        } else {
            displayValue = internalWeightKg
        }
        // Call the static formatter
        weightInputString = ExerciseDetailView.formatWeight(displayValue)
    }

    // Prepare state variables for the edit form
    private func prepareFieldsForEditing() {
        // Reset non-weight fields
        name = exercise.name
        selectedExerciseType = exercise.exerciseTypeEnum
        sets = "\(exercise.sets)"
        reps = "\(exercise.reps)"
        duration = "\(exercise.duration)"
        distance = String(format: "%.1f", exercise.distance)
        calories = "\(exercise.calories)"
        holdTime = "\(exercise.holdTime)"
        notes = exercise.notes ?? ""

        // Reset weight fields
        internalWeightKg = Decimal(exercise.weight) // Store original KG value
        editingWeightUnit = displayWeightUnit      // Set picker to user preference
        updateWeightInputString(for: editingWeightUnit) // Update TextField based on internal value and unit (uses static formatter internally)
    }

     private func resetFields() {
        // Reset non-weight fields
        name = exercise.name
        selectedExerciseType = exercise.exerciseTypeEnum
        sets = "\(exercise.sets)"
        reps = "\(exercise.reps)"
        duration = "\(exercise.duration)"
        distance = String(format: "%.1f", exercise.distance)
        calories = "\(exercise.calories)"
        holdTime = "\(exercise.holdTime)"
        notes = exercise.notes ?? ""

        // Reset weight fields to reflect original exercise data and user preference
        internalWeightKg = Decimal(exercise.weight)
        editingWeightUnit = displayWeightUnit
        updateWeightInputString(for: editingWeightUnit) // Uses static formatter internally
    }

    private func saveChanges() {
        // Convert string inputs to appropriate types
        guard let setsValue = Int16(sets),
              let repsValue = Int16(reps),
              let weightValue = Double(weightInputString.replacingOccurrences(of: ",", with: ".")),
              let durationValue = Int16(duration),
              let distanceValue = Double(distance.replacingOccurrences(of: ",", with: ".")),
              let caloriesValue = Int16(calories),
              let holdTimeValue = Int16(holdTime)
        else {
            return
        }

        // Convert weight to KG if needed
        let finalWeightKg: Double
        if editingWeightUnit == "lbs" {
            finalWeightKg = weightValue / 2.20462 // Correct: convert lbs to kg
        } else {
            finalWeightKg = weightValue
        }

        dataManager.updateExercise(
            exercise: exercise,
            name: name,
            exerciseType: selectedExerciseType,
            sets: setsValue,
            reps: repsValue,
            weight: finalWeightKg,
            duration: durationValue,
            distance: distanceValue,
            calories: caloriesValue,
            holdTime: holdTimeValue,
            notes: notes.isEmpty ? nil : notes
        )

        isEditing = false
    }
}
