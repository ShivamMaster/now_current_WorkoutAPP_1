import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    let exercise: ExerciseModel
    
    @AppStorage("weightUnit") private var defaultWeightUnit: String = "kg"
    @State private var weightUnit: String
    
    @State private var name: String
    @State private var sets: String
    @State private var reps: String
    @State private var weight: String
    @State private var notes: String
    @State private var isEditing = false
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        let userUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"
        _weightUnit = State(initialValue: userUnit)
        _name = State(initialValue: exercise.name)
        _sets = State(initialValue: "\(exercise.sets)")
        _reps = State(initialValue: "\(exercise.reps)")
        // Display weight in user's preferred unit
        let displayWeight: Double
        if userUnit == "lbs" {
            displayWeight = exercise.weight * 2.20462
        } else {
            displayWeight = exercise.weight
        }
        _weight = State(initialValue: String(format: "%.1f", displayWeight))
        _notes = State(initialValue: exercise.notes ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Exercise Details")) {
                if isEditing {
                    TextField("Name", text: $name)
                    
                    HStack {
                        Text("Sets")
                        Spacer()
                        TextField("Sets", text: $sets)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Reps")
                        Spacer()
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("kg").tag("kg")
                        Text("lbs").tag("lbs")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: weightUnit) { newUnit in
                        // Convert displayed weight when unit changes
                        if let currentValue = Double(weight) {
                            if newUnit == "lbs" {
                                weight = String(format: "%.1f", currentValue * 2.20462)
                            } else {
                                weight = String(format: "%.1f", currentValue / 2.20462)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Weight (\(weightUnit))")
                        Spacer()
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
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
                        Text("Sets")
                        Spacer()
                        Text("\(exercise.sets)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Reps")
                        Spacer()
                        Text("\(exercise.reps)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        let displayWeight = weightUnit == "lbs" ? exercise.weight * 2.20462 : exercise.weight
                        Text("\(String(format: "%.1f", displayWeight)) \(weightUnit)")
                            .foregroundColor(.secondary)
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
        guard let setsValue = Int16(sets),
              let repsValue = Int16(reps),
              let weightValue = Double(weight) else {
            return
        }
        
        // Convert to kg if needed
        let finalWeight: Double
        if weightUnit == "lbs" {
            finalWeight = weightValue / 2.20462
        } else {
            finalWeight = weightValue
        }
        
        // Save the user's preferred weight unit
        UserDefaults.standard.set(weightUnit, forKey: "weightUnit")
        
        dataManager.updateExercise(
            exercise: exercise,
            name: name,
            sets: setsValue,
            reps: repsValue,
            weight: finalWeight,
            notes: notes.isEmpty ? nil : notes
        )
        
        isEditing = false
    }
    
    private func resetFields() {
        name = exercise.name
        sets = "\(exercise.sets)"
        reps = "\(exercise.reps)"
        let displayWeight: Double
        if weightUnit == "lbs" {
            displayWeight = exercise.weight * 2.20462
        } else {
            displayWeight = exercise.weight
        }
        weight = String(format: "%.1f", displayWeight)
        notes = exercise.notes ?? ""
    }
}