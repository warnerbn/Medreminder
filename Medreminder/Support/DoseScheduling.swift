import Foundation

enum DoseScheduling {
    static let intervalInDays = 14

    static func nextDueDate(after takenAt: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: intervalInDays, to: takenAt)
            ?? takenAt.addingTimeInterval(TimeInterval(intervalInDays * 86_400))
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
