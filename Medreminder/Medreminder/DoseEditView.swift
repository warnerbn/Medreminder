//
//  DoseEditView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

/// Correct the date/time or note of a logged dose, or delete it.
struct DoseEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dose: DoseEvent

    @State private var takenAt: Date
    @State private var note: String
    @State private var isConfirmingDelete = false

    init(dose: DoseEvent) {
        self.dose = dose
        _takenAt = State(initialValue: dose.takenAt)
        _note = State(initialValue: dose.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Medication", value: dose.medication?.name ?? "Unknown")
                    DatePicker("Taken", selection: $takenAt, in: ...Date.now)
                }

                Section("Note") {
                    TextField("e.g. took a day early - travel", text: $note, axis: .vertical)
                }

                Section {
                    Button("Delete Dose", role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .frame(maxWidth: .infinity)
                } footer: {
                    Text("Logged \(dose.createdAt.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .navigationTitle("Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .interactiveDismissDisabled()
            .confirmationDialog("Delete this dose?", isPresented: $isConfirmingDelete,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(dose)
                    dismiss()
                }
            }
        }
    }

    private func save() {
        dose.takenAt = takenAt
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        dose.note = trimmed.isEmpty ? nil : trimmed
        dismiss()
    }
}
