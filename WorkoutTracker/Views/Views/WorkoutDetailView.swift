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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                Spacer()
                Text(exercise.exerciseTypeEnum.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text(exercise.primaryMetrics)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
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