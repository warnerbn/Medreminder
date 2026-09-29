//
//  DosesView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

struct DosesView: View {
    @Query private var medications: [Medication]

    var body: some View {
        NavigationStack {
            // Re-render every minute so hints like "Due today at 8:00 PM" flip to overdue.
            TimelineView(.everyMinute) { context in
                let now = context.date
                let groups = grouped(now: now)
                // Today always shows (with "Nothing due today") unless something is overdue.
                let showNothingDue = !medications.isEmpty && groups[.overdue] == nil && groups[.today] == nil
                let visible = DoseSection.allCases.filter {
                    groups[$0] != nil || ($0 == .today && showNothingDue)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)],
                              alignment: .leading, spacing: 16) {
                        ForEach(visible, id: \.self) { section in
                            Section {
                                if let items = groups[section] {
                                    ForEach(items) { medication in
                                        MedicationCard(medication: medication, now: now)
                                    }
                                } else {
                                    Label("Nothing due today", systemImage: "checkmark.circle")
                                        .foregroundStyle(.secondary)
                                }
                            } header: {
                                SectionHeader(section: section, showsDivider: section != visible.first)
                            }
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
            .navigationTitle("Doses")
        }
    }

    /// Medications by section, each soonest (or most overdue) first; empty sections are omitted.
    private func grouped(now: Date) -> [DoseSection: [Medication]] {
        let sorted = medications.sorted {
            ($0.nextDue(now: now) ?? .distantFuture) < ($1.nextDue(now: now) ?? .distantFuture)
        }
        return Dictionary(grouping: sorted) {
            DoseSection.section(due: $0.nextDue(now: now), lastTaken: $0.lastDose?.takenAt, now: now)
        }
    }
}

private struct SectionHeader: View {
    let section: DoseSection
    /// A rule above the heading separates this section from the one before it.
    let showsDivider: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsDivider {
                Divider()
                    .padding(.top, 12)
            }
            Text(section.title)
                .font(.title3.bold())
                .foregroundStyle(section == .overdue ? .red : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, showsDivider ? 0 : 8)
    }
}

private struct MedicationCard: View {
    @Environment(\.modelContext) private var modelContext
    let medication: Medication
    let now: Date

    @State private var isConfirmingEarly = false

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

            if isUnlocked(due: due) {
                Button(action: logDose) {
                    Label("Taken", systemImage: "checkmark.circle.fill")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
            } else if medication.lastDose != nil {
                // Done until the next dose unlocks: not a button, so it can't be tapped.
                Label {
                    Text("Taken")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .font(.title3.bold())
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel("Taken. Next dose not due yet.")
            } else {
                Button {} label: {
                    Text("Not due yet")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .disabled(true)
            }

            if let due, !isUnlocked(due: due),
               medication.schedule.canTakeEarly(forDue: due, now: now) {
                Button("Take early…") { isConfirmingEarly = true }
                    .font(.subheadline)
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity)
                    .confirmationDialog("Take \(medication.name) now?",
                                        isPresented: $isConfirmingEarly,
                                        titleVisibility: .visible) {
                        Button("Log Dose Now", action: logDose)
                    } message: {
                        Text(earlyMessage(due: due))
                    }
            }
        }
        .sensoryFeedback(.success, trigger: medication.doses.count)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private var lastTakenText: String {
        guard let last = medication.lastDose else { return "Not taken yet" }
        return "Last taken \(last.takenAt.formatted(.dateTime.weekday(.abbreviated).month().day().hour().minute()))"
    }

    /// The Taken button unlocks at the start of the due day, or at a later
    /// dose's own time on a day that already has a dose logged.
    private func isUnlocked(due: Date?) -> Bool {
        guard let due else { return false }
        let unlock = medication.schedule.unlockDate(forDue: due, takenDates: medication.doses.map(\.takenAt))
        return now >= unlock
    }

    private func earlyMessage(due: Date) -> String {
        let dueText = due.formatted(.dateTime.weekday(.wide).month(.wide).day().hour().minute())
        return medication.schedule.isFloating
            ? "It isn't due until \(dueText). The next dose will be counted from now."
            : "It isn't due until \(dueText). This logs that dose now."
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
    return DosesView()
        .modelContainer(container)
}

#Preview("Empty") {
    DosesView()
        .modelContainer(for: [Medication.self, DoseEvent.self], inMemory: true)
}
