//
//  MedicationSchedule.swift
//  Medreminder
//

import Foundation

enum Frequency: String, Codable, CaseIterable, Identifiable {
    case daily, weekly, monthly

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

/// A medication's schedule as plain values, so due dates can be computed
/// (and tested, and previewed in the form) without SwiftData.
struct DoseSchedule {
    var frequency: Frequency
    /// Minutes after midnight, one per dose per day.
    var doseTimes: [Int]
    var startDate: Date
    /// Weekly fixed schedules: Calendar weekday numbers, 1 = Sunday ... 7 = Saturday.
    var weekdays: Set<Int> = []
    /// Weekly: every N weeks.
    var weekInterval: Int = 1
    /// Weekly: next due is counted from the last dose instead of fixed weekdays.
    var countsFromLastDose: Bool = false

    /// Monthly and weekly-from-last-dose schedules float with the last dose;
    /// daily and weekly-on-weekdays schedules are fixed to the calendar.
    var isFloating: Bool {
        frequency == .monthly || (frequency == .weekly && countsFromLastDose)
    }

    /// The next dose slot not yet covered by a logged dose. A slot on a day is
    /// covered when that day has at least (slot index + 1) doses logged.
    /// May be in the past (overdue). Nil if the schedule can never be due.
    func nextDue(takenDates: [Date], now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard !doseTimes.isEmpty else { return nil }
        return isFloating
            ? nextFloatingDue(takenDates: takenDates, calendar: calendar)
            : nextFixedDue(takenDates: takenDates, now: now, calendar: calendar)
    }

    /// When the Taken button unlocks for the dose due at `due`: the start of its
    /// day for a day's first dose (so it can be taken any time that day), or the
    /// dose's own time for a later dose on a day that already has one logged.
    func unlockDate(forDue due: Date, takenDates: [Date], calendar: Calendar = .current) -> Date {
        let dayStarted = takenDates.contains { calendar.isDate($0, inSameDayAs: due) }
        return dayStarted ? due : calendar.startOfDay(for: due)
    }

    /// Whether a dose logged now would count toward the dose due at `due`.
    /// Floating schedules restart from any dose; fixed schedules only count
    /// doses logged on the due day itself.
    func canTakeEarly(forDue due: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        isFloating || calendar.isDate(due, inSameDayAs: now)
    }

    /// The next `count` due slots, assuming each one is taken on time.
    func upcoming(count: Int, takenDates: [Date], now: Date = .now, calendar: Calendar = .current) -> [Date] {
        var taken = takenDates
        var result: [Date] = []
        for _ in 0..<count {
            guard let due = nextDue(takenDates: taken, now: now, calendar: calendar) else { break }
            result.append(due)
            taken.append(due)
        }
        return result
    }

    /// One-line description, e.g. "Every 2 weeks on Tue, Fri · 2x at 8:00 AM, 8:00 PM".
    func summary(calendar: Calendar = .current) -> String {
        let repeatText: String
        switch frequency {
        case .daily:
            repeatText = "Daily"
        case .weekly:
            let every = weekInterval > 1 ? "Every \(weekInterval) weeks" : "Every week"
            if countsFromLastDose {
                repeatText = "\(every), from last dose"
            } else {
                let days = Self.orderedWeekdays(calendar: calendar)
                    .filter { weekdays.contains($0) }
                    .map { calendar.shortWeekdaySymbols[$0 - 1] }
                    .joined(separator: ", ")
                repeatText = days.isEmpty ? every : "\(every) on \(days)"
            }
        case .monthly:
            repeatText = "Monthly, from last dose"
        }

        var timeStyle = Date.FormatStyle(date: .omitted, time: .shortened)
        timeStyle.timeZone = calendar.timeZone
        let today = calendar.startOfDay(for: .now)
        let times = doseTimes.sorted()
            .map { calendar.date(byAdding: .minute, value: $0, to: today)!.formatted(timeStyle) }
            .joined(separator: ", ")
        return "\(repeatText) · \(doseTimes.count)x at \(times)"
    }

    /// Weekday numbers (1 = Sunday) starting from the locale's first day of the week.
    static func orderedWeekdays(calendar: Calendar = .current) -> [Int] {
        (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
    }

    // MARK: - Fixed schedules

    private func nextFixedDue(takenDates: [Date], now: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: now)
        let lookBack = 7 * max(weekInterval, 1)

        // Most recent scheduled day on or before today: due/overdue if not fully covered.
        for offset in 0..<lookBack {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            guard isScheduled(day, calendar: calendar) else { continue }
            let taken = dosesTaken(on: day, takenDates: takenDates, calendar: calendar)
            if taken < doseTimes.count {
                return slots(on: day, calendar: calendar)[taken]
            }
            break
        }

        // Otherwise the first uncovered slot on a later scheduled day
        // (doses can already be logged ahead, e.g. by `upcoming`).
        for offset in 1...(366 + lookBack) {
            let day = calendar.date(byAdding: .day, value: offset, to: today)!
            guard isScheduled(day, calendar: calendar) else { continue }
            let taken = dosesTaken(on: day, takenDates: takenDates, calendar: calendar)
            if taken < doseTimes.count {
                return slots(on: day, calendar: calendar)[taken]
            }
        }
        return nil
    }

    private func isScheduled(_ day: Date, calendar: Calendar) -> Bool {
        guard day >= calendar.startOfDay(for: startDate) else { return false }
        switch frequency {
        case .daily:
            return true
        case .weekly:
            guard weekdays.contains(calendar.component(.weekday, from: day)),
                  let startWeek = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start,
                  let dayWeek = calendar.dateInterval(of: .weekOfYear, for: day)?.start,
                  let days = calendar.dateComponents([.day], from: startWeek, to: dayWeek).day
            else { return false }
            return (days / 7) % max(weekInterval, 1) == 0
        case .monthly:
            return false  // monthly always floats
        }
    }

    // MARK: - Floating schedules

    private func nextFloatingDue(takenDates: [Date], calendar: Calendar) -> Date? {
        guard let last = takenDates.max() else {
            return slots(on: calendar.startOfDay(for: startDate), calendar: calendar)[0]
        }
        let lastDay = calendar.startOfDay(for: last)
        let taken = dosesTaken(on: lastDay, takenDates: takenDates, calendar: calendar)
        if taken < doseTimes.count {
            return slots(on: lastDay, calendar: calendar)[taken]
        }
        let nextDay = frequency == .monthly
            ? calendar.date(byAdding: .month, value: 1, to: lastDay)!
            : calendar.date(byAdding: .day, value: 7 * max(weekInterval, 1), to: lastDay)!
        return slots(on: nextDay, calendar: calendar)[0]
    }

    // MARK: - Helpers

    /// The dose times on `day`, earliest first.
    private func slots(on day: Date, calendar: Calendar) -> [Date] {
        doseTimes.sorted().map { minutes in
            calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day)!
        }
    }

    private func dosesTaken(on day: Date, takenDates: [Date], calendar: Calendar) -> Int {
        takenDates.filter { calendar.isDate($0, inSameDayAs: day) }.count
    }
}

/// Human-readable status for a due date, e.g. "In 6 days" or "Overdue since 8:00 AM".
enum DueHint {
    static func isOverdue(_ due: Date, now: Date = .now) -> Bool {
        due < now
    }

    static func text(for due: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: due)).day ?? 0
        var timeStyle = Date.FormatStyle(date: .omitted, time: .shortened)
        timeStyle.timeZone = calendar.timeZone
        let time = due.formatted(timeStyle)
        switch days {
        case 0: return due >= now ? "Due today at \(time)" : "Overdue since \(time)"
        case 1: return "Tomorrow at \(time)"
        case let days where days > 1: return "In \(days) days"
        case -1: return "Overdue by 1 day"
        case let days: return "Overdue by \(-days) days"
        }
    }
}
