import SwiftUI
import Charts

struct ProgressView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedExercise = ""
    @State private var timeFrame = 90 // Days
    
    private var exerciseNames: [String] {
        var names = Set<String>()
        
        for workout in dataManager.workouts {
            for exercise in workout.exerciseArray {
                names.insert(exercise.name)
            }
        }
        
        return Array(names).sorted()
    }
    
    private var progressData: [(date: Date, exercise: ExerciseModel)] {
        guard !selectedExercise.isEmpty else { return [] }
        return dataManager.getAdvancedProgressData(for: selectedExercise, timeFrame: timeFrame)
    }
    
    private var selectedExerciseType: ExerciseType? {
        if progressData.isEmpty {
            return nil
        }
        return progressData.first?.exercise.exerciseTypeEnum
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if exerciseNames.isEmpty {
                    ContentUnavailableView(
                        "No Workout Data",
                        systemImage: "dumbbell",
                        description: Text("Add some workouts to track your progress")
                    )
                } else {
                    Form {
                        Section(header: Text("Filter Options")) {
                            Picker("Exercise", selection: $selectedExercise) {
                                Text("Select an exercise").tag("")
                                ForEach(exerciseNames, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            
                            Picker("Time Frame", selection: $timeFrame) {
                                Text("1 Month").tag(30)
                                Text("3 Months").tag(90)
                                Text("6 Months").tag(180)
                                Text("1 Year").tag(365)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        if !selectedExercise.isEmpty {
                            if progressData.isEmpty {
                                Section {
                                    ContentUnavailableView(
                                        "No Data for \(selectedExercise)",
                                        systemImage: "chart.line.downtrend.xyaxis",
                                        description: Text("No workouts found within the selected time frame")
                                    )
                                }
                            } else if let exerciseType = selectedExerciseType {
                                // Display charts based on exercise type
                                switch exerciseType {
                                case .strengthTraining, .functional:
                                    strengthTrainingCharts
                                case .cardio:
                                    cardioCharts
                                case .flexibility:
                                    flexibilityCharts
                                case .bodyweight:
                                    bodyweightCharts
                                }
                                
                                Section(header: Text("Data Points")) {
                                    ForEach(progressData.sorted(by: { $0.date > $1.date }), id: \.date) { item in
                                        VStack(alignment: .leading) {
                                            Text(item.date, format: .dateTime.year().month().day())
                                                .font(.headline)
                                            
                                            Text(item.exercise.primaryMetrics)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 5)
                                    }
                                }
                            }
                        } else {
                            Section {
                                ContentUnavailableView(
                                    "Select an Exercise",
                                    systemImage: "dumbbell",
                                    description: Text("Choose an exercise from the dropdown to view progress data")
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Progress Tracker")
            .onAppear {
                if !exerciseNames.isEmpty && selectedExercise.isEmpty {
                    selectedExercise = exerciseNames[0]
                }
            }
        }
    }
    
    // MARK: - Chart Views for Different Exercise Types
    
    private var strengthTrainingCharts: some View {
        Group {
            Section(header: Text("Weight Progress")) {
                Chart {
                    ForEach(progressData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Weight", item.exercise.weight)
                        )
                        .foregroundStyle(Color.blue)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Weight", item.exercise.weight)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Volume Progress (Sets × Reps)")) {
                Chart {
                    ForEach(progressData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Volume", Double(item.exercise.sets * item.exercise.reps))
                        )
                        .foregroundStyle(Color.green)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Volume", Double(item.exercise.sets * item.exercise.reps))
                        )
                        .foregroundStyle(Color.green)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var cardioCharts: some View {
        Group {
            Section(header: Text("Duration Progress")) {
                Chart {
                    ForEach(progressData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Duration", Double(item.exercise.duration))
                        )
                        .foregroundStyle(Color.orange)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Duration", Double(item.exercise.duration))
                        )
                        .foregroundStyle(Color.orange)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Distance Progress")) {
                Chart {
                    ForEach(progressData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Distance", item.exercise.distance)
                        )
                        .foregroundStyle(Color.purple)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Distance", item.exercise.distance)
                        )
                        .foregroundStyle(Color.purple)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var flexibilityCharts: some View {
        Group {
            Section(header: Text("Hold Time Progress")) {
                Chart {
                    ForEach(progressData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Hold Time", Double(item.exercise.holdTime))
                        )
                        .foregroundStyle(Color.teal)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Hold Time", Double(item.exercise.holdTime))
                        )
                        .foregroundStyle(Color.teal)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Duration Progress")) {
                Chart {
                    ForEach(progressData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Duration", Double(item.exercise.duration))
                        )
                        .foregroundStyle(Color.orange)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Duration", Double(item.exercise.duration))
                        )
                        .foregroundStyle(Color.orange)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var bodyweightCharts: some View {
        Group {
            Section(header: Text("Volume Progress (Sets × Reps)")) {
                Chart {
                    ForEach(progressData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Volume", Double(item.exercise.sets * item.exercise.reps))
                        )
                        .foregroundStyle(Color.green)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Volume", Double(item.exercise.sets * item.exercise.reps))
                        )
                        .foregroundStyle(Color.green)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 14)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month().day())
                            }
                        }
                    }
                }
            }
        }
    }
} 