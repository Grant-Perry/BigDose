import SwiftData
import SwiftUI

struct LabResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var results: [LabResult]
    @State private var isAddingResult = false

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("25(OH)D Results")
                        .font(.system(.largeTitle, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Lab values anchor BigDose estimates. Add each result as ng/mL from your report.")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))

                    if results.isEmpty {
                        emptyState
                    } else {
                        ForEach(results) { result in
                            labRow(result)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Lab Results")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    isAddingResult = true
                }
            }
        }
        .sheet(isPresented: $isAddingResult) {
            AddLabResultView()
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "testtube.2")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.solarGold)

                Text("No lab results yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Add your latest 25(OH)D value when you have one. BigDose will keep estimates clearly labeled until then.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func labRow(_ result: LabResult) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.measuredAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(result.note.isEmpty ? result.source.title : result.note)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(Int(result.nanogramsPerMilliliter.rounded()))")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("ng/mL")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .contextMenu {
            Button("Delete", role: .destructive) {
                modelContext.delete(result)
                try? modelContext.save()
            }
        }
    }
}

struct AddLabResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var measuredAt = Date()
    @State private var valueText = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Measured", selection: $measuredAt, displayedComponents: .date)
                TextField("25(OH)D ng/mL", text: $valueText)
                    .keyboardType(.decimalPad)
                TextField("Note", text: $note, axis: .vertical)
            }
            .navigationTitle("Add Lab Result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(Double(valueText) == nil)
                }
            }
        }
    }

    private func save() {
        guard let value = Double(valueText) else { return }
        modelContext.insert(LabResult(measuredAt: measuredAt, nanogramsPerMilliliter: value, note: note))
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LabResultsView()
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
