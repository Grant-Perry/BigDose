import SwiftData
import SwiftUI

struct ProgressDashboardView: View {
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var foods: [FoodVitaminDEntry]
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labs: [LabResult]
    var profile: UserProfile?

    private var activeProfile: UserProfile {
        profile ?? .preview
    }

    private var estimatedLevel: Double {
        snapshot.estimatedLevel
    }

    private var levelProgress: Double {
        min(estimatedLevel / activeProfile.goalNanogramsPerMilliliter, 1)
    }

    private var snapshot: BigDoseProgressSnapshot {
        ProgressAggregationService.snapshot(
            profile: activeProfile,
            sessions: sessions,
            supplements: supplements,
            foods: foods,
            labs: labs
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        bloodLevelCard
                        weeklyCard
                        sourceSplitCard
                        badgesCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Progress")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Momentum")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("The goal is consistency, not cooking yourself.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var bloodLevelCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Estimated D Level")
                            .font(.bigDoseHeader(.title3).weight(.black))
                            .foregroundStyle(.white)

                        Text(snapshot.confidence)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Text("\(Int(estimatedLevel.rounded()))")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(estimatedLevel >= 30 ? .solarGold : .red)

                    Text("ng/mL")
                        .font(.bigDoseHeader(.headline).weight(.bold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                SunArcMeter(
                    progress: levelProgress,
                    quality: estimatedLevel >= 30 ? .prime : .low,
                    title: "\(Int(levelProgress * 100))%",
                    subtitle: "of today's goal"
                )
            }
        }
    }

    private var weeklyCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last 7 Days")
                        .font(.bigDoseHeader(.title3).weight(.black))
                        .foregroundStyle(.white)

                    Text("Sun, supplements, and food counted against your current daily target.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(compactIU(snapshot.totalIU))
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.solarGold)
                    Text("of \(compactIU(snapshot.targetIU)) IU")
                        .font(.bigDoseHeader(.headline).weight(.bold))
                        .foregroundStyle(.white.opacity(0.66))
                }
            }
        }
    }

    private var sourceSplitCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Source Split")
                    .font(.bigDoseHeader(.title3).weight(.black))
                    .foregroundStyle(.white)

                ProgressSourceRow(title: "Sun", value: snapshot.sunIU, systemImage: "sun.max.fill")
                ProgressSourceRow(title: "Supplements", value: snapshot.supplementIU, systemImage: "pills.fill")
                ProgressSourceRow(title: "Food", value: snapshot.foodIU, systemImage: "fork.knife")

                if let latestLab = snapshot.latestLab {
                    Divider().overlay(.white.opacity(0.12))
                    Text("Latest lab: \(Int(latestLab.nanogramsPerMilliliter.rounded())) ng/mL on \(latestLab.measuredAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.66))
                }
            }
        }
    }

    private var badgesCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "rosette")
                    .font(.bigDoseHeader(.largeTitle).weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Badges")
                        .font(.bigDoseHeader(.title3).weight(.black))
                        .foregroundStyle(.white)

                    Text("Streaks, smart timing, and safe exposure wins will unlock here.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private func compactIU(_ value: Double) -> String {
        if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        }

        return "\(Int(value.rounded()))"
    }
}

private struct ProgressSourceRow: View {
    var title: String
    var value: Double
    var systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Text("\(Int(value.rounded())) IU")
                .font(.bigDoseHeader(.headline).weight(.black))
                .foregroundStyle(.solarGold)
        }
    }
}

#Preview {
    ProgressDashboardView(profile: .preview)
        .modelContainer(BigDoseModelContainerFactory.preview)
}
