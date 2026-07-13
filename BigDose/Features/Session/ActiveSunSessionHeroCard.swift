import SwiftUI

struct ActiveSunSessionHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var elapsedText: String
    var estimatedIU: Int
    var targetIU: Int
    var iuPerMinute: Int
    var goalProgress: Double
    var minutesToGoal: Int?
    var isTraceVitaminDConditions: Bool
    var isPaused: Bool
    var onGoalTap: (() -> Void)?

    private var clampedGoalProgress: Double {
        min(max(goalProgress, 0), 1)
    }

    private var goalStatus: String {
        if goalProgress >= 1 {
            return "Goal reached"
        }

        if let minutesToGoal {
            return "About \(minutesToGoal) min remaining"
        }

        return "Calculating time remaining"
    }

    var body: some View {
        VStack(spacing: colorScheme == .dark ? 8 : 0) {
            ActiveSunSessionDial(
                elapsedText: elapsedText,
                estimatedIU: estimatedIU,
                iuPerMinute: iuPerMinute,
                goalProgress: goalProgress,
                isTraceVitaminDConditions: isTraceVitaminDConditions,
                isPaused: isPaused
            )

            goalSummaryButton
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var goalSummaryButton: some View {
        let summary = goalSummary
            .contentShape(.rect)

        if let onGoalTap {
            Button(action: onGoalTap) {
                summary
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Session goal, \(targetIU.formatted()) IU")
            .accessibilityHint("Opens goal editor")
        } else {
            summary
        }
    }

    private var goalSummary: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(goalProgress * 100))%")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(accentColor)

                    Text("OF \(targetIU.formatted()) IU")
                        .font(.caption)
                        .bold()
                        .tracking(0.8)
                        .foregroundStyle(secondaryText)
                }

                Divider()
                    .frame(height: 32)

                Spacer(minLength: 0)

                Text(goalStatus.uppercased())
                    .font(.caption)
                    .bold()
                    .tracking(0.6)
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }

            ProgressView(value: clampedGoalProgress)
                .tint(accentColor)
                .scaleEffect(x: 1, y: 1.6)
        }
        .padding(.horizontal, colorScheme == .dark ? 20 : 10)
        .padding(.vertical, colorScheme == .dark ? 14 : 10)
        .background {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.black.opacity(0.34))
            }
        }
        .overlay {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.solarGold.opacity(0.24), lineWidth: 1)
            }
        }
    }

    private var primaryText: Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.22, green: 0.13, blue: 0.07)
    }

    private var secondaryText: Color {
        primaryText.opacity(0.62)
    }

    private var accentColor: Color {
        goalProgress >= 1
            ? (colorScheme == .dark ? .gpHiGreen : .green)
            : (colorScheme == .dark ? .solarGoldBright : .solarOrange)
    }
}
