import SwiftUI

struct ActiveSunSessionMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var title: String
    var value: String
    var systemImage: String
    var accent: Color
    var infoTopic: BigDoseInfoTopic
    var badge: String?

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(accent)

                Text(title.uppercased())
                    .font(.caption)
                    .bold()
                    .tracking(0.8)
                    .foregroundStyle(primaryText.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                InfoCircleButton(topic: infoTopic, compact: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .monospaced))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if let badge {
                    Text(badge)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(accent, in: .capsule)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, minHeight: 74)
        .padding(.horizontal, 6)
        .accessibilityElement(children: .combine)
    }

    private var primaryText: Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.22, green: 0.13, blue: 0.07)
    }
}
