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

    init(takenAt: Date = .now, note: String? = nil) {
        self.id = UUID()
        self.takenAt = takenAt
        self.createdAt = .now
        self.note = note
    }
}
