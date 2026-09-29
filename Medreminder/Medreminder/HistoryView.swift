//
//  HistoryView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DoseEvent.takenAt, order: .reverse) private var doses: [DoseEvent]
    @Query(sort: \Medication.name) private var medications: [Medication]

    /// Nil shows every medication.
    @State private var filter: Medication?
    @State private var editing: DoseEvent?

    var body: some View {
        NavigationStack {
            List {
                ForEach(days, id: \.day) { group in
                    Section(group.day.formatted(.dateTime.weekday(.wide).month(.wide).day().year())) {
                        ForEach(group.doses) { dose in
                            Button {
                                editing = dose
                            } label: {
                                DoseRow(dose: dose)
                            }
                            .tint(.primary)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.deleteDose(group.doses[index])
                            }
                            try? modelContext.save()
                        }
                    }
                }
            }
            .overlay {
                if filteredDoses.isEmpty {
                    ContentUnavailableView("No Doses", systemImage: "list.bullet",
                                           description: Text("Doses appear here when you tap Taken."))
                }
            }
            .navigationTitle("History")
            .toolbar {
                if medications.count > 1 {
                    Menu {
                        Picker("Medication", selection: $filter) {
                            Text("All Medications").tag(Medication?.none)
                            ForEach(medications) { medication in
                                Text(medication.name).tag(Optional(medication))
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: filter == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .sheet(item: $editing) { dose in
                DoseEditView(dose: dose)
            }
        }
    }

    private var filteredDoses: [DoseEvent] {
        guard let filter else { return doses }
        return doses.filter { $0.medication == filter }
    }

    /// Doses grouped by calendar day, newest day first.
    private var days: [(day: Date, doses: [DoseEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredDoses) { calendar.startOfDay(for: $0.takenAt) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0]!) }
    }
}

private struct DoseRow: View {
    let dose: DoseEvent

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dose.medication?.name ?? "Unknown medication")
                    .font(.headline)
                if let note = dose.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(dose.takenAt, format: .dateTime.hour().minute())
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Medication.self, DoseEvent.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let shot = Medication(name: "Biweekly shot", frequency: .weekly, weekInterval: 2, countsFromLastDose: true)
    let vitamin = Medication(name: "Vitamin D", frequency: .daily, doseTimes: [8 * 60, 20 * 60])
    container.mainContext.insert(shot)
    container.mainContext.insert(vitamin)
    container.mainContext.insert(DoseEvent(medication: shot, takenAt: .now.addingTimeInterval(-14 * 86_400),
                                           note: "Took a day early - travel"))
    container.mainContext.insert(DoseEvent(medication: vitamin, takenAt: .now.addingTimeInterval(-3_600)))
    container.mainContext.insert(DoseEvent(medication: vitamin, takenAt: .now.addingTimeInterval(-86_400)))
    return HistoryView()
        .modelContainer(container)
}
