//
//  MedicationFormView.swift
//  Medreminder
//

import SwiftUI
import SwiftData

/// Add a new medication, or edit an existing one when `medication` is set.
struct MedicationFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let medication: Medication?

    @State private var name: String
    @State private var frequency: Frequency
    @State private var doseTimes: [Date]
    @State private var startDate: Date
    @State private var weekdays: Set<Int>
    @State private var weekInterval: Int
    @State private var countsFromLastDose: Bool

    init(medication: Medication? = nil) {
        self.medication = medication
        _name = State(initialValue: medication?.name ?? "")
        _frequency = State(initialValue: medication?.frequency ?? .daily)
        _doseTimes = State(initialValue: (medication?.doseTimes ?? Self.defaultTimes(count: 1)).map(Self.date(fromMinutes:)))
        _startDate = State(initialValue: medication?.startDate ?? .now)
        _weekdays = State(initialValue: Set(medication?.weekdays ?? []))
        _weekInterval = State(initialValue: medication?.weekInterval ?? 1)
        _countsFromLastDose = State(initialValue: medication?.countsFromLastDose ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section {
                    Picker("How often", selection: $frequency) {
                        ForEach(Frequency.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)

                    if frequency == .weekly {
                        Picker("Repeat", selection: $weekInterval) {
                            ForEach(1...4, id: \.self) { n in
                                Text(n == 1 ? "Every week" : "Every \(n) weeks").tag(n)
                            }
                        }
                        Toggle("Count from last dose", isOn: $countsFromLastDose)
                        if !countsFromLastDose {
                            WeekdayPicker(selection: $weekdays)
                        }
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    if let scheduleFooter {
                        Text(scheduleFooter)
                    }
                }

                Section("Times per day") {
                    Picker("Times per day", selection: dosesPerDay) {
                        ForEach(1...4, id: \.self) { Text("\($0)x").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    ForEach(doseTimes.indices, id: \.self) { index in
                        DatePicker(doseTimes.count == 1 ? "Time" : "Dose \(index + 1)",
                                   selection: $doseTimes[index],
                                   displayedComponents: .hourAndMinute)
                    }
                }

                Section(draftSchedule.isFloating ? "First dose" : "Start date") {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }

                Section("Next doses") {
                    if upcoming.isEmpty {
                        Text("Pick at least one day of the week.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(upcoming, id: \.self) { date in
                            Text(date, format: .dateTime.weekday(.abbreviated).month().day().hour().minute())
                        }
                    }
                }
            }
            .navigationTitle(medication == nil ? "New Medication" : "Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .onChange(of: countsFromLastDose) { _, counts in
                // Start fixed weekly schedules on the start date's weekday.
                if !counts && weekdays.isEmpty {
                    weekdays = [Calendar.current.component(.weekday, from: startDate)]
                }
            }
            .onChange(of: frequency) { _, newFrequency in
                if newFrequency == .weekly && !countsFromLastDose && weekdays.isEmpty {
                    weekdays = [Calendar.current.component(.weekday, from: startDate)]
                }
            }
        }
    }

    // MARK: - Derived state

    /// Changing the count resets the times to sensible defaults for that count.
    private var dosesPerDay: Binding<Int> {
        Binding(get: { doseTimes.count },
                set: { doseTimes = Self.defaultTimes(count: $0).map(Self.date(fromMinutes:)) })
    }

    private var doseMinutes: [Int] {
        doseTimes.map { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }.sorted()
    }

    private var draftSchedule: DoseSchedule {
        DoseSchedule(frequency: frequency,
                     doseTimes: doseMinutes,
                     startDate: startDate,
                     weekdays: weekdays,
                     weekInterval: weekInterval,
                     countsFromLastDose: countsFromLastDose)
    }

    private var upcoming: [Date] {
        draftSchedule.upcoming(count: 4, takenDates: medication?.doses.map(\.takenAt) ?? [])
    }

    private var scheduleFooter: String? {
        switch frequency {
        case .daily:
            return nil
        case .weekly where countsFromLastDose:
            let span = weekInterval == 1 ? "1 week" : "\(weekInterval) weeks"
            return "The next dose is due \(span) after the last one you log, so it shifts if you take it early or late."
        case .weekly:
            return nil
        case .monthly:
            return "The next dose is due 1 month after the last one you log."
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !(frequency == .weekly && !countsFromLastDose && weekdays.isEmpty)
    }

    // MARK: - Actions

    private func save() {
        let target = medication ?? Medication(name: "")
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.frequency = frequency
        target.doseTimes = doseMinutes
        target.startDate = Calendar.current.startOfDay(for: startDate)
        target.weekdays = weekdays.sorted()
        target.weekInterval = weekInterval
        target.countsFromLastDose = countsFromLastDose
        if medication == nil {
            modelContext.insert(target)
        }
        dismiss()
    }

    // MARK: - Helpers

    nonisolated private static func defaultTimes(count: Int) -> [Int] {
        switch count {
        case 1: [9 * 60]
        case 2: [8 * 60, 20 * 60]
        case 3: [8 * 60, 14 * 60, 20 * 60]
        default: [8 * 60, 12 * 60, 16 * 60, 20 * 60]
        }
    }

    nonisolated private static func date(fromMinutes minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: Calendar.current.startOfDay(for: .now))!
    }
}

/// A row of toggleable day-of-week chips (S M T W T F S).
private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        let calendar = Calendar.current
        HStack(spacing: 6) {
            ForEach(DoseSchedule.orderedWeekdays(calendar: calendar), id: \.self) { weekday in
                let isOn = selection.contains(weekday)
                Button {
                    if isOn { selection.remove(weekday) } else { selection.insert(weekday) }
                } label: {
                    Text(calendar.veryShortWeekdaySymbols[weekday - 1])
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15),
                                    in: Circle())
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(calendar.weekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("New") {
    MedicationFormView()
        .modelContainer(for: [Medication.self, DoseEvent.self], inMemory: true)
}
