import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingAddExercise = false
    
    // Add state variables for editing
    @State private var isEditing = false
    @State private var name: String
    @State private var date: Date
    @State private var duration: String
    @State private var notes: String
    
    let workout: WorkoutModel
    
    // Initialize state variables with workout values
    init(workout: WorkoutModel) {
        self.workout = workout
        _name = State(initialValue: workout.name)
        _date = State(initialValue: workout.date)
        _duration = State(initialValue: "\(workout.duration)")
        _notes = State(initialValue: workout.notes ?? "")
    }
    
    var body: some View {
        List {
            Section(header: Text("Details")) {
                if isEditing {
                    // Edit mode fields
                    TextField("Workout Name", text: $name)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("Duration (minutes)")
                        Spacer()
                        TextField("Duration", text: $duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5)
                } else {
                    // Display mode fields
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(formattedDate)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(workout.duration) minutes")
                            .foregroundColor(.secondary)
                    }
                    
                    if let notes = workout.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            
            // Edit mode buttons
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
            
            NavigationLink(destination: CategoryWorkoutView(workout: workout)) {
                HStack {
                    Image(systemName: "list.bullet.clipboard.fill")
                    Text("View Exercises By Category")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
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
                
                Button(action: {
                    showingAddExercise = true
                }) {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(workout.name)
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(workout: workout)
        }
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
    
    // Add functions for saving changes and resetting fields
    private func saveChanges() {
        guard let durationValue = Int16(duration) else {
            return
        }
        
        dataManager.updateWorkout(
            workout: workout,
            name: name,
            date: date,
            duration: durationValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        isEditing = false
    }
    
    private func resetFields() {
        name = workout.name
        date = workout.date
        duration = "\(workout.duration)"
        notes = workout.notes ?? ""
    }
}

struct EnhancedExerciseRowView: View {
    let exercise: ExerciseModel
    @AppStorage("weightUnit") private var displayWeightUnit: String = "kg" // Access user preference

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.headline)
                // Display primary metrics based on exercise type and user preference
                Text(formattedPrimaryMetrics()) // Use a helper function
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    // Helper function to format the primary metrics string
    private func formattedPrimaryMetrics() -> String {
        var metrics: [String] = []
        let type = exercise.exerciseTypeEnum

        if type.measurementFields.contains("Sets") && exercise.sets > 0 {
            metrics.append("\(exercise.sets) set\(exercise.sets == 1 ? "" : "s")")
        }
        if type.measurementFields.contains("Reps") && exercise.reps > 0 {
            metrics.append("\(exercise.reps) rep\(exercise.reps == 1 ? "" : "s")")
        }
        // Format weight based on user preference
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


        // Join the relevant metrics with " x "
        return metrics.joined(separator: " x ")
    }

    // Helper function to format weight (copied/adapted from ExerciseDetailView)
    private func displayWeightString(weightInKg: Double, unit: String) -> String {
        if unit == "lbs" {
            let weightInLbs = weightInKg * 2.20462
            // Use %g to remove trailing .0 if it's a whole number after conversion
            return String(format: "%g lbs", weightInLbs)
        } else {
            return String(format: "%g kg", weightInKg)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: ExerciseModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(exercise.name)
                .font(.headline)
            
            HStack {
                Text("\(exercise.sets) sets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(exercise.reps) reps")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", exercise.weight)) kg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct CategoryWorkoutView: View {
    @EnvironmentObject private var dataManager: DataManager
    let workout: WorkoutModel
    
    var body: some View {
        List {
            ForEach(ExerciseType.allCases) { category in
                Section(header: Text(category.rawValue)) {
                    let categoryExercises = workout.exerciseArray.filter { 
                        $0.exerciseTypeEnum == category 
                    }
                    
                    if categoryExercises.isEmpty {
                        Text("No exercises added yet")
                            .italic()
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(categoryExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .font(.headline)
                                    Text(exercise.primaryMetrics)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("\(workout.name) Categories")
    }
}


//// Add this function inside WorkoutDetailView
//private func duplicateExercise(_ exercise: ExerciseModel) {
//    dataManager.duplicateExercise(exercise, for: workout)
//}
