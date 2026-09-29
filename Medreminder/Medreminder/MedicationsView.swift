//
//  MedicationsView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]

    @State private var isAdding = false
    @State private var editing: Medication?
    @State private var pendingDelete: Medication?

    var body: some View {
        NavigationStack {
            List {
                ForEach(medications) { medication in
                    Button {
                        editing = medication
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(medication.name)
                                .font(.headline)
                            Text(medication.schedule.summary())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
                .onDelete { offsets in
                    pendingDelete = offsets.first.map { medications[$0] }
                }
            }
            .overlay {
                if medications.isEmpty {
                    ContentUnavailableView {
                        Label("No Medications", systemImage: "pills")
                    } description: {
                        Text("Add a medication to start tracking its doses.")
                    } actions: {
                        Button("Add Medication") { isAdding = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
            .sheet(isPresented: $isAdding) {
                MedicationFormView()
            }
            .sheet(item: $editing) { medication in
                MedicationFormView(medication: medication)
            }
            .confirmationDialog("Delete \(pendingDelete?.name ?? "medication")?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible,
                                presenting: pendingDelete) { medication in
                Button("Delete", role: .destructive) {
                    modelContext.delete(medication)
                }
            } message: { medication in
                Text(medication.doses.isEmpty
                     ? "This can't be undone."
                     : "Its \(medication.doses.count) logged doses will also be deleted. This can't be undone.")
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Medication.self, DoseEvent.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(Medication(name: "Biweekly shot", frequency: .weekly,
                                            weekInterval: 2, countsFromLastDose: true))
    container.mainContext.insert(Medication(name: "Vitamin D", frequency: .daily,
                                            doseTimes: [8 * 60, 20 * 60]))
    return MedicationsView()
        .modelContainer(container)
}
