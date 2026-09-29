//
//  NotificationScheduler.swift
//  Medreminder
//

import Foundation
import UIKit
import UserNotifications

struct PlannedReminder: Equatable {
    let identifier: String
    let medicationName: String
    let date: Date
}

/// Decides which local notifications to schedule. Pure, so it can be tested.
enum ReminderPlanner {
    struct Input {
        let id: String
        let name: String
        let schedule: DoseSchedule
        let takenDates: [Date]
    }

    /// Reminders scheduled ahead per medication.
    static let perMedication = 8
    /// iOS keeps at most 64 pending notifications per app.
    static let totalLimit = 60

    /// The soonest future dose times across all medications, assuming each
    /// dose is taken on time. Rescheduling after every change keeps it accurate.
    static func plan(_ inputs: [Input], now: Date = .now, calendar: Calendar = .current) -> [PlannedReminder] {
        let reminders = inputs.flatMap { input in
            input.schedule
                .upcoming(count: perMedication, takenDates: input.takenDates, now: now, calendar: calendar)
                .filter { $0 > now }
                .map { date in
                    PlannedReminder(identifier: "\(input.id)-\(Int(date.timeIntervalSince1970))",
                                    medicationName: input.name,
                                    date: date)
                }
        }
        return Array(reminders.sorted { $0.date < $1.date }.prefix(totalLimit))
    }
}

enum NotificationScheduler {
    /// Replaces every pending reminder with a fresh plan for `medications`.
    /// Asks for notification permission the first time (no prompt after that).
    static func reschedule(_ medications: [Medication]) async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])

        let inputs = medications.map {
            ReminderPlanner.Input(id: $0.id.uuidString, name: $0.name,
                                  schedule: $0.schedule, takenDates: $0.doses.map(\.takenAt))
        }
        let reminders = ReminderPlanner.plan(inputs)

        center.removeAllPendingNotificationRequests()
        for reminder in reminders {
            // A newer reschedule has started; let it finish instead.
            guard !Task.isCancelled else { return }

            let content = UNMutableNotificationContent()
            content.title = reminder.medicationName
            content.body = "Time to take \(reminder.medicationName)."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                             from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.identifier,
                                                        content: content, trigger: trigger))
        }
    }
}

/// Shows reminders as banners even while the app is open.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
