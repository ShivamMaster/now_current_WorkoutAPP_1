import SwiftUI

// MARK: - Category Workout View
/// An alternative visualization of a workout session, grouping exercises by their type (e.g., Strength, Cardio).
/// Uses expandable sections (DisclosureGroups) for a clean, organized layout.
struct CategoryWorkoutView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingAddExercise = false
    @State private var selectedCategory: ExerciseType?
    @State private var expandedCategories: Set<ExerciseType> = []
    
    let workout: WorkoutModel
    
    var body: some View {
        List {
            ForEach(ExerciseType.allCases) { category in
                Section {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCategories.contains(category) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedCategories.insert(category)
                                } else {
                                    expandedCategories.remove(category)
                                }
                            }
                        ),
                        content: {
                            // Filtered exercises for this category
                            let categoryExercises = workout.exerciseArray.filter { $0.exerciseTypeEnum == category }
                            
                            if categoryExercises.isEmpty {
                                Text("No \(category.rawValue) exercises added yet")
                                    .italic()
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(categoryExercises) { exercise in
                                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                        EnhancedExerciseRowView(exercise: exercise)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            dataManager.deleteExercise(exercise)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            
                            // Add exercise button for this category
                            Button {
                                selectedCategory = category
                                showingAddExercise = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add \(category.rawValue) Exercise")
                                }
                            }
                            .padding(.top, 5)
                        },
                        label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                                    .font(.headline)
                                Spacer()
                                Text("\(workout.exerciseArray.filter { $0.exerciseTypeEnum == category }.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(5)
                                    .background(Circle().fill(Color(.systemGray6)))
                            }
                        }
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(workout.name)
        .sheet(isPresented: $showingAddExercise) {
            if let category = selectedCategory {
                AddExerciseView(workout: workout, preselectedType: category)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(ExerciseType.allCases) { category in
                        Button {
                            selectedCategory = category
                            showingAddExercise = true
                        } label: {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
    }
}