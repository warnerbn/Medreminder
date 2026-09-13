import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let reminderIdentifier = "medreminder.dueNotification"

    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    /// Recomputes the next due date from the most recent dose (if any) and reschedules
    /// the single reminder notification, cancelling any previously scheduled one.
    func reschedule(mostRecentDose: Date?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        guard let mostRecentDose,
              let fireDate = DoseScheduling.reminderFireDate(forDoseTakenAt: mostRecentDose)
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "Medication due"
        content.body = "Time to take your medication."
        content.sound = .default

        let fireComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        center.add(request)
    }
}
