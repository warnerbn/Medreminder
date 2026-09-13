import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DoseEvent.takenAt, order: .reverse) private var doses: [DoseEvent]

    var body: some View {
        NavigationStack {
            Group {
                if doses.isEmpty {
                    ContentUnavailableView("No doses logged yet", systemImage: "clock")
                } else {
                    List {
                        ForEach(doses) { dose in
                            NavigationLink(value: dose) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(DoseDateFormatter.full.string(from: dose.takenAt))
                                        .font(.body)
                                    if let note = dose.note, !note.isEmpty {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: DoseEvent.self) { dose in
                EditDoseView(dose: dose)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let remaining = doses.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for index in offsets {
            modelContext.delete(doses[index])
        }
        try? modelContext.save()

        NotificationManager.shared.reschedule(mostRecentDose: remaining.map(\.takenAt).max())
    }
}
