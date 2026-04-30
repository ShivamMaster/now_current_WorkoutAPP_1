import SwiftUI

struct AddWorkoutView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedField: WorkoutField?

    @State private var name = ""
    @State private var duration = ""
    @State private var notes = ""
    @State private var date = Date()

    enum WorkoutField { case name, duration, notes }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $name)
                        .focused($focusedField, equals: .name)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Minutes", text: $duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .duration)
                    }

                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(5)
                        .focused($focusedField, equals: .notes)
                }

                Section {
                    Button("Save") {
                        saveWorkout()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            // Feature 2: Done button to dismiss number pad / keyboard
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !duration.isEmpty && Int16(duration) != nil
    }

    private func saveWorkout() {
        guard let durationValue = Int16(duration) else { return }
        dataManager.addWorkout(
            name: name,
            date: date,
            duration: durationValue,
            notes: notes.isEmpty ? nil : notes
        )
        presentationMode.wrappedValue.dismiss()
    }
}