import Foundation
import SwiftData

@Model
final class DoseEvent {
    var takenAt: Date
    var createdAt: Date
    var note: String?

    init(takenAt: Date, note: String? = nil) {
        self.takenAt = takenAt
        self.createdAt = Date()
        self.note = note
    }
}
