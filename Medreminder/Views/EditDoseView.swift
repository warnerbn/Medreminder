import SwiftUI
import SwiftData

struct EditDoseView: View {
    let dose: DoseEvent

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DoseEvent.takenAt, order: .reverse) private var allDoses: [DoseEvent]

    @State private var takenAt: Date
    @State private var note: String

    init(dose: DoseEvent) {
        self.dose = dose
        _takenAt = State(initialValue: dose.takenAt)
        _note = State(initialValue: dose.note ?? "")
    }

    var body: some View {
        Form {
            DatePicker("Taken at", selection: $takenAt, displayedComponents: [.date, .hourAndMinute])

            TextField("Note (optional)", text: $note)

            Button("Delete entry", role: .destructive, action: deleteEntry)
        }
        .navigationTitle("Edit dose")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
            }
        }
    }

    private func save() {
        dose.takenAt = takenAt
        dose.note = note.isEmpty ? nil : note
        try? modelContext.save()
        NotificationManager.shared.reschedule(mostRecentDose: allDoses.map(\.takenAt).max())
        dismiss()
    }

    private func deleteEntry() {
        let remaining = allDoses.filter { $0.id != dose.id }
        modelContext.delete(dose)
        try? modelContext.save()
        NotificationManager.shared.reschedule(mostRecentDose: remaining.map(\.takenAt).max())
        dismiss()
    }
}
