import SwiftData
import SwiftUI

struct SupplementLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var doses: [SupplementDose]
    @State private var isAddingDose = false
    @State private var editingDose: SupplementDose?
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
            .bigDoseSwipeActionsContainer()
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
        .sheet(item: $editingDose) { dose in
            AddSupplementDoseView(profile: profile, dose: dose)
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

                Text("Use Add to record a dose. Dashboard can also quick-log your default amount.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func doseRow(_ dose: SupplementDose) -> some View {
        Button {
            editingDose = dose
        } label: {
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

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.32))
                }
            }
        }
        .buttonStyle(.plain)
        .bigDoseDeletable {
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
}

struct AddSupplementDoseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var takenAt: Date
    @State private var iuText: String
    @State private var note: String
    @State private var healthKitImportService = HealthKitImportService()
    var profile: UserProfile?
    private let dose: SupplementDose?

    init(defaultIU: Int = 1_000, profile: UserProfile? = nil, dose: SupplementDose? = nil) {
        self.profile = profile
        self.dose = dose
        _takenAt = State(initialValue: dose?.takenAt ?? .now)
        _iuText = State(initialValue: String(dose?.internationalUnits ?? defaultIU))
        _note = State(initialValue: dose?.note ?? "")
    }

    private var isEditing: Bool { dose != nil }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Taken", selection: $takenAt)
                TextField("IU", text: $iuText)
                    .keyboardType(.numberPad)
                TextField("Note", text: $note, axis: .vertical)
            }
            .navigationTitle(isEditing ? "Edit Supplement" : "Add Supplement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            deleteDose()
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

        if let dose {
            Task {
                do {
                    try await healthKitImportService.removeSupplementDoseFromHealth(dose)
                } catch {
                    return
                }
                dose.takenAt = takenAt
                dose.internationalUnits = iu
                dose.note = note
                try? modelContext.save()

                if let profile {
                    await healthKitImportService.syncSupplementDoseToHealth(dose, profile: profile)
                    try? modelContext.save()
                }

                dismiss()
            }
            return
        }

        let newDose = SupplementDose(takenAt: takenAt, internationalUnits: iu, note: note)
        modelContext.insert(newDose)
        try? modelContext.save()

        if let profile {
            Task {
                await healthKitImportService.syncSupplementDoseToHealth(newDose, profile: profile)
                try? modelContext.save()
            }
        }

        dismiss()
    }

    private func deleteDose() {
        guard let dose else { return }

        Task {
            do {
                try await healthKitImportService.removeSupplementDoseFromHealth(dose)
            } catch {
                return
            }
            modelContext.delete(dose)
            try? modelContext.save()
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        SupplementLogView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
