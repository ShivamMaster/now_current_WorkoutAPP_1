import SwiftUI

// MARK: - Workout List Entry Point
/// A wrapper view that serves as the root for the Workouts tab.
/// It currently displays the `SplitListView` as the primary interface for managing workout routines.
struct WorkoutListView: View {
    var body: some View {
        SplitListView()
    }
}

struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutListView()
            .environmentObject(DataManager.shared)
    }
}

// MARK: - Sync Status Indicator
/// A small UI component that displays the current synchronization state (synced/unsynced).
/// Typically used in toolbars to provide quick visual feedback to the user.
struct SyncStatusView: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        HStack(spacing: 6) {
            // Status dot: Orange for unsynced, Green for synced.
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