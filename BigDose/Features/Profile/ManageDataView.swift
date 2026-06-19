import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ManageDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labs: [LabResult]
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var foods: [FoodVitaminDEntry]
    @Query(sort: \DailySunPlan.generatedAt, order: .reverse) private var dailyPlans: [DailySunPlan]
    @Query(sort: \HealthImportBatch.importedAt, order: .reverse) private var importBatches: [HealthImportBatch]
    @Query(sort: \HealthImportItem.startedAt, order: .reverse) private var importItems: [HealthImportItem]
    @State private var exportURL: URL?
    @State private var isShowingImporter = false
    @State private var isShowingClearConfirmation = false
    @State private var statusMessage = "Export, restore, sync, and Apple Health import tools live here."
    var profile: UserProfile?

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    syncCard
                    exportCard
                    restoreCard
                    healthCard
                    clearCard
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Manage Data")
        .toolbarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isShowingImporter, allowedContentTypes: [.json]) { result in
            restore(from: result)
        }
        .confirmationDialog("Clear all local data?", isPresented: $isShowingClearConfirmation) {
            Button("Clear All Local Data", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes BigDose records on this device. Export a rescue file first if you may need the data later.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Manage Data")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text(statusMessage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var syncCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("iCloud Sync", systemImage: "icloud.fill")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white)

                Text("BigDose syncs your profile, sessions, labs, and imports through iCloud when you're signed in on this device. Rescue exports remain available for manual backup.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                Text(profile?.lastHealthKitImportAt == nil ? "No recent Apple Health import" : "Latest Apple Health import: \(profile?.lastHealthKitImportAt?.formatted(date: .abbreviated, time: .shortened) ?? "")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.56))
            }
        }
    }

    private var exportCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Export Full Data Stack", systemImage: "square.and.arrow.up")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white)

                Text("\(sessions.count) sessions, \(supplements.count) supplements, \(labs.count) labs, \(importBatches.count) import batches.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))

                Button {
                    createExport()
                } label: {
                    Text("Create Rescue File")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.solarOrange)

                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share Export", systemImage: "square.and.arrow.up")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(.solarGold)
                }
            }
        }
    }

    private var restoreCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Restore from Rescue File", systemImage: "externaldrive.badge.plus")
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.white)

                Text("Import a BigDose JSON export. Restored records are added to the local store and marked by source where applicable.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                Button {
                    isShowingImporter = true
                } label: {
                    Text("Choose Rescue File")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.solarGold)
            }
        }
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                HealthImportView(profile: profile)
            } label: {
                GlassCard {
                    AppleHealthNavigationRow(
                        title: "Import from Apple Health",
                        detail: "Review 90 days of workouts"
                    )
                }
            }
            .buttonStyle(.plain)

            AppleHealthKitAttributionView()
        }
    }

    private var clearCard: some View {
        GlassCard {
            Button(role: .destructive) {
                isShowingClearConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash.fill")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .tint(.red)
        }
    }

    private func createExport() {
        do {
            let payload = BigDoseDataExportService.makePayload(
                profiles: profiles,
                sessions: sessions,
                supplements: supplements,
                labs: labs,
                foods: foods,
                dailyPlans: dailyPlans,
                healthImportBatches: importBatches,
                healthImportItems: importItems
            )
            exportURL = try BigDoseDataExportService.writeTemporaryExport(payload)
            statusMessage = "Rescue file created and ready to share."
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func restore(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let payload = try BigDoseDataExportService.decodePayload(from: url)
            BigDoseDataExportService.restore(payload, into: modelContext)
            statusMessage = "Restored \(payload.sessions.count + payload.supplements.count + payload.labs.count) records from rescue file."
        } catch {
            statusMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func clearAllData() {
        for item in sessions { modelContext.delete(item) }
        for item in supplements { modelContext.delete(item) }
        for item in labs { modelContext.delete(item) }
        for item in foods { modelContext.delete(item) }
        for item in dailyPlans { modelContext.delete(item) }
        for item in importBatches { modelContext.delete(item) }
        for item in importItems { modelContext.delete(item) }
        try? modelContext.save()
        statusMessage = "Local activity, import, lab, and supplement data was cleared."
    }
}

#Preview {
    NavigationStack {
        ManageDataView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
