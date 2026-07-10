import SwiftUI

struct ActiveSunSessionMetricsGrid: View {
    @Environment(\.colorScheme) private var colorScheme

    var medRemainingText: String
    var medUsedText: String
    var medUsedColor: Color
    var showsOverBadge: Bool
    var turnOverText: String
    var hasPassedTurnOver: Bool

    var body: some View {
        HStack(spacing: 0) {
            ActiveSunSessionMetricCard(
                title: "Burn limit",
                value: medRemainingText,
                systemImage: "shield.fill",
                accent: colorScheme == .dark ? .solarGoldBright : lightValueColor,
                infoTopic: .minToMED
            )

            divider

            ActiveSunSessionMetricCard(
                title: "MED used",
                value: medUsedText,
                systemImage: "sun.max.trianglebadge.exclamationmark.fill",
                accent: colorScheme == .dark ? medUsedColor : lightValueColor,
                infoTopic: .medUsed,
                badge: showsOverBadge ? "OVER" : nil
            )

            divider

            ActiveSunSessionMetricCard(
                title: hasPassedTurnOver ? "Burn limit" : "Roll over",
                value: turnOverText,
                systemImage: hasPassedTurnOver ? "exclamationmark.shield.fill" : "arrow.triangle.2.circlepath",
                accent: colorScheme == .dark
                    ? (hasPassedTurnOver ? .gpRedPink : .gpHiGreen)
                    : lightValueColor,
                infoTopic: hasPassedTurnOver ? .minToMED : .minToRollOver
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(surfaceColor, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(borderColor, lineWidth: 1)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(borderColor)
            .frame(width: 1, height: 54)
    }

    private var surfaceColor: Color {
        colorScheme == .dark
            ? .black.opacity(0.28)
            : .white.opacity(0.45)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? .solarGold.opacity(0.2)
            : Color.black.opacity(0.08)
    }

    private var lightValueColor: Color {
        Color(red: 0.22, green: 0.13, blue: 0.07)
    }
}
