//
//  HomeView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DoseEvent.takenAt, order: .reverse) private var doses: [DoseEvent]

    private var lastDose: DoseEvent? { doses.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                Button(action: logDose) {
                    Label("Taken", systemImage: "checkmark.circle.fill")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 24))
                .sensoryFeedback(.success, trigger: doses.count)

                if let lastDose {
                    VStack(spacing: 6) {
                        Text("Last taken")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(lastDose.takenAt,
                             format: .dateTime.weekday(.wide).month(.wide).day().hour().minute())
                            .font(.title2)
                    }

                    VStack(spacing: 6) {
                        Text("Next due")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(lastDose.nextDueDate,
                             format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.title2)
                        Text(dueHint(for: lastDose.nextDueDate))
                            .font(.subheadline.bold())
                            .foregroundStyle(isOverdue(lastDose.nextDueDate) ? .red : .secondary)
                    }
                } else {
                    Text("No doses logged yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: 500)
            .navigationTitle("Today")
        }
    }

    private func logDose() {
        modelContext.insert(DoseEvent())
    }

    /// Whole calendar days from today until `date` (negative if past).
    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day],
                                       from: calendar.startOfDay(for: .now),
                                       to: calendar.startOfDay(for: date)).day ?? 0
    }

    private func isOverdue(_ date: Date) -> Bool {
        daysUntil(date) < 0
    }

    private func dueHint(for date: Date) -> String {
        switch daysUntil(date) {
        case 0: "Due today"
        case 1: "Tomorrow"
        case let days where days > 1: "In \(days) days"
        case -1: "Overdue by 1 day"
        case let days: "Overdue by \(-days) days"
        }
    }
}

#Preview("No doses") {
    HomeView()
        .modelContainer(for: DoseEvent.self, inMemory: true)
}

#Preview("Overdue") {
    let container = try! ModelContainer(for: DoseEvent.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(DoseEvent(takenAt: .now.addingTimeInterval(-16 * 86_400)))
    return HomeView()
        .modelContainer(container)
}
