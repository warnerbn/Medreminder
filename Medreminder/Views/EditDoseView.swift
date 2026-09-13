import SwiftUI
import SwiftData

struct EditDoseView: View {
    @Bindable var dose: DoseEvent

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DoseEvent.takenAt, order: .reverse) private var allDoses: [DoseEvent]

    var body: some View {
        Form {
            DatePicker("Taken at", selection: $dose.takenAt, displayedComponents: [.date, .hourAndMinute])

            TextField(
                "Note (optional)",
                text: Binding(
                    get: { dose.note ?? "" },
                    set: { dose.note = $0.isEmpty ? nil : $0 }
                )
            )

            Button("Delete entry", role: .destructive, action: deleteEntry)
        }
        .navigationTitle("Edit dose")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
            }
        }
    }

    private func save() {
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
