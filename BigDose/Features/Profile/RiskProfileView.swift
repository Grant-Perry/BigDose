import SwiftData
import SwiftUI

struct RiskProfileView: View {
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var foods: [FoodVitaminDEntry]
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labs: [LabResult]
    @Query(sort: \DailySunPlan.generatedAt, order: .reverse) private var dailyPlans: [DailySunPlan]
    var profile: UserProfile?

    private var activeProfile: UserProfile {
        profile ?? .preview
    }

    private var progress: BigDoseProgressSnapshot {
        ProgressAggregationService.snapshot(
            profile: activeProfile,
            sessions: sessions,
            supplements: supplements,
            foods: foods,
            labs: labs
        )
    }

    private var risk: BigDoseRiskProfile {
        RiskProfileService.evaluate(
            profile: activeProfile,
            weather: nil,
            dailyPlan: dailyPlans.first { Calendar.current.isDateInToday($0.date) },
            progress: progress
        )
    }

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    scoreGrid
                    explanationCard
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Risk Snapshot")
        .toolbarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Risk Snapshot")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Wellness guidance based on your profile, recent intake, and current solar data.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var scoreGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            RiskScoreCard(title: "Sun Strength", value: risk.sunStrengthScore, symbolName: "sun.max.fill")
            RiskScoreCard(title: "Skin Limit", value: risk.skinLimitScore, symbolName: "shield.lefthalf.filled")
            RiskScoreCard(title: "Goal Progress", value: risk.deficiencyProgressScore, symbolName: "target")
            RiskScoreCard(title: "Safety", value: risk.skinLimitScore, symbolName: "figure.outdoor.cycle")
        }
    }

    private var explanationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(risk.safetyLabel, systemImage: "info.circle.fill")
                    .font(.bigDoseHeader(.title3).weight(.black))
                    .foregroundStyle(.solarGold)

                Text(risk.summary)
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white)

                Text("Confidence: \(risk.confidence). BigDose uses this for reminders and session guidance; it is not a medical diagnosis.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }
}

private struct RiskScoreCard: View {
    var title: String
    var value: Int
    var symbolName: String

    var body: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbolName)
                    .font(.bigDoseHeader(.title2).weight(.bold))
                    .foregroundStyle(.solarGold)

                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))

                Text("\(value)")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        RiskProfileView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}
