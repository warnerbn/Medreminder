import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DoseEvent.takenAt, order: .reverse) private var doses: [DoseEvent]

    private var lastDose: DoseEvent? { doses.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Button(action: logDoseNow) {
                    Text("Taken")
                        .font(.largeTitle.bold())
                        .frame(width: 200, height: 200)
                        .background(Circle().fill(Color.accentColor))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 12) {
                    infoRow(
                        title: "Last taken",
                        value: lastDose.map { DoseDateFormatter.full.string(from: $0.takenAt) }
                            ?? "No doses logged yet"
                    )

                    if let lastDose {
                        let dueDate = DoseScheduling.nextDueDate(after: lastDose.takenAt)
                        infoRow(
                            title: "Next due",
                            value: "\(DoseDateFormatter.full.string(from: dueDate)) · \(DoseScheduling.relativeDueDescription(for: dueDate))"
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Medreminder")
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
    }

    private func logDoseNow() {
        let event = DoseEvent(takenAt: Date())
        modelContext.insert(event)
        try? modelContext.save()
        NotificationManager.shared.reschedule(mostRecentDose: event.takenAt)
    }
}
