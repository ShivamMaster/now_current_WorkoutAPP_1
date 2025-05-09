import WidgetKit
import SwiftUI
import CoreData // Import CoreData

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
        // Use Calendar.current consistently
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let workoutDays = fetchWorkoutDays(for: startOfMonth) // Fetch data using the updated function

        let entry = SimpleEntry(date: currentDate, currentMonthDate: startOfMonth, workoutDays: workoutDays)

        // Calculate next update time (e.g., start of next day)
        let nextUpdateDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: currentDate))!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }

    // Updated function to fetch directly from Core Data
    private func fetchWorkoutDays(for month: Date) -> Set<Int> {
        print("WIDGET DEBUG: Starting fetchWorkoutDays for month: \(month)")
        
        guard let context = getSharedManagedObjectContext() else {
            print("WIDGET DEBUG: Failed to get shared Core Data context.")
            return []
        }
        print("WIDGET DEBUG: Got shared context successfully")

        let calendar = Calendar.current
        let request: NSFetchRequest<WorkoutModel> = NSFetchRequest<WorkoutModel>(entityName: "Workout")

        // Create date range for the beginning and end of the month
        var components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components) else {
            print("WIDGET DEBUG: Could not calculate start of month.")
            return []
        }
        
        // Calculate end of month more reliably - Split into two guards
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
             print("WIDGET DEBUG: Could not calculate next month.")
             return []
        }
        // Calculate the actual last day of the target month
        guard let endOfMonthDate = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
            print("WIDGET DEBUG: Could not calculate end of month date from next month.")
            return []
        }
        
        // Adjust end of month to be the very end of the day for comparison
        let startOfDay = calendar.startOfDay(for: endOfMonthDate)
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            print("WIDGET DEBUG: Could not calculate start of the day after end of month.")
            return []
        }
        
        // Calculate end of day separately
        guard let endOfDayOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextDay) else {
             print("WIDGET DEBUG: Could not calculate end of day for end of month using alternative method.")
             return []
        }

        print("WIDGET DEBUG: Date range: \(startOfMonth) to \(endOfDayOfMonth)")

        // Filter workouts within the specified month
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfDayOfMonth as NSDate)

        do {
            // Perform fetch on the background context for safety in extensions
            let workoutsInMonth = try context.fetch(request)
            print("WIDGET DEBUG: Fetched \(workoutsInMonth.count) workouts")
            
            // Detailed logging of each workout
            for (index, workout) in workoutsInMonth.enumerated() {
                print("WIDGET DEBUG: Workout \(index): date = \(workout.date), name = \(workout.name)")
            }
            
            // let days = workoutsInMonth.compactMap { workout -> Int? in
            //     guard let date = workout.date else { return nil }
            //     let day = calendar.component(.day, from: date)
            //     print("WIDGET DEBUG: Extracted day \(day) from workout date \(date)")
            //     return day
            // }

            let days = workoutsInMonth.compactMap { workout -> Int? in
                let day = calendar.component(.day, from: workout.date) // Directly use workout.date
                print("WIDGET DEBUG: Extracted day \(day) from workout date \(workout.date)")
                return day
            }
            
            let daySet = Set(days)
            print("WIDGET DEBUG: Final workout days set: \(daySet)")
            return daySet
        } catch {
            print("WIDGET DEBUG: Error fetching workouts from Core Data: \(error.localizedDescription)")
            return []
        }
    }

    // Placeholder for the function that provides the shared context.
    // This needs proper implementation within the widget target.
    private func getSharedManagedObjectContext() -> NSManagedObjectContext? {
        print("WIDGET DEBUG: Initializing shared managed object context")
        
        // Create the container with your model name
        let container = NSPersistentContainer(name: "WorkoutTracker")
        
        // Get the URL for the shared App Group container
        guard let groupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.HiraGoel.WorkoutTracker") else {
            print("WIDGET DEBUG: Failed to get App Group container URL - check App Group configuration")
            return nil
        }
        
        print("WIDGET DEBUG: App Group container URL: \(groupContainerURL.path)")
        
        // Define the store URL within the App Group container
        let storeURL = groupContainerURL.appendingPathComponent("WorkoutTracker.sqlite")
        print("WIDGET DEBUG: Store URL: \(storeURL.path)")
        
        // Check if the database file exists
        let fileExists = FileManager.default.fileExists(atPath: storeURL.path)
        print("WIDGET DEBUG: Database file exists at path: \(fileExists)")
        
        // Configure the persistent store description
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        
        var context: NSManagedObjectContext? = nil
        var loadError: Error?
        
        // Use a semaphore to wait for the asynchronous loadPersistentStores to complete
        let semaphore = DispatchSemaphore(value: 0)
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("WIDGET DEBUG: Error loading shared persistent store: \(error)")
                print("WIDGET DEBUG: Store description: \(storeDescription)")
                loadError = error
            } else {
                print("WIDGET DEBUG: Successfully loaded persistent store")
                // Use a background context for better performance in extensions
                context = container.newBackgroundContext()
                context?.automaticallyMergesChangesFromParent = true
            }
            semaphore.signal() // Signal that loading is complete (or failed)
        }
        
        // Wait with timeout for the store to load
        _ = semaphore.wait(timeout: .now() + 10)
        
        if loadError != nil {
            print("WIDGET DEBUG: Persistent store loading failed within timeout")
            return nil
        }
        
        print("WIDGET DEBUG: Shared persistent store loaded successfully. Context available: \(context != nil)")
        return context
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
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.8)
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
        .padding(.vertical) // Removed horizontal padding, keep vertical
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
    let kind: String = "WorkoutCalendarWidget" // This must match the string used in WidgetCenter.reloadTimelines

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Workout Calendar")
        .description("Shows your workout days for the current month.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Restore your Preview if you had one
#Preview(as: .systemMedium) {
    WorkoutCalendarWidget()
} timeline: {
    SimpleEntry(date: Date(), currentMonthDate: Date(), workoutDays: [1, 5, 15, 22])
}

// Make sure your WorkoutModel class is available to the Widget target
// You might need to add the Core Data Model file (.xcdatamodeld) and the
// generated NSManagedObject subclass files to the Widget target's "Compile Sources"
// and "Copy Bundle Resources" build phases.


// MARK: - Motivational Quote Widget

// Entry for the motivational quote widget
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: String
    let author: String
}

// Provider for the motivational quote widget
struct QuoteProvider: TimelineProvider {
    private let appGroupID = "group.com.HiraGoel.WorkoutTracker"
    private let quoteKey = "dailyQuote"
    private let authorKey = "dailyQuoteAuthor"
    private let dateKey = "dailyQuoteDate"

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: "Loading...", author: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        loadQuote { quote, author in
            let entry = QuoteEntry(date: Date(), quote: quote, author: author)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        loadQuote { quote, author in
            let currentDate = Date()
            let calendar = Calendar.current
            let nextUpdateDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: currentDate))!
            let entry = QuoteEntry(date: currentDate, quote: quote, author: author)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }

    private func loadQuote(completion: @escaping (String, String) -> Void) {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let savedDate = userDefaults?.object(forKey: dateKey) as? Date,
           calendar.isDate(savedDate, inSameDayAs: today),
           let savedQuote = userDefaults?.string(forKey: quoteKey),
           let savedAuthor = userDefaults?.string(forKey: authorKey) {
            // Use cached quote for today
            completion(savedQuote, savedAuthor)
        } else {
            // Fetch new quote from API
            fetchQuoteFromAPI { quote, author in
                // Save to UserDefaults for today
                userDefaults?.set(quote, forKey: quoteKey)
                userDefaults?.set(author, forKey: authorKey)
                userDefaults?.set(today, forKey: dateKey)
                completion(quote, author)
            }
        }
    }

    private func fetchQuoteFromAPI(completion: @escaping (String, String) -> Void) {
        guard let url = URL(string: "https://api.realinspire.live/v1/quotes/random?maxLength=120") else {
            completion("Stay motivated!", "Unknown")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let first = json.first,
               let quote = first["content"] as? String,
               let author = first["author"] as? String {
                completion(quote, author)
            } else {
                completion("Stay motivated!", "Unknown")
            }
        }
        task.resume()
    }
}

// View for the motivational quote widget
struct QuoteWidgetView: View {
    var entry: QuoteProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer(minLength: 4)

            // Quote text
            Text("\"\(entry.quote)\"")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .lineLimit(4) // Limit to 4 lines
                .minimumScaleFactor(0.6) // Allow text to shrink
                .padding(.horizontal, 8)

            Spacer(minLength: 2)

            // Author text
            Text("- \(entry.author)")
                .font(.system(size: 13, weight: .light, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1) // Limit to 1 line
                .minimumScaleFactor(0.7)
                .padding(.bottom, 6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

// Define the motivational quote widget
struct MotivationalQuoteWidget: Widget {
    let kind: String = "MotivationalQuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Workout Motivation")
        .description("Daily motivational quotes for your workout.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Preview for the motivational quote widget
#Preview(as: .systemSmall) {
    MotivationalQuoteWidget()
} timeline: {
    QuoteEntry(date: Date(), quote: "The body achieves what the mind believes.", author: "Napoleon Hill")
}

// MARK: - Widget Bundle

// REMOVE any @main struct or WidgetBundle from this file.
struct WorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutCalendarWidget()
        MotivationalQuoteWidget()
    }
}

// Restore your Preview if you had one
#Preview(as: .systemSmall) {
    WorkoutCalendarWidget()
} timeline: {
    SimpleEntry(date: Date(), currentMonthDate: Date(), workoutDays: [1, 5, 15, 22])
}

// Make sure your WorkoutModel class is available to the Widget target
// You might need to add the Core Data Model file (.xcdatamodeld) and the
// generated NSManagedObject subclass files to the Widget target's "Compile Sources"
// and "Copy Bundle Resources" build phases.
