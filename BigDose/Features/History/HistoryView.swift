import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labs: [LabResult]
    @Query(sort: \HealthImportBatch.importedAt, order: .reverse) private var importBatches: [HealthImportBatch]

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        summaryCard

                        if sessions.isEmpty && supplements.isEmpty && labs.isEmpty && importBatches.isEmpty {
                            emptyState
                        } else {
                            sectionTitle("Sun")
                            ForEach(sessions) { session in
                                sessionRow(session)
                            }

                            sectionTitle("Supplements")
                            ForEach(supplements) { dose in
                                supplementRow(dose)
                            }

                            sectionTitle("Labs")
                            ForEach(labs) { result in
                                labRow(result)
                            }

                            sectionTitle("Imports")
                            ForEach(importBatches) { batch in
                                NavigationLink {
                                    HealthImportBatchLogView(batchImportedAt: batch.importedAt)
                                } label: {
                                    importRow(batch)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("History")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Sun Ledger")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Sun, supplements, food, and labs will live here.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var summaryCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Last 90 Days")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("\(sessions.count) sun sessions • \(supplements.count) supplement doses • \(labs.count) labs")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text(totalIU.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "sun.horizon.fill")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(.solarGold)

                Text("No sessions yet")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)

                Text("Once live tracking lands, your sun sessions will appear as clean timeline cards with UV, duration, estimated IU, and risk margin.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var totalIU: Double {
        sessions.reduce(0) { $0 + $1.estimatedIU } + supplements.reduce(0) { $0 + Double($1.internationalUnits) }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.black))
            .tracking(1.6)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 4)
    }

    private func sessionRow(_ session: ExposureSession) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.historySourceTitle)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text(session.startedAt, style: .time)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(Int(session.estimatedIU.rounded()))")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    private func supplementRow(_ dose: SupplementDose) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Supplement")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text(dose.takenAt, style: .date)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(dose.internationalUnits)")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                Text("IU")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    private func labRow(_ result: LabResult) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                Image(systemName: "testtube.2")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("25(OH)D Result")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text(result.measuredAt, style: .date)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(Int(result.nanogramsPerMilliliter.rounded()))")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.solarGold)

                Text("ng/mL")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    private func importRow(_ batch: HealthImportBatch) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health Import")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("\(batch.workoutCount) workouts • \(batch.acceptedExposureCount) accepted")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text(batch.importedAt, style: .date)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(BigDoseModelContainerFactory.preview)
}
