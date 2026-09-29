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
}

#Preview {
    HomeView()
        .modelContainer(for: DoseEvent.self, inMemory: true)
}
