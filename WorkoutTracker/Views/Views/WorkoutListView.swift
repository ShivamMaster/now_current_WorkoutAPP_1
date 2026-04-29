import SwiftUI

// WorkoutListView now wraps SplitListView as the main workout tab entry point
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

// MARK: - Sync Status Indicator (used in SplitListView toolbar)
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