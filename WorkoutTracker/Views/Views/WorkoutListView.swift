import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingAddWorkout = false

    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutRowView(workout: workout)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            dataManager.duplicateWorkout(workout)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            if let index = dataManager.workouts.firstIndex(of: workout) {
                                deleteWorkouts(at: IndexSet(integer: index))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SyncStatusView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWorkout = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView()
            }
        }
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            let workout = dataManager.workouts[index]
            dataManager.deleteWorkout(workout)
        }
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                Spacer()
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(workout.exerciseArray.count) exercises")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(workout.duration) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: workout.date)
    }
}

struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutListView()
            .environmentObject(DataManager.shared)
    }
}

struct SyncStatusView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dataManager.hasUnsyncedChanges ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
                .shadow(color: (dataManager.hasUnsyncedChanges ? Color.orange : Color.green).opacity(0.5), radius: 2)
            
            Text(dataManager.hasUnsyncedChanges ? "unsynced" : "synced")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}