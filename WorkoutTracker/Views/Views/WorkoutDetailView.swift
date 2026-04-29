import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingAddExercise = false
    @FocusState private var focusedField: DetailField?

    @State private var isEditing = false
    @State private var name: String
    @State private var date: Date
    @State private var duration: String
    @State private var notes: String
    @State private var dayName: String

    let workout: WorkoutModel

    enum DetailField { case name, duration, notes, dayName }

    init(workout: WorkoutModel) {
        self.workout = workout
        _name = State(initialValue: workout.name)
        _date = State(initialValue: workout.date)
        _duration = State(initialValue: "\(workout.duration)")
        _notes = State(initialValue: workout.notes ?? "")
        _dayName = State(initialValue: workout.dayName ?? "")
    }

    var body: some View {
        List {
            Section(header: Text("Details")) {
                if isEditing {
                    TextField("Workout Name", text: $name)
                        .focused($focusedField, equals: .name)

                    TextField("Day Label (Optional)", text: $dayName)
                        .focused($focusedField, equals: .dayName)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    HStack {
                        Text("Duration (minutes)")
                        Spacer()
                        TextField("Duration", text: $duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .duration)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5)
                        .focused($focusedField, equals: .notes)
                } else {
                    if let dayName = workout.dayName, !dayName.isEmpty {
                        HStack {
                            Text("Day")
                            Spacer()
                            Text(dayName).foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(formattedDate).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(workout.duration) minutes").foregroundColor(.secondary)
                    }
                    if let notes = workout.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Notes").font(.headline)
                            Text(notes).font(.body).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
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

            NavigationLink(destination: CategoryWorkoutView(workout: workout)) {
                HStack {
                    Image(systemName: "list.bullet.clipboard.fill")
                    Text("View Exercises By Category")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }

            Section(header: Text("All Exercises")) {
                ForEach(workout.exerciseArray) { exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        EnhancedExerciseRowView(exercise: exercise)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            dataManager.duplicateExercise(exercise, in: workout)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let index = workout.exerciseArray.firstIndex(of: exercise) {
                                deleteExercises(at: IndexSet(integer: index))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteExercises)

                Button(action: { showingAddExercise = true }) {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(workout.dayName?.isEmpty == false ? (workout.dayName ?? workout.name) : workout.name)
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(workout: workout)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isEditing {
                    Button("Edit") { isEditing = true }
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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: workout.date)
    }

    private func deleteExercises(at offsets: IndexSet) {
        let exercises = workout.exerciseArray
        for index in offsets {
            dataManager.deleteExercise(exercises[index])
        }
    }

    private func saveChanges() {
        guard let durationValue = Int16(duration) else { return }
        dataManager.updateWorkout(
            workout: workout,
            name: name,
            date: date,
            duration: durationValue,
            notes: notes.isEmpty ? nil : notes,
            dayName: dayName.isEmpty ? nil : dayName
        )
        isEditing = false
    }

    private func resetFields() {
        name = workout.name
        date = workout.date
        duration = "\(workout.duration)"
        notes = workout.notes ?? ""
        dayName = workout.dayName ?? ""
    }
}

// MARK: - Enhanced Exercise Row View
struct EnhancedExerciseRowView: View {
    let exercise: ExerciseModel
    @AppStorage("weightUnit") private var displayWeightUnit: String = "kg"

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name).font(.headline)
                Text(formattedPrimaryMetrics())
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    private func formattedPrimaryMetrics() -> String {
        var metrics: [String] = []
        let type = exercise.exerciseTypeEnum
        if type.measurementFields.contains("Sets") && exercise.sets > 0 {
            metrics.append("\(exercise.sets) set\(exercise.sets == 1 ? "" : "s")")
        }
        if type.measurementFields.contains("Reps") && exercise.reps > 0 {
            metrics.append("\(exercise.reps) rep\(exercise.reps == 1 ? "" : "s")")
        }
        if type.measurementFields.contains("Weight (kg)") && exercise.weight > 0 {
            metrics.append(displayWeightString(weightInKg: exercise.weight, unit: displayWeightUnit))
        }
        if type.measurementFields.contains("Duration (min)") && exercise.duration > 0 {
            metrics.append("\(exercise.duration) min")
        }
        if type.measurementFields.contains("Distance (km)") && exercise.distance > 0 {
            metrics.append(String(format: "%.1f km", exercise.distance))
        }
        if type.measurementFields.contains("Calories") && exercise.calories > 0 {
            metrics.append("\(exercise.calories) kcal")
        }
        if type.measurementFields.contains("Hold Time (sec)") && exercise.holdTime > 0 {
            metrics.append("\(exercise.holdTime) sec")
        }
        return metrics.joined(separator: " × ")
    }

    private func displayWeightString(weightInKg: Double, unit: String) -> String {
        if unit == "lbs" {
            return String(format: "%g lbs", weightInKg * 2.20462)
        } else {
            return String(format: "%g kg", weightInKg)
        }
    }
}

// MARK: - Exercise Row View (simple)
struct ExerciseRowView: View {
    let exercise: ExerciseModel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(exercise.name).font(.headline)
            HStack {
                Text("\(exercise.sets) sets").font(.subheadline).foregroundColor(.secondary)
                Text("•").foregroundColor(.secondary)
                Text("\(exercise.reps) reps").font(.subheadline).foregroundColor(.secondary)
                Text("•").foregroundColor(.secondary)
                Text(String(format: "%.1f kg", exercise.weight)).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}