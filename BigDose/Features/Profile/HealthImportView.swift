import SwiftData
import SwiftUI

struct HealthImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthImportItem.startedAt, order: .reverse) private var importedItems: [HealthImportItem]
    @State private var service = HealthKitImportService()
    @State private var candidates: [HealthWorkoutImportCandidate] = []
    @State private var isLoading = false
    @State private var statusMessage = "Review outdoor workouts from the last 90 days before BigDose counts them."
    @State private var lastResult: HealthImportResult?
    var profile: UserProfile?

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    actionCard

                    if let lastResult {
                        summaryCard(lastResult)
                    }

                    if !candidates.isEmpty {
                        Text("Found in Apple Health".uppercased())
                            .font(.caption.weight(.black))
                            .tracking(1.6)
                            .foregroundStyle(.white.opacity(0.5))

                        ForEach(candidates) { candidate in
                            candidateRow(candidate)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Apple Health")
        .toolbarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Health Import")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text(statusMessage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var actionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("90-day workout lookback", systemImage: "heart.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("BigDose reads workouts only after permission. Outdoor workouts are imported with a visible confidence note and conservative vitamin D assumptions.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                Button {
                    Task { await loadCandidates() }
                } label: {
                    Label(isLoading ? "Checking Apple Health" : "Review Apple Health Workouts", systemImage: "arrow.down.heart.fill")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.solarOrange)
                .disabled(isLoading)

                Button {
                    commitImport()
                } label: {
                    Label("Import Selected Workouts", systemImage: "checkmark.circle.fill")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.solarGold)
                .disabled(candidates.filter(\.shouldImport).isEmpty)
            }
        }
    }

    private func summaryCard(_ result: HealthImportResult) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Import")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("\(result.acceptedCount) accepted • \(result.skippedCount) skipped")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(result.workoutCount)")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("items")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
    }

    private func candidateRow(_ candidate: HealthWorkoutImportCandidate) -> some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.activityName)
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)

                        Text(candidate.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Text("\(Int(candidate.durationSeconds / 60)) min")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.solarGold)
                }

                Text(candidate.note)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))

                Label(candidate.shouldImport ? "Will import" : "Skipped", systemImage: candidate.shouldImport ? "checkmark.circle.fill" : "minus.circle")
                    .font(.caption.weight(.black))
                    .foregroundStyle(candidate.shouldImport ? .green : .white.opacity(0.5))
            }
        }
    }

    private func loadCandidates() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await service.requestAuthorization()
            profile?.healthKitImportStatus = .authorized
            let existingIDs = Set(importedItems.map(\.externalIdentifier))
            candidates = try await service.fetchWorkoutCandidates(existingIDs: existingIDs)
            statusMessage = candidates.isEmpty ? "No recent workouts were found in Apple Health." : "Review what BigDose found before importing."
            try? modelContext.save()
        } catch {
            profile?.healthKitImportStatus = .failed
            statusMessage = error.localizedDescription
            try? modelContext.save()
        }
    }

    private func commitImport() {
        guard let profile else { return }
        lastResult = service.commit(candidates: candidates, profile: profile, modelContext: modelContext)
        candidates.removeAll()
        statusMessage = "Import complete. You can inspect imported items in History."
    }
}

#Preview {
    NavigationStack {
        HealthImportView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
