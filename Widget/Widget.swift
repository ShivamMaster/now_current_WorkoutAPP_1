import WidgetKit
import SwiftUI

// Minimal Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
}

// Minimal Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// Minimal View
struct WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text("Widget Loaded!")
            .containerBackground(.background, for: .widget)
    }
}

// Main Widget Structure (Keep your kind)
struct WorkoutCalendarWidget: Widget {
    let kind: String = "WorkoutCalendarWidget" // Keep this consistent

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Test Widget")
        .description("A simple test widget.")
        .supportedFamilies([.systemSmall]) // Simplify supported families temporarily
    }
}

// Ensure WidgetBundle is correct
// (Keep your WidgetBundle.swift as is)
