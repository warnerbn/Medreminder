import SwiftUI
import SwiftData

@main
struct MedreminderApp: App {
    init() {
        NotificationManager.shared.requestAuthorizationIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: DoseEvent.self)
    }
}
