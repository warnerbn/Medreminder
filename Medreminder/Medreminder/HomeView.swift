//
//  HomeView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var medications: [Medication]

    var body: some View {
        NavigationStack {
            // Re-render every minute so hints like "Due today at 8:00 PM" flip to overdue.
            TimelineView(.everyMinute) { context in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                        ForEach(sorted(now: context.date)) { medication in
                            MedicationCard(medication: medication, now: context.date)
                        }
                    }
                    .padding()
                }
            }
            .overlay {
                if medications.isEmpty {
                    ContentUnavailableView("No Medications", systemImage: "pills",
                                           description: Text("Add a medication in the Medications tab."))
                }
            }
            .navigationTitle("Today")
        }
    }

    /// Soonest (or most overdue) first; medications that are never due go last.
    private func sorted(now: Date) -> [Medication] {
        medications.sorted {
            ($0.nextDue(now: now) ?? .distantFuture) < ($1.nextDue(now: now) ?? .distantFuture)
        }
    }
}

private struct MedicationCard: View {
    @Environment(\.modelContext) private var modelContext
    let medication: Medication
    let now: Date

    var body: some View {
        let due = medication.nextDue(now: now)

        VStack(alignment: .leading, spacing: 12) {
            Text(medication.name)
                .font(.title2.bold())

            if let due {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DueHint.text(for: due, now: now))
                        .font(.headline)
                        .foregroundStyle(DueHint.isOverdue(due, now: now) ? .red : .primary)
                    Text("Next due \(due.formatted(.dateTime.weekday(.wide).month(.wide).day().hour().minute()))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(lastTakenText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: logDose) {
                Label("Taken", systemImage: "checkmark.circle.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .sensoryFeedback(.success, trigger: medication.doses.count)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private var lastTakenText: String {
        guard let last = medication.lastDose else { return "Not taken yet" }
        return "Last taken \(last.takenAt.formatted(.dateTime.weekday(.abbreviated).month().day().hour().minute()))"
    }

    private func logDose() {
        modelContext.insert(DoseEvent(medication: medication))
    }
}

#Preview("Medications") {
    let container = try! ModelContainer(for: Medication.self, DoseEvent.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let shot = Medication(name: "Biweekly shot", frequency: .weekly, weekInterval: 2, countsFromLastDose: true)
    let vitamin = Medication(name: "Vitamin D", frequency: .daily, doseTimes: [8 * 60, 20 * 60])
    container.mainContext.insert(shot)
    container.mainContext.insert(vitamin)
    container.mainContext.insert(DoseEvent(medication: shot, takenAt: .now.addingTimeInterval(-16 * 86_400)))
    return HomeView()
        .modelContainer(container)
}

#Preview("Empty") {
    HomeView()
        .modelContainer(for: [Medication.self, DoseEvent.self], inMemory: true)
}
