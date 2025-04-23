import SwiftUI

struct AddExerciseView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    let workout: WorkoutModel
    
    @State private var name = ""
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
                        Text("Weight (kg)")
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
        
        dataManager.addExercise(
            to: workout,
            name: name,
            sets: setsValue,
            reps: repsValue,
            weight: weightValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        presentationMode.wrappedValue.dismiss()
    }
} 