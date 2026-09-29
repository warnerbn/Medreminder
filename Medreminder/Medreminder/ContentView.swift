//
//  ContentView.swift
//  Medreminder
//
//  Created by Brian Warner on 9/29/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Medication.createdAt) private var medications: [Medication]
    @Query(sort: \DoseEvent.takenAt) private var doses: [DoseEvent]

    var body: some View {
        TabView {
            Tab("Doses", systemImage: "pills") {
                DosesView()
            }
            Tab("History", systemImage: "list.bullet") {
                HistoryView()
            }
            Tab("Medications", systemImage: "cross.vial") {
                MedicationsView()
            }
        }
        // Reschedule reminders on launch and whenever a medication or dose changes...
        .task(id: reminderSignature) {
            await NotificationScheduler.reschedule(medications)
        }
        // ...and when returning to the app, so the look-ahead window keeps moving.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await NotificationScheduler.reschedule(medications) }
            }
        }
    }

    /// Changes whenever anything that affects reminder times changes.
    private var reminderSignature: Int {
        var hasher = Hasher()
        for medication in medications {
            hasher.combine(medication.id)
            hasher.combine(medication.name)
            hasher.combine(medication.frequency)
            hasher.combine(medication.doseTimes)
            hasher.combine(medication.startDate)
            hasher.combine(medication.weekdays)
            hasher.combine(medication.weekInterval)
            hasher.combine(medication.countsFromLastDose)
        }
        for dose in doses {
            hasher.combine(dose.id)
            hasher.combine(dose.takenAt)
            hasher.combine(dose.medication?.id)
        }
        return hasher.finalize()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DoseEvent.self, inMemory: true)
}
