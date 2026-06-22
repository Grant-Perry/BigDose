import SwiftData
import SwiftUI

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var entries: [FoodVitaminDEntry]
    @State private var isAddingEntry = false
    @State private var editingEntry: FoodVitaminDEntry?

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Food Log")
                        .font(.system(.largeTitle, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Track vitamin D IU from fortified foods and fatty fish so daily totals stay complete.")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))

                    if entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(entries) { entry in
                            entryRow(entry)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .bigDoseSwipeActionsContainer()
        }
        .navigationTitle("Food")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
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

    private var emptyState: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "fork.knife")
                    .font(.bigDoseHeader(.largeTitle).weight(.semibold))
                    .foregroundStyle(.solarGold)

                Text("No food logged")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white)

                Text("Use Add to record vitamin D from salmon, fortified milk, eggs and other sources.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func entryRow(_ entry: FoodVitaminDEntry) -> some View {
        Button {
            editingEntry = entry
        } label: {
            GlassCard(cornerRadius: 22) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.foodName.isEmpty ? "Food" : entry.foodName)
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)

                        Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Text("\(entry.estimatedIU)")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.solarGold)

                    Text("IU")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.32))
                }
            }
        }
        .buttonStyle(.plain)
        .bigDoseDeletable {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}

struct FoodVitaminDEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var loggedAt: Date
    @State private var foodName: String
    @State private var iuText: String
    private let entry: FoodVitaminDEntry?

    init(entry: FoodVitaminDEntry? = nil) {
        self.entry = entry
        _loggedAt = State(initialValue: entry?.loggedAt ?? .now)
        _foodName = State(initialValue: entry?.foodName ?? "")
        _iuText = State(initialValue: entry.map { String($0.estimatedIU) } ?? "")
    }

    private var isEditing: Bool { entry != nil }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Logged", selection: $loggedAt)
                TextField("Food", text: $foodName, prompt: Text("Salmon, fortified milk…"))
                TextField("IU", text: $iuText)
                    .keyboardType(.numberPad)
            }
            .navigationTitle(isEditing ? "Edit Food" : "Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            deleteEntry()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(Int(iuText) == nil)
                }
            }
        }
    }

    private func save() {
        guard let iu = Int(iuText) else { return }

        if let entry {
            entry.loggedAt = loggedAt
            entry.foodName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.estimatedIU = iu
        } else {
            let newEntry = FoodVitaminDEntry(
                loggedAt: loggedAt,
                foodName: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
                estimatedIU: iu
            )
            modelContext.insert(newEntry)
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteEntry() {
        guard let entry else { return }
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FoodLogView()
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
