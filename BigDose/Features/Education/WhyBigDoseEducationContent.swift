import SwiftUI

/// Shared copy for the "Why BigDose" product story — onboarding, Science tab and nudges.
enum WhyBigDoseEducationContent {
    static let heroPrimaryLine = "Dose your D..."
    static let heroAccentLine = "Defend your Skin!"
    /// Legacy combined tagline — prefer `BigDoseHeroTitle` for display.
    static var tagline: String { "\(heroPrimaryLine)\n\(heroAccentLine)" }
    static let subtitle = "Most sun advice picks one lane. BigDose tracks vitamin D progress and burn risk at the same time — so you can get outside without guessing."

    static let philosophySections: [WhyBigDoseSection] = [
        WhyBigDoseSection(
            symbolName: "bolt.fill",
            title: "The Sun Does Two Jobs At Once",
            detail: """
            When UV reaches your skin, it kick-starts vitamin D production and it stresses skin cells at the same time. \
            Redness, tanning, photoaging and long-term skin cancer risk all ride on the same sunlight. \
            More minutes outside is not a free extra helping of D — it is also more wear on your skin.
            """
        ),
        WhyBigDoseSection(
            symbolName: "circle.circle",
            title: "Two Meters, One Session",
            detail: """
            Every live sun session runs two clocks. The goal ring tracks estimated vitamin D toward your daily target. \
            the MED (burn risk) Used: tracks how much of your personal sunburn budget you have spent. \
            Hitting your IU goal does not mean your skin is safe — and a safe skin window does not always match your D goal.
            """
        ),
        WhyBigDoseSection(
            symbolName: "person.crop.circle.badge.checkmark",
            title: "Your Body, Your Sky, Your Limits",
            detail: """
            Fair skin at solar noon in Denver is not the same as medium skin under clouds at 4 PM in Seattle. \
            BigDose uses your skin type, age, coverage, sunscreen, local UV, cloud cover and sun angle — \
            not a generic "15 minutes" rule from a chart that ignores who you are.
            """
        ),
        WhyBigDoseSection(
            symbolName: "hand.raised.fill",
            title: "We Guide. You Decide.",
            detail: """
            BigDose warns to turn over at halfway through your planned session or at ~50% MED (burn risk) — whichever comes first — and stop-now at 100% MED. \
            Optional Nanny adds wrap-up (~75%), tighter guidance at 95% and 98%. We never end a session for you. \
            The estimates are deliberately conservative — missing a little D is easier to fix than reversing sun damage.
            """
        )
    ]

    static let scienceFooter = WhyBigDoseSection(
        symbolName: "book.fill",
        title: "Simple Science, Honest Limits",
        detail: """
        Vitamin D timing uses published response models. Burn risk uses Fitzpatrick skin-type baselines adjusted for real UV, \
        clouds and sunscreen. That is useful freshman-level biology — not a diagnosis. \
        A 25(OH)D blood test is still the source of truth for your level.
        """
    )

    static let onboardingTeaser = """
    BigDose was built on a simple idea: you should not have to choose between getting vitamin D and protecting your skin. \
    We watch both — in real time — and let you make the call.
    """
}

enum NannyModeEducation {
    static let toggleTitle = "Nanny Mode"

    static let fullExplanation = """
    During live sun sessions, BigDose tracks your burn risk (MED Used) and warns you at key milestones. \
    Turn-over fires at halfway through your planned session or at 50% MED (burn risk) — whichever comes first. \
    With Nanny on, you also get wrap-up near 75%, the 95% guidance alert and a 98% reminder if you keep going — extra guardrails for staying out past the wrap-up window. \
    With Nanny off, you still get turn-over and stop-now at 100% MED (burn risk) when session safety guidance is on. \
    BigDose never ends a session for you — only you can stop and save.
    """
}

struct WhyBigDoseSection: Identifiable {
    let id = UUID()
    var symbolName: String
    var title: String
    var detail: String
}

struct WhyBigDoseTaglineHeader: View {
    var showsSubtitle = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BigDoseHeroTitle(
                primaryLine: WhyBigDoseEducationContent.heroPrimaryLine,
                accentLine: WhyBigDoseEducationContent.heroAccentLine
            )

            if showsSubtitle {
                Text(WhyBigDoseEducationContent.subtitle)
                    .font(.bigDoseLede(.callout))
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct WhyBigDoseSectionCard: View {
    var section: WhyBigDoseSection
    var cornerRadius: CGFloat = 26

    var body: some View {
        GlassCard(cornerRadius: cornerRadius) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: section.symbolName)
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.solarGold)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Text(section.detail)
                        .font(.bigDoseBody(.subheadline, weight: .medium))
                        .foregroundStyle(.white.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
