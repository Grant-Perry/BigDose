import SwiftUI

/// Marketing hero headline — matches bigdose.web.app first-screen title treatment.
struct BigDoseHeroTitle: View {
    var primaryLine: String
    var accentLine: String
    var alignment: HorizontalAlignment = .leading
    /// Web `clamp(2.35rem, 4.8vw, 4.35rem)` ≈ 38pt on phone widths.
    var primarySize: CGFloat = 38
    /// Web `clamp(1.9rem, 3.9vw, 3.55rem)` ≈ 32pt on phone widths.
    var accentSize: CGFloat = 32

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(primaryLine)
                .font(.bigDoseHeroPrimary(primarySize))
                .foregroundStyle(.white)
                .textCase(.uppercase)
                .tracking(primarySize * 0.03)
                .lineSpacing(primarySize * 0.05)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(accentLine)
                .font(.bigDoseHeroAccent(accentSize))
                .foregroundStyle(BigDoseBrandGradients.heroAccent)
                .tracking(accentSize * -0.02)
                .lineSpacing(accentSize * 0.15)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .center: .center
        case .trailing: .trailing
        default: .leading
        }
    }
}

#Preview {
    ZStack {
        Color.deepSpace.ignoresSafeArea()
        BigDoseHeroTitle(
            primaryLine: WhyBigDoseEducationContent.heroPrimaryLine,
            accentLine: WhyBigDoseEducationContent.heroAccentLine
        )
        .padding()
    }
}
