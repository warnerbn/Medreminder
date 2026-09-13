import Foundation

enum DoseScheduling {
    static let intervalInDays = 14
    static let reminderHour = 9

    static func nextDueDate(after takenAt: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: intervalInDays, to: takenAt)
            ?? takenAt.addingTimeInterval(TimeInterval(intervalInDays * 86_400))
    }

    // A past-dated calendar trigger never fires, so a missed due morning moves to the next one.
    static func reminderFireDate(
        forDoseTakenAt takenAt: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        let dueDate = nextDueDate(after: takenAt)

        if let dueMorning = calendar.date(bySettingHour: reminderHour, minute: 0, second: 0, of: dueDate),
           dueMorning > now {
            return dueMorning
        }

        return calendar.nextDate(
            after: now,
            matching: DateComponents(hour: reminderHour, minute: 0),
            matchingPolicy: .nextTime
        )
    }

    static func relativeDueDescription(for dueDate: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDue = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfDue).day ?? 0

        switch days {
        case 0:
            return "Due today"
        case 1:
            return "Due tomorrow"
        case let d where d > 1:
            return "In \(d) days"
        case -1:
            return "Overdue by 1 day"
        default:
            return "Overdue by \(-days) days"
        }
    }
}

enum DoseDateFormatter {
    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
