//
//  Medication.swift
//  Medreminder
//

import Foundation
import SwiftData

@Model
final class Medication {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var frequency: Frequency
    /// Minutes after midnight, one per dose per day (1–4 entries).
    var doseTimes: [Int]
    /// First possible due day.
    var startDate: Date
    /// Weekly fixed schedules: 1 = Sunday ... 7 = Saturday.
    var weekdays: [Int]
    /// Weekly: every N weeks.
    var weekInterval: Int
    /// Weekly: count from the last dose instead of fixed weekdays.
    var countsFromLastDose: Bool
    @Relationship(deleteRule: .cascade, inverse: \DoseEvent.medication)
    var doses: [DoseEvent] = []

    init(name: String,
         frequency: Frequency = .daily,
         doseTimes: [Int] = [9 * 60],
         startDate: Date = .now,
         weekdays: [Int] = [],
         weekInterval: Int = 1,
         countsFromLastDose: Bool = false) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.frequency = frequency
        self.doseTimes = doseTimes
        self.startDate = startDate
        self.weekdays = weekdays
        self.weekInterval = weekInterval
        self.countsFromLastDose = countsFromLastDose
    }
}

extension Medication {
    var dosesPerDay: Int { doseTimes.count }

    var schedule: DoseSchedule {
        DoseSchedule(frequency: frequency,
                     doseTimes: doseTimes,
                     startDate: startDate,
                     weekdays: Set(weekdays),
                     weekInterval: weekInterval,
                     countsFromLastDose: countsFromLastDose)
    }

    var lastDose: DoseEvent? {
        doses.max { $0.takenAt < $1.takenAt }
    }

    func nextDue(now: Date = .now) -> Date? {
        schedule.nextDue(takenDates: doses.map(\.takenAt), now: now)
    }
}
