import SwiftUI

// MARK: - Split List View
/// The primary interface for organizing workout routines into "splits" (e.g., Push/Pull/Legs).
/// Replaces the generic workout list to provide a more structured training approach.
struct SplitListView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    // MARK: - Navigation & UI State
    @State private var showingAddSplit = false
    /// Force-reset identifier for navigation stack management.
    @State private var navigationId = UUID()
    
    // MARK: - Inline Renaming State
    @State private var isRenamingSplit = false
    @State private var splitToRename: WorkoutSplitModel?
    @State private var newSplitName = ""

    var body: some View {
        NavigationView {
            Group {
                if dataManager.splits.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.7))
                        Text("No Splits Yet")
                            .font(.title2.bold())
                        Text("Create a training split (e.g. Push/Pull/Legs)\nand organize your workout days inside it.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button(action: { showingAddSplit = true }) {
                            Label("Create Split", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(dataManager.splits) { split in
                            NavigationLink(destination: SplitDetailView(split: split)) {
                                SplitRowView(split: split)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    dataManager.deleteSplit(split)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    dataManager.duplicateSplit(split)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                                
                                Button {
                                    splitToRename = split
                                    newSplitName = split.name
                                    isRenamingSplit = true
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("My Splits")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SyncStatusView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSplit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSplit) {
                AddSplitView()
            }
            .alert("Rename Split", isPresented: $isRenamingSplit) {
                TextField("Split Name", text: $newSplitName)
                Button("Save") {
                    if let split = splitToRename, !newSplitName.isEmpty {
                        dataManager.renameSplit(split, newName: newSplitName)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .id(navigationId)
        .onReceive(dataManager.$popToRootWorkout) { _ in
            navigationId = UUID() // Reset entire navigation stack
        }
    }
}

// MARK: - Split Row
struct SplitRowView: View {
    let split: WorkoutSplitModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(split.name)
                .font(.headline)
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(split.workoutArray.count) day\(split.workoutArray.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Created \(split.createdAt.formatted(.dateTime.month().day()))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Split Detail View (shows workout days within a split)
struct SplitDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    let split: WorkoutSplitModel
    @State private var showingAddDay = false

    var body: some View {
        List {
            if split.workoutArray.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 40))
                            .foregroundColor(.blue.opacity(0.6))
                        Text("No days yet")
                            .font(.headline)
                        Text("Add your first workout day to this split.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(action: { showingAddDay = true }) {
                            Label("Add Workout Day", systemImage: "plus.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            } else {
                Section(header: Text("Workout Days")) {
                    ForEach(split.workoutArray) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            WorkoutDayRowView(workout: workout)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                dataManager.deleteWorkout(workout)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                dataManager.duplicateWorkout(workout)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(split.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddDay = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDay) {
            AddDayView(split: split)
        }
    }
}

// MARK: - Workout Day Row (used inside SplitDetailView)
struct WorkoutDayRowView: View {
    let workout: WorkoutModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let dayName = workout.dayName, !dayName.isEmpty {
                    Text(dayName)
                        .font(.headline)
                } else {
                    Text(workout.name)
                        .font(.headline)
                }
                Spacer()
                Text(workout.date.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Label("\(workout.exerciseArray.count) exercises", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("\(workout.duration) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Add Split View
struct AddSplitView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var showingDiscardAlert = false

    private var hasChanges: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Split Name")) {
                    TextField("e.g. Push/Pull/Legs, PPL, Bro Split…", text: $name)
                        .autocapitalization(.words)
                }
                Section {
                    Button("Create Split") {
                        dataManager.addSplit(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("New Split")
            .navigationBarItems(trailing: Button("Cancel") {
                if hasChanges {
                    showingDiscardAlert = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            })
            .interactiveDismissDisabled(hasChanges)
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to discard this split?")
            }
        }
    }
}

// MARK: - Add Day View (adds a workout day to a split)
struct AddDayView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedField: DayField?

    let split: WorkoutSplitModel

    @State private var dayName = ""
    @State private var workoutName = ""
    @State private var duration = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var showingDiscardAlert = false

    private var hasChanges: Bool {
        !dayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !duration.isEmpty ||
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    enum DayField { case dayName, workoutName, duration, notes }

    private var isValid: Bool {
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !duration.isEmpty && Int16(duration) != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Day Label (Optional)")) {
                    TextField("e.g. Push Day, Monday, Chest & Tri…", text: $dayName)
                        .focused($focusedField, equals: .dayName)
                }

                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $workoutName)
                        .focused($focusedField, equals: .workoutName)

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
                        .lineLimit(4)
                        .focused($focusedField, equals: .notes)
                }

                Section {
                    Button("Add Day") {
                        saveDay()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Add Workout Day")
            .navigationBarItems(trailing: Button("Cancel") {
                if hasChanges {
                    showingDiscardAlert = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            })
            .interactiveDismissDisabled(hasChanges)
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to discard this workout day?")
            }
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

    private func saveDay() {
        guard let durationValue = Int16(duration) else { return }
        let trimmedDayName = dayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        dataManager.addWorkout(
            name: trimmedName,
            date: date,
            duration: durationValue,
            notes: notes.isEmpty ? nil : notes,
            dayName: trimmedDayName.isEmpty ? nil : trimmedDayName,
            split: split
        )
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Previews
struct SplitListView_Previews: PreviewProvider {
    static var previews: some View {
        SplitListView()
            .environmentObject(DataManager.shared)
    }
}
