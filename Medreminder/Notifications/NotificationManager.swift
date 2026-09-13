import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let reminderIdentifier = "medreminder.dueNotification"
    private let reminderHour = 9

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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        guard let mostRecentDose else { return }

        let dueDate = DoseScheduling.nextDueDate(after: mostRecentDose)

        var fireComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        fireComponents.hour = reminderHour
        fireComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Medication due"
        content.body = "Time to take your medication."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
