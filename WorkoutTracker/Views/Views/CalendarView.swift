import SwiftUI

struct CalendarView: View {
    // Sample workout data - in a real app, you would fetch this from your data store
    @State private var workoutDays: [Date] = []
    
    // Calendar configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let daysInYear = 365
    private let calendar = Calendar.current
    
    // Colors for different workout intensities
    private let colors: [Color] = [
        Color(red: 0.8, green: 0.9, blue: 0.8),  // Light - 1 workout
        Color(red: 0.6, green: 0.8, blue: 0.6),  // Medium - 2 workouts
        Color(red: 0.4, green: 0.7, blue: 0.4),  // Heavy - 3 workouts
        Color(red: 0.2, green: 0.6, blue: 0.2)   // Intense - 4+ workouts
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Workout Activity")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("Each square represents a day. Darker colors indicate more workouts on that day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Calendar grid
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(getDaysInYear(), id: \.self) { date in
                        DayCell(date: date, workoutDays: workoutDays)
                    }
                }
                .padding()
                
                // Legend
                HStack(spacing: 16) {
                    ForEach(0..<4) { index in
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(colors[index])
                                .frame(width: 15, height: 15)
                                .cornerRadius(2)
                            
                            Text(index == 0 ? "1 workout" : 
                                 index == 1 ? "2 workouts" : 
                                 index == 2 ? "3 workouts" : "4+ workouts")
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Activity Calendar")
        .onAppear {
            // Load sample workout data - replace with actual data in your app
            loadSampleWorkoutData()
        }
    }
    
    // Get all days in the current year
    private func getDaysInYear() -> [Date] {
        let today = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today))!
        
        return (0..<daysInYear).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfYear)
        }
    }
    
    // Load sample workout data - replace with your actual data loading logic
    private func loadSampleWorkoutData() {
        // This is just sample data - you should replace this with actual workout data from your app
        let today = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today))!
        
        // Generate some random workout days for demonstration
        var sampleDays: [Date] = []
        for i in 0..<daysInYear {
            if Int.random(in: 0...3) > 1 { // ~50% chance of having a workout
                if let date = calendar.date(byAdding: .day, value: i, to: startOfYear) {
                    // Add multiple entries for the same day to simulate multiple workouts
                    let workoutCount = Int.random(in: 1...5)
                    for _ in 0..<workoutCount {
                        sampleDays.append(date)
                    }
                }
            }
        }
        
        workoutDays = sampleDays
    }
}

// A single day cell in the calendar
struct DayCell: View {
    let date: Date
    let workoutDays: [Date]
    private let calendar = Calendar.current
    
    // Colors for different workout intensities
    private let colors: [Color] = [
        Color(red: 0.9, green: 0.9, blue: 0.9),  // No workout
        Color(red: 0.8, green: 0.9, blue: 0.8),  // Light - 1 workout
        Color(red: 0.6, green: 0.8, blue: 0.6),  // Medium - 2 workouts
        Color(red: 0.4, green: 0.7, blue: 0.4),  // Heavy - 3 workouts
        Color(red: 0.2, green: 0.6, blue: 0.2)   // Intense - 4+ workouts
    ]
    
    var body: some View {
        let count = workoutCount()
        let color = count == 0 ? colors[0] : 
                   count == 1 ? colors[1] :
                   count == 2 ? colors[2] :
                   count == 3 ? colors[3] : colors[4]
        
        Rectangle()
            .fill(color)
            .frame(width: 15, height: 15)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .tooltip(tooltipText())
    }
    
    // Count workouts for this day
    private func workoutCount() -> Int {
        workoutDays.filter { calendar.isDate($0, inSameDayAs: date) }.count
    }
    
    // Generate tooltip text
    private func tooltipText() -> String {
        let count = workoutCount()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        return "\(dateFormatter.string(from: date)): \(count) workout\(count == 1 ? "" : "s")"
    }
}

// Simple tooltip modifier
extension View {
    func tooltip(_ text: String) -> some View {
        self
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        EmptyView()
                    }
                    .contentShape(Rectangle())
                    .onHover { isHovered in
                        if isHovered {
                            let hoverString = NSAttributedString(string: text)
                            NSCursor.pointingHand.set()
                            DispatchQueue.main.async {
                                NSHoverNote.show(with: hoverString, at: NSPoint(x: geo.frame(in: .global).midX, y: geo.frame(in: .global).midY), in: nil, preferredPosition: .bottom, duration: 2.0, fadeInDuration: 0.25, fadeOutDuration: 0.25, slideInDuration: 0, slideOutDuration: 0)
                            }
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                }
            )
    }
}