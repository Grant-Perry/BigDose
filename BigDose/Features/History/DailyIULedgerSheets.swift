import SwiftData
import SwiftUI

struct DailySupplementLedgerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var allDoses: [SupplementDose]
    @State private var isAddingDose = false
    @State private var editingDose: SupplementDose?
    @State private var healthKitImportService = HealthKitImportService()
    var profile: UserProfile?

    private var calendar: Calendar { .current }

    private var todayDoses: [SupplementDose] {
        allDoses.filter { calendar.isDateInToday($0.takenAt) }
    }

    var body: some View {
        NavigationStack {
            List {
                if todayDoses.isEmpty {
                    ContentUnavailableView(
                        "No supplements today",
                        systemImage: "pills.fill",
                        description: Text("Add a dose to count it toward today's IU total.")
                    )
                } else {
                    ForEach(todayDoses) { dose in
                        Button {
                            editingDose = dose
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dose.takenAt.formatted(date: .omitted, time: .shortened))
                                        .font(.headline)

                                    if !dose.note.isEmpty {
                                        Text(dose.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Text("\(dose.internationalUnits) IU")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(.orange)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .bigDoseSwipeToDelete {
                            deleteSupplementDose(dose)
                        }
                    }
                }
            }
            .navigationTitle("Today's Supplements")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        isAddingDose = true
                    }
                }
            }
            .sheet(isPresented: $isAddingDose) {
                AddSupplementDoseView(
                    defaultIU: profile?.defaultSupplementIU ?? 1_000,
                    profile: profile
                )
            }
            .sheet(item: $editingDose) { dose in
                AddSupplementDoseView(profile: profile, dose: dose)
            }
        }
    }

    private func deleteSupplementDose(_ dose: SupplementDose) {
        Task {
            do {
                try await healthKitImportService.removeSupplementDoseFromHealth(dose)
            } catch {
                return
            }
            modelContext.delete(dose)
            try? modelContext.save()
        }
    }
}

struct DailyFoodLedgerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var allEntries: [FoodVitaminDEntry]
    @State private var isAddingEntry = false
    @State private var editingEntry: FoodVitaminDEntry?

    private var calendar: Calendar { .current }

    private var todayEntries: [FoodVitaminDEntry] {
        allEntries.filter { calendar.isDateInToday($0.loggedAt) }
    }

    var body: some View {
        NavigationStack {
            List {
                if todayEntries.isEmpty {
                    ContentUnavailableView(
                        "No food logged today",
                        systemImage: "fork.knife",
                        description: Text("Add salmon, fortified milk, eggs or other vitamin D sources.")
                    )
                } else {
                    ForEach(todayEntries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.foodName.isEmpty ? "Food" : entry.foodName)
                                        .font(.headline)

                                    Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(entry.estimatedIU) IU")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(.orange)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .bigDoseSwipeToDelete {
                            deleteFoodEntry(entry)
                        }
                    }
                }
            }
            .navigationTitle("Today's Food")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        isAddingEntry = true
                    }
                }
            }
            .sheet(isPresented: $isAddingEntry) {
                FoodVitaminDEntryEditorView()
            }
            .sheet(item: $editingEntry) { entry in
                FoodVitaminDEntryEditorView(entry: entry)
            }
        }
    }

    private func deleteFoodEntry(_ entry: FoodVitaminDEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}
