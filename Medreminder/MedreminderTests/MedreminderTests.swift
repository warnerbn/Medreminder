//
//  MedreminderTests.swift
//  MedreminderTests
//
//  Created by Brian Warner on 9/29/26.
//

import Foundation
import Testing
@testable import Medreminder

/// Fixed calendar and time zone so results don't depend on the machine running the tests.
private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Chicago")!
    return calendar
}()

/// Parses "yyyy-MM-dd HH:mm" in the test calendar's time zone.
private func date(_ string: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.date(from: string)!
}

@MainActor
struct DailyScheduleTests {
    // 2x daily at 8:00 AM and 8:00 PM (deliberately unsorted), starting Tue Sep 1.
    let schedule = DoseSchedule(frequency: .daily, doseTimes: [20 * 60, 8 * 60],
                                startDate: date("2026-09-01 00:00"))

    @Test func firstSlotOfTheDay() {
        let due = schedule.nextDue(takenDates: [], now: date("2026-09-29 07:00"), calendar: calendar)
        #expect(due == date("2026-09-29 08:00"))
    }

    @Test func secondSlotAfterMorningDose() {
        let due = schedule.nextDue(takenDates: [date("2026-09-29 08:05")],
                                   now: date("2026-09-29 09:00"), calendar: calendar)
        #expect(due == date("2026-09-29 20:00"))
    }

    @Test func nextDayWhenBothDosesTaken() {
        let due = schedule.nextDue(takenDates: [date("2026-09-29 08:05"), date("2026-09-29 20:01")],
                                   now: date("2026-09-29 21:00"), calendar: calendar)
        #expect(due == date("2026-09-30 08:00"))
    }

    @Test func overdueWhenSlotPassedUntaken() {
        let due = schedule.nextDue(takenDates: [], now: date("2026-09-29 12:00"), calendar: calendar)
        #expect(due == date("2026-09-29 08:00"))
    }

    @Test func futureStartDate() {
        let due = schedule.nextDue(takenDates: [], now: date("2026-08-20 10:00"), calendar: calendar)
        #expect(due == date("2026-09-01 08:00"))
    }

    @Test func upcomingWalksThroughSlots() {
        let upcoming = schedule.upcoming(count: 3, takenDates: [], now: date("2026-08-20 10:00"),
                                         calendar: calendar)
        #expect(upcoming == [date("2026-09-01 08:00"), date("2026-09-01 20:00"), date("2026-09-02 08:00")])
    }
}

@MainActor
struct WeeklyFixedScheduleTests {
    // Tuesdays and Fridays at 9:00 AM, every 2 weeks, starting Tue Sep 1.
    let schedule = DoseSchedule(frequency: .weekly, doseTimes: [9 * 60],
                                startDate: date("2026-09-01 00:00"),
                                weekdays: [3, 6], weekInterval: 2)

    @Test func upcomingSkipsOffWeeks() {
        let upcoming = schedule.upcoming(count: 5, takenDates: [], now: date("2026-08-31 10:00"),
                                         calendar: calendar)
        #expect(upcoming == [date("2026-09-01 09:00"), date("2026-09-04 09:00"),
                             date("2026-09-15 09:00"), date("2026-09-18 09:00"),
                             date("2026-09-29 09:00")])
    }

    @Test func missedDoseIsOverdue() {
        let due = schedule.nextDue(takenDates: [date("2026-09-01 09:00")],
                                   now: date("2026-09-06 10:00"), calendar: calendar)
        #expect(due == date("2026-09-04 09:00"))
    }

    @Test func coveredWeekMovesToNextOnWeek() {
        let due = schedule.nextDue(takenDates: [date("2026-09-01 09:00"), date("2026-09-04 09:00")],
                                   now: date("2026-09-13 10:00"), calendar: calendar)
        #expect(due == date("2026-09-15 09:00"))
    }

    @Test func noWeekdaysMeansNeverDue() {
        var empty = schedule
        empty.weekdays = []
        #expect(empty.nextDue(takenDates: [], now: date("2026-09-01 10:00"), calendar: calendar) == nil)
    }
}

@MainActor
struct FloatingScheduleTests {
    // Every 2 weeks from the last dose at 9:00 AM — the original 14-day medication.
    let biweekly = DoseSchedule(frequency: .weekly, doseTimes: [9 * 60],
                                startDate: date("2026-09-29 00:00"),
                                weekInterval: 2, countsFromLastDose: true)

    @Test func firstDoseIsStartDate() {
        #expect(biweekly.nextDue(takenDates: [], calendar: calendar) == date("2026-09-29 09:00"))
    }

    @Test func countsFromLastDoseDay() {
        let due = biweekly.nextDue(takenDates: [date("2026-09-03 09:00"), date("2026-09-17 13:52")],
                                   calendar: calendar)
        #expect(due == date("2026-10-01 09:00"))
    }

    @Test func shiftsWithLateDose() {
        // Taken two days late while traveling: next due shifts with it.
        let due = biweekly.nextDue(takenDates: [date("2026-10-03 18:00")], calendar: calendar)
        #expect(due == date("2026-10-17 09:00"))
    }

    @Test func monthlyClampsToEndOfShortMonth() {
        let monthly = DoseSchedule(frequency: .monthly, doseTimes: [9 * 60],
                                   startDate: date("2026-01-31 00:00"))
        let due = monthly.nextDue(takenDates: [date("2026-01-31 09:00")], calendar: calendar)
        #expect(due == date("2026-02-28 09:00"))
    }

    @Test func multiDoseDayFinishesBeforeFloating() {
        let monthly2x = DoseSchedule(frequency: .monthly, doseTimes: [8 * 60, 20 * 60],
                                     startDate: date("2026-09-01 00:00"))
        let midDay = monthly2x.nextDue(takenDates: [date("2026-09-10 08:00")], calendar: calendar)
        #expect(midDay == date("2026-09-10 20:00"))
        let done = monthly2x.nextDue(takenDates: [date("2026-09-10 08:00"), date("2026-09-10 20:00")],
                                     calendar: calendar)
        #expect(done == date("2026-10-10 08:00"))
    }
}

@MainActor
struct DueHintTests {
    let now = date("2026-09-29 12:00")

    @Test(arguments: [
        ("2026-09-29 20:00", "Due today at 8:00 PM"),
        ("2026-09-29 08:00", "Overdue since 8:00 AM"),
        ("2026-09-30 09:00", "Tomorrow at 9:00 AM"),
        ("2026-10-05 09:00", "In 6 days"),
        ("2026-09-28 09:00", "Overdue by 1 day"),
        ("2026-09-26 09:00", "Overdue by 3 days"),
    ])
    func hintText(due: String, expected: String) {
        let text = DueHint.text(for: date(due), now: now, calendar: calendar)
        // Normalize the narrow no-break space some locales put before AM/PM.
        #expect(text.replacingOccurrences(of: "\u{202F}", with: " ") == expected)
    }
}

@MainActor
struct ScheduleSummaryTests {
    private func summary(_ schedule: DoseSchedule) -> String {
        schedule.summary(calendar: calendar).replacingOccurrences(of: "\u{202F}", with: " ")
    }

    @Test func dailyTwiceADay() {
        let schedule = DoseSchedule(frequency: .daily, doseTimes: [20 * 60, 8 * 60], startDate: .now)
        #expect(summary(schedule) == "Daily · 2x at 8:00 AM, 8:00 PM")
    }

    @Test func weeklyOnDays() {
        let schedule = DoseSchedule(frequency: .weekly, doseTimes: [9 * 60], startDate: .now,
                                    weekdays: [6, 3], weekInterval: 2)
        #expect(summary(schedule) == "Every 2 weeks on Tue, Fri · 1x at 9:00 AM")
    }

    @Test func weeklyFromLastDose() {
        let schedule = DoseSchedule(frequency: .weekly, doseTimes: [9 * 60], startDate: .now,
                                    weekInterval: 2, countsFromLastDose: true)
        #expect(summary(schedule) == "Every 2 weeks, from last dose · 1x at 9:00 AM")
    }

    @Test func monthly() {
        let schedule = DoseSchedule(frequency: .monthly, doseTimes: [9 * 60], startDate: .now)
        #expect(summary(schedule) == "Monthly, from last dose · 1x at 9:00 AM")
    }
}

@MainActor
struct UnlockTests {
    let daily2x = DoseSchedule(frequency: .daily, doseTimes: [8 * 60, 20 * 60],
                               startDate: date("2026-09-01 00:00"))

    @Test func firstDoseOfDayUnlocksAtMidnight() {
        let due = date("2026-09-30 08:00")
        let unlock = daily2x.unlockDate(forDue: due, takenDates: [date("2026-09-29 20:00")], calendar: calendar)
        #expect(unlock == date("2026-09-30 00:00"))
    }

    @Test func laterDoseUnlocksAtItsTime() {
        let due = date("2026-09-29 20:00")
        let unlock = daily2x.unlockDate(forDue: due, takenDates: [date("2026-09-29 08:00")], calendar: calendar)
        #expect(unlock == due)
    }

    @Test func biweeklyUnlocksOnDueDay() {
        let biweekly = DoseSchedule(frequency: .weekly, doseTimes: [9 * 60], startDate: date("2026-09-01 00:00"),
                                    weekInterval: 2, countsFromLastDose: true)
        let taken = [date("2026-09-17 13:52")]
        let due = biweekly.nextDue(takenDates: taken, calendar: calendar)!
        #expect(biweekly.unlockDate(forDue: due, takenDates: taken, calendar: calendar) == date("2026-10-01 00:00"))
    }
}

@MainActor
struct TakeEarlyTests {
    @Test func floatingCanTakeEarlyOnAnotherDay() {
        let biweekly = DoseSchedule(frequency: .weekly, doseTimes: [9 * 60], startDate: date("2026-09-01 00:00"),
                                    weekInterval: 2, countsFromLastDose: true)
        #expect(biweekly.canTakeEarly(forDue: date("2026-10-01 09:00"), now: date("2026-09-30 18:00"),
                                      calendar: calendar))
    }

    @Test func fixedCanTakeEarlyOnlySameDay() {
        let daily2x = DoseSchedule(frequency: .daily, doseTimes: [8 * 60, 20 * 60],
                                   startDate: date("2026-09-01 00:00"))
        #expect(daily2x.canTakeEarly(forDue: date("2026-09-29 20:00"), now: date("2026-09-29 19:30"),
                                     calendar: calendar))
        #expect(!daily2x.canTakeEarly(forDue: date("2026-09-30 08:00"), now: date("2026-09-29 21:00"),
                                      calendar: calendar))
    }
}
