import SwiftUI
import Foundation

struct ExerciseDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("weightUnit") private var displayWeightUnit: String = "kg"
    @FocusState private var focusedField: ExerciseField?

    let exercise: ExerciseModel

    @State private var name: String
    @State private var selectedExerciseType: ExerciseType
    @State private var sets: String
    @State private var reps: String
    @State private var weightInputString: String
    @State private var duration: String
    @State private var distance: String
    @State private var calories: String
    @State private var holdTime: String
    @State private var notes: String
    @State private var isEditing = false
    @State private var editingWeightUnit: String
    @State private var internalWeightKg: Decimal

    private let kgToLbsFactor: Decimal = 2.20462
    private let lbsToKgFactor: Decimal = 0.453592

    enum ExerciseField: Hashable { case name, sets, reps, weight, duration, distance, calories, holdTime, notes }

    init(exercise: ExerciseModel) {
        self.exercise = exercise
        let preferredUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"

        _name = State(initialValue: exercise.name)
        _selectedExerciseType = State(initialValue: exercise.exerciseTypeEnum)
        _sets = State(initialValue: "\(exercise.sets)")
        _reps = State(initialValue: "\(exercise.reps)")
        _duration = State(initialValue: "\(exercise.duration)")
        _distance = State(initialValue: String(format: "%.1f", exercise.distance))
        _calories = State(initialValue: "\(exercise.calories)")
        _holdTime = State(initialValue: "\(exercise.holdTime)")
        _notes = State(initialValue: exercise.notes ?? "")

        _internalWeightKg = State(initialValue: Decimal(exercise.weight))
        _editingWeightUnit = State(initialValue: preferredUnit)

        var initialDisplayWeight: Decimal
        if preferredUnit == "lbs" {
            initialDisplayWeight = Decimal(exercise.weight) * 2.20462
        } else {
            initialDisplayWeight = Decimal(exercise.weight)
        }
        let initialFormattedString = ExerciseDetailView.formatWeight(initialDisplayWeight)
        _weightInputString = State(initialValue: initialFormattedString)
    }

    var body: some View {
        Form {
            Section(header: Text("Exercise Details")) {
                if isEditing {
                    TextField("Name", text: $name)
                        .focused($focusedField, equals: .name)

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
                                    .focused($focusedField, equals: .sets)
                            }
                        case "Reps":
                            HStack {
                                Text("Reps")
                                Spacer()
                                TextField("Reps", text: $reps)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .reps)
                            }
                        case "Weight (kg)":
                            VStack {
                                Picker("Unit", selection: $editingWeightUnit) {
                                    Text("kg").tag("kg")
                                    Text("lbs").tag("lbs")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: editingWeightUnit) { _, newUnit in
                                    updateWeightInputString(for: newUnit)
                                }
                                HStack {
                                    Text("Weight (\(editingWeightUnit))")
                                    Spacer()
                                    TextField("Weight", text: $weightInputString)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .weight)
                                }
                            }
                        case "Duration (min)":
                            HStack {
                                Text("Duration (min)")
                                Spacer()
                                TextField("Minutes", text: $duration)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .duration)
                            }
                        case "Distance (km)":
                            HStack {
                                Text("Distance (km)")
                                Spacer()
                                TextField("Kilometers", text: $distance)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .distance)
                            }
                        case "Calories":
                            HStack {
                                Text("Calories")
                                Spacer()
                                TextField("Calories", text: $calories)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .calories)
                            }
                        case "Hold Time (sec)":
                            HStack {
                                Text("Hold Time (sec)")
                                Spacer()
                                TextField("Seconds", text: $holdTime)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .holdTime)
                            }
                        default:
                            EmptyView()
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5)
                        .focused($focusedField, equals: .notes)

                } else {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(exercise.name).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(exercise.exerciseTypeEnum.rawValue).foregroundColor(.secondary)
                    }
                    ForEach(exercise.exerciseTypeEnum.measurementFields, id: \.self) { field in
                        switch field {
                        case "Sets":
                            HStack { Text("Sets"); Spacer(); Text("\(exercise.sets)").foregroundColor(.secondary) }
                        case "Reps":
                            HStack { Text("Reps"); Spacer(); Text("\(exercise.reps)").foregroundColor(.secondary) }
                        case "Weight (kg)":
                            HStack {
                                Text("Weight")
                                Spacer()
                                Text(displayWeightString(weightInKg: exercise.weight, unit: displayWeightUnit))
                                    .foregroundColor(.secondary)
                            }
                        case "Duration (min)":
                            HStack { Text("Duration"); Spacer(); Text("\(exercise.duration) min").foregroundColor(.secondary) }
                        case "Distance (km)":
                            HStack { Text("Distance"); Spacer(); Text("\(String(format: "%.1f", exercise.distance)) km").foregroundColor(.secondary) }
                        case "Calories":
                            HStack { Text("Calories"); Spacer(); Text("\(exercise.calories)").foregroundColor(.secondary) }
                        case "Hold Time (sec)":
                            HStack { Text("Hold Time"); Spacer(); Text("\(exercise.holdTime) sec").foregroundColor(.secondary) }
                        default: EmptyView()
                        }
                    }
                    if let notes = exercise.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Notes")
                            Text(notes).foregroundColor(.secondary)
                        }
                    }
                }
            }

            if isEditing {
                Section {
                    Button("Save Changes") { saveChanges() }
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
            // Feature 2: Done button for number pads
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
    }

    private func displayWeightString(weightInKg: Double, unit: String) -> String {
        let weightDecimal = Decimal(weightInKg)
        let displayValue: Decimal
        let displayUnit: String
        if unit == "lbs" {
            displayValue = weightDecimal * kgToLbsFactor
            displayUnit = "lbs"
        } else {
            displayValue = weightDecimal
            displayUnit = "kg"
        }
        return "\(ExerciseDetailView.formatWeight(displayValue)) \(displayUnit)"
    }

    static private func formatWeight(_ weight: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .halfUp
        return formatter.string(from: weight as NSDecimalNumber) ?? "\(weight)"
    }

    private func updateWeightInputString(for unit: String) {
        let displayValue: Decimal = unit == "lbs" ? internalWeightKg * kgToLbsFactor : internalWeightKg
        weightInputString = ExerciseDetailView.formatWeight(displayValue)
    }

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
        internalWeightKg = Decimal(exercise.weight)
        editingWeightUnit = displayWeightUnit
        updateWeightInputString(for: editingWeightUnit)
    }

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
        internalWeightKg = Decimal(exercise.weight)
        editingWeightUnit = displayWeightUnit
        updateWeightInputString(for: editingWeightUnit)
    }

    private func saveChanges() {
        guard let setsValue = Int16(sets),
              let repsValue = Int16(reps),
              let weightValue = Double(weightInputString.replacingOccurrences(of: ",", with: ".")),
              let durationValue = Int16(duration),
              let distanceValue = Double(distance.replacingOccurrences(of: ",", with: ".")),
              let caloriesValue = Int16(calories),
              let holdTimeValue = Int16(holdTime)
        else { return }

        let finalWeightKg: Double = editingWeightUnit == "lbs" ? weightValue / 2.20462 : weightValue

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