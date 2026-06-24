import SwiftUI

enum SunSafetyMilestoneGuideStyle {
    case educational
}

struct SunSafetyMilestoneGuide: View {
    var style: SunSafetyMilestoneGuideStyle = .educational

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch style {
            case .educational:
                milestoneRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Turn over",
                    detail: "~50% of MED (burn risk)",
                    note: "Flip sides or rotate so one area does not take all the UV."
                )
                milestoneRow(
                    icon: "figure.walk",
                    title: "Wrap up",
                    detail: "~75% of MED (burn risk)",
                    note: "Start heading inside or into shade."
                )
                milestoneRow(
                    icon: "hand.raised.fill",
                    title: "Stop or cover up",
                    detail: "~95% of MED (burn risk)",
                    note: "BigDose's guidance limit. Requires Nanny in Settings → Session Safety. Nanny also adds a 98% reminder while you stay out. Only you stop the session.",
                    tint: .solarOrange
                )
            }
        }
    }

    private func milestoneRow(
        icon: String,
        title: String,
        detail: String,
        note: String,
        tint: Color = .white
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.solarGold)
                .frame(width: 22, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.88))

                    Spacer(minLength: 8)

                    Text(detail)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint == .white ? .solarGold : tint)
                }

                Text(note)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SunSafetyIntroBanner: View {
    var goalMinutes: Int
    var safeMaxMinutes: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.solarGold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Your personal limits for today's UV")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("BigDose alerts you at each milestone during your session. Your D goal is ~\(goalMinutes) min. Your safe max is ~\(safeMaxMinutes) min — never plan past safe max.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: 18))
    }
}
