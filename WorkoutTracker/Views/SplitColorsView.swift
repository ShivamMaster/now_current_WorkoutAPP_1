import SwiftUI

// MARK: - Split Colors Customization View
/// Allows users to personalize the colors associated with their workout splits.
/// These colors are used throughout the app, most prominently in the Calendar.
struct SplitColorsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Form {
            Section(header: Text("Multiple Splits"), footer: Text("This color represents days where you perform workouts from more than one split.")) {
                ColorPicker("Multiple Splits Color", selection: $themeManager.multipleSplitsColor)
            }

            Section(header: Text("Defined Splits"), footer: Text("Set a color for each of your specific workout splits. These colors will appear on the calendar.")) {
                if dataManager.splits.isEmpty {
                    Text("No splits defined yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(dataManager.splits) { split in
                        ColorPicker(split.name, selection: Binding(
                            get: { themeManager.splitColors[split.id.uuidString] ?? themeManager.calendarBoxColor },
                            set: { themeManager.splitColors[split.id.uuidString] = $0 }
                        ))
                    }
                }
            }
        }
        .navigationTitle("Split Colors")
    }
}
