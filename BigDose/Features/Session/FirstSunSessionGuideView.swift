import SwiftUI

struct FirstSunSessionGuideView: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Two meters, two jobs")
                            .font(.bigDoseHeader(.title2).weight(.semibold))
                            .foregroundStyle(.white)

                        Text("BigDose tracks vitamin D progress and burn risk separately during every sun session.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    .padding(.top, 8)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Goal ring", systemImage: "target")
                                .font(.bigDoseHeader(.headline).weight(.semibold))
                                .foregroundStyle(.solarGold)

                            Text("Fills as estimated vitamin D accumulates toward today's IU target.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 4) {
                                Label("MED (burn risk) Used", systemImage: "shield.lefthalf.filled")
                                    .font(.bigDoseHeader(.headline).weight(.semibold))
                                    .foregroundStyle(.solarOrange)
                                InfoCircleButton(topic: .medUsed, compact: true)
                            }

                            Text("Climbs as burn risk is consumed. Turn-over alerts fire at halfway through your planned session or at 50% MED (burn risk) — whichever comes first. A stop-now warning always fires at 100% MED (burn risk). Nanny adds wrap-up at 75%, the 95% guidance alert and a 98% reminder. Only you stop the session.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("What to expect")
                                .font(.bigDoseHeader(.headline).weight(.semibold))
                                .foregroundStyle(.white)

                            SunSafetyMilestoneGuide()
                        }
                    }

                    Text("These are conservative wellness estimates, not medical guarantees.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.52))

                    BigDosePrimaryButton(title: "Start Session", action: onDismiss)
                }
                .padding(22)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    FirstSunSessionGuideView(onDismiss: {})
}
