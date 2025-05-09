import SwiftUI

struct AddExerciseView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    // Add weight unit support
    @AppStorage("weightUnit") private var defaultWeightUnit: String = "kg"
    @State private var weightUnit: String
    
    let workout: WorkoutModel
    
    @State private var name = ""
    @State private var selectedExerciseType: ExerciseType = .strengthTraining
    @State private var sets = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var notes = ""
    
    // Common exercise suggestions
    let exerciseSuggestions = [
        "Bench Press", "Squat", "Deadlift", "Shoulder Press",
        "Pull-up", "Push-up", "Bicep Curl", "Tricep Extension",
        "Leg Press", "Lat Pulldown", "Plank", "Lunge",
        "Leg Extension", "Leg Curl", "Calf Raise", "Dip"
    ]
    
    @State private var showingSuggestions = false
    
    // Initialize with weight unit from user defaults
    init(workout: WorkoutModel) {
        self.workout = workout
        _weightUnit = State(initialValue: UserDefaults.standard.string(forKey: "weightUnit") ?? "kg")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $name)
                    
                    Button("Select from common exercises") {
                        showingSuggestions = true
                    }
                    .sheet(isPresented: $showingSuggestions) {
                        NavigationView {
                            List(exerciseSuggestions, id: \.self) { exercise in
                                Button(exercise) {
                                    name = exercise
                                    showingSuggestions = false
                                }
                            }
                            .navigationTitle("Common Exercises")
                            .navigationBarItems(trailing: Button("Cancel") {
                                showingSuggestions = false
                            })
                        }
                    }
                    
                    // Add weight unit picker
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("kg").tag("kg")
                        Text("lbs").tag("lbs")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
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
                    
                    HStack {
                        Text("Weight (\(weightUnit))")
                        Spacer()
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
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
        !name.isEmpty && 
        !sets.isEmpty && Int16(sets) != nil &&
        !reps.isEmpty && Int16(reps) != nil &&
        !weight.isEmpty && Double(weight) != nil
    }
    
    private func saveExercise() {
        guard let setsValue = Int16(sets),
              let repsValue = Int16(reps),
              let weightValue = Double(weight) else {
            return
        }
        
        // Convert weight to kg if entered in lbs
        let finalWeight: Double
        if weightUnit == "lbs" {
            finalWeight = weightValue / 2.20462 // Convert lbs to kg
        } else {
            finalWeight = weightValue
        }
        
        // Save the user's preferred weight unit
        UserDefaults.standard.set(weightUnit, forKey: "weightUnit")
        
        dataManager.addExercise(
            to: workout,
            name: name,
            sets: setsValue,
            reps: repsValue,
            weight: finalWeight, // Use the converted weight
            notes: notes.isEmpty ? nil : notes
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}