import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \DoseEvent.takenAt, order: .reverse) private var doses: [DoseEvent]

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
        }
        .task { rearmReminder() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            rearmReminder()
        }
    }

    // Repairs a reminder lost to a late permission grant, a restore, or a fired one-shot.
    private func rearmReminder() {
        NotificationManager.shared.reschedule(mostRecentDose: doses.first?.takenAt)
    }
}
