import SwiftData
import SwiftUI

struct SupplementLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var doses: [SupplementDose]
    @State private var isAddingDose = false
    @State private var healthKitImportService = HealthKitImportService()
    var profile: UserProfile?

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Supplement Log")
                        .font(.system(.largeTitle, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Track vitamin D IU from supplements so progress is not only based on sunlight.")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))

                    if doses.isEmpty {
                        emptyState
                    } else {
                        ForEach(doses) { dose in
                            doseRow(dose)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Supplements")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
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
    }

    private var emptyState: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "pills.fill")
                    .font(.bigDoseHeader(.largeTitle).weight(.semibold))
                    .foregroundStyle(.solarGold)

                Text("No supplements logged")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white)

                Text("Use Add to record a dose. Home can also quick-log your default amount.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func doseRow(_ dose: SupplementDose) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dose.takenAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white)

                    Text(dose.note.isEmpty ? dose.source.title : dose.note)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(dose.internationalUnits)")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .contextMenu {
            Button("Delete", role: .destructive) {
                Task {
                    await healthKitImportService.removeSupplementDoseFromHealth(dose)
                    modelContext.delete(dose)
                    try? modelContext.save()
                }
            }
        }
    }
}

struct AddSupplementDoseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var takenAt = Date()
    @State private var iuText: String
    @State private var note = ""
    @State private var healthKitImportService = HealthKitImportService()
    var profile: UserProfile?

    init(defaultIU: Int = 1_000, profile: UserProfile? = nil) {
        _iuText = State(initialValue: String(defaultIU))
        self.profile = profile
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Taken", selection: $takenAt)
                TextField("IU", text: $iuText)
                    .keyboardType(.numberPad)
                TextField("Note", text: $note, axis: .vertical)
            }
            .navigationTitle("Add Supplement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
        let dose = SupplementDose(takenAt: takenAt, internationalUnits: iu, note: note)
        modelContext.insert(dose)
        try? modelContext.save()

        if let profile {
            Task {
                await healthKitImportService.syncSupplementDoseToHealth(dose, profile: profile)
                try? modelContext.save()
            }
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        SupplementLogView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
