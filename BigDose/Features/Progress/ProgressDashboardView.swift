import SwiftUI

struct ProgressDashboardView: View {
    var profile: UserProfile?

    private var activeProfile: UserProfile {
        profile ?? .preview
    }

    private var estimatedLevel: Double {
        activeProfile.baselineNanogramsPerMilliliter ?? 25
    }

    private var levelProgress: Double {
        min(estimatedLevel / activeProfile.goalNanogramsPerMilliliter, 1)
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
                        Text("Estimated D Blood Level")
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)

                        Text("Trend estimate. Labs are truth.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Text("\(Int(estimatedLevel.rounded()))")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(estimatedLevel >= 30 ? .solarGold : .red)

                    Text("ng/mL")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                SunArcMeter(
                    progress: levelProgress,
                    quality: estimatedLevel >= 30 ? .prime : .low,
                    title: "\(Int(levelProgress * 100))%",
                    subtitle: "of goal"
                )
            }
        }
    }

    private var weeklyCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last 7 Days")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)

                    Text("Your weekly IU chart will land here with sun, food, and supplements split cleanly.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text("5.5K")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.solarGold)
                    Text("of 7K IU")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.66))
                }
            }
        }
    }

    private var badgesCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "rosette")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Badges")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)

                    Text("Streaks, smart timing, and safe exposure wins will unlock here.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }
}

#Preview {
    ProgressDashboardView(profile: .preview)
}
