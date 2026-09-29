//
//  HistoryView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            // Phase 5: list of all DoseEvents, newest first.
            ContentUnavailableView("History", systemImage: "list.bullet",
                                   description: Text("Dose history coming in phase 5."))
                .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: DoseEvent.self, inMemory: true)
}
