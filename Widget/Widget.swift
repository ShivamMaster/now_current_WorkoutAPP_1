import WidgetKit
import SwiftUI

// Restore your original SimpleEntry definition
struct SimpleEntry: TimelineEntry {
    let date: Date
    let currentMonthDate: Date
    let workoutDays: Set<Int> // Make sure this is back
}

// Restore your original Provider definition
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // Restore your placeholder logic
        SimpleEntry(date: Date(), currentMonthDate: Date(), workoutDays: [1, 5, 15])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Restore your snapshot logic (including fetchWorkoutDays)
        let entry = SimpleEntry(date: Date(), currentMonthDate: Date(), workoutDays: fetchWorkoutDays(for: Date()))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        // Restore your timeline logic (including fetchWorkoutDays)
        let currentDate = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentDate))!
        let workoutDays = fetchWorkoutDays(for: startOfMonth)

        let entry = SimpleEntry(date: currentDate, currentMonthDate: startOfMonth, workoutDays: workoutDays)

        let nextUpdateDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: currentDate))!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }

    // Restore your fetchWorkoutDays function
    private func fetchWorkoutDays(for month: Date) -> Set<Int> {
        // Placeholder data or your actual fetching logic
        return [3, 8, 21]
    }
}

// Restore your original WidgetEntryView definition
struct WidgetEntryView : View {
    var entry: Provider.Entry
    let calendar = Calendar.current
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        // Restore your full VStack calendar layout here...
        VStack(alignment: .leading, spacing: 4) {
            Text(monthYearString(from: entry.currentMonthDate))
                .font(.headline)
                .padding(.bottom, 4)

            // Day of week headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid (restore the full logic)
            let days = daysInMonth(for: entry.currentMonthDate)
            let firstDayWeekday = weekday(for: entry.currentMonthDate)
            let totalCells = days.count + firstDayWeekday - 1
            let numberOfRows = Int(ceil(Double(totalCells) / 7.0))

            ForEach(0..<numberOfRows, id: \.self) { row in
                HStack(spacing: 0) { // Reduced spacing
                    ForEach(1...7, id: \.self) { col in
                        let dayIndex = row * 7 + col - firstDayWeekday
                        if dayIndex >= 0 && dayIndex < days.count {
                            let day = days[dayIndex]
                            let isWorkoutDay = entry.workoutDays.contains(day)
                            Text("\(day)")
                                .font(.caption2) // Smaller font for day numbers
                                .frame(maxWidth: .infinity)
                                .padding(1) // Reduced padding around numbers
                                // Use accent color for background and make it boxy
                                .background(isWorkoutDay ? Color.accentColor.opacity(0.6) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 3)) // Boxier shape
                                .foregroundColor(isToday(day: day) ? .red : .primary)
                                .minimumScaleFactor(0.6) // Allow text to shrink slightly if needed
                        } else {
                            // Keep empty text for alignment
                            Text("")
                                .font(.caption2) // Match font size
                                .frame(maxWidth: .infinity)
                                .padding(1) // Match padding
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        // End of restored VStack
    }

    // Restore your helper functions (monthYearString, daysInMonth, etc.)
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysInMonth(for date: Date) -> [Int] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        return Array(range)
    }

    private func weekday(for date: Date) -> Int {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        return calendar.component(.weekday, from: startOfMonth)
    }

    private func isToday(day: Int) -> Bool {
        let today = calendar.component(.day, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        let entryMonth = calendar.component(.month, from: entry.currentMonthDate)
        let currentYear = calendar.component(.year, from: Date())
        let entryYear = calendar.component(.year, from: entry.currentMonthDate)

        return day == today && currentMonth == entryMonth && currentYear == entryYear
    }
}


// Define the main widget structure
struct WorkoutCalendarWidget: Widget {
    let kind: String = "WorkoutCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry) // Use your restored view
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Workout Calendar") // Restore original name
        .description("Shows your workout days for the current month.") // Restore description
        // Restore the families you want to support
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Restore your Preview if you had one
#Preview(as: .systemMedium) {
    WorkoutCalendarWidget()
} timeline: {
    SimpleEntry(date: Date(), currentMonthDate: Date(), workoutDays: [1, 5, 15, 22])
}
