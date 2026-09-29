//
//  DoseEvent.swift
//  Medreminder
//

import Foundation
import SwiftData

@Model
final class DoseEvent {
    @Attribute(.unique) var id: UUID
    /// When the dose was taken. Editable to correct mistakes.
    var takenAt: Date
    /// When this entry was created (audit trail, never edited).
    var createdAt: Date
    /// Optional context, e.g. "took a day early - travel".
    var note: String?
    var medication: Medication?

    init(medication: Medication? = nil, takenAt: Date = .now, note: String? = nil) {
        self.id = UUID()
        self.medication = medication
        self.takenAt = takenAt
        self.createdAt = .now
        self.note = note
    }
}

// Single-medication logic used by HomeView until the Today tab is
// reworked for multiple medications (phase 6).
extension DoseEvent {
    /// Days between doses.
    static let intervalDays = 14

    /// When the next dose is due if this is the most recent one.
    var nextDueDate: Date {
        Calendar.current.date(byAdding: .day, value: Self.intervalDays, to: takenAt)!
    }
}
