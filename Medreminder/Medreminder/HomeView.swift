//
//  HomeView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

struct HomeView: View {
    var body: some View {
        NavigationStack {
            // Phase 2: "Taken" button and last-taken display.
            // Phase 3: next due date.
            ContentUnavailableView("Today", systemImage: "pills",
                                   description: Text("Dose logging coming in phase 2."))
                .navigationTitle("Today")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: DoseEvent.self, inMemory: true)
}
