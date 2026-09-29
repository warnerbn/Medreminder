//
//  ContentView.swift
//  Medreminder
//
//  Created by Brian Warner on 9/29/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "pills") {
                HomeView()
            }
            Tab("History", systemImage: "list.bullet") {
                HistoryView()
            }
            Tab("Medications", systemImage: "cross.vial") {
                MedicationsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DoseEvent.self, inMemory: true)
}
