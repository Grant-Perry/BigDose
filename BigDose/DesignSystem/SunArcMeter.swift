import SwiftUI

struct SunArcMeter: View {
    var progress: Double
    var quality: SunWindowQuality
    var title: String
    var subtitle: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress = 0.0
    @State private var glow = false

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ArcShape(startAngle: .degrees(200), endAngle: .degrees(340))
                    .stroke(Color.gpDark1.opacity(0.72), style: StrokeStyle(lineWidth: 22, lineCap: .round))

                ArcShape(startAngle: .degrees(200), endAngle: .degrees(200 + 140 * animatedProgress))
                    .stroke(
                        LinearGradient(
                            colors: [Color.gpHiOrange, Color.gpGatePill],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .shadow(color: Color.gpHiOrange.opacity(glow ? 0.75 : 0.35), radius: glow ? 20 : 10)

                sun
                    .offset(positionOffset(for: animatedProgress))

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text(subtitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
                .padding(.top, 52)
            }
            .frame(height: 190)

            Text(quality.title.uppercased())
                .font(.caption.weight(.black))
                .tracking(1.6)
                .foregroundStyle(.solarGold)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.solarGold.opacity(0.15), in: .capsule)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vitamin D meter, \(title), \(subtitle), \(quality.title)")
        .onAppear {
            animateMeter()
        }
        .onChange(of: progress) {
            animateMeter()
        }
    }

    private var sun: some View {
        ZStack {
            Circle()
                .fill(Color.gpGatePill.opacity(0.32))
                .frame(width: 58, height: 58)
                .blur(radius: 12)

            Circle()
                .fill(.white.opacity(0.92))
                .frame(width: 40, height: 40)
                .shadow(color: Color.gpGatePill.opacity(0.65), radius: 14)

            Image(systemName: "sun.max.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.gpHiOrange)
                .symbolEffect(.pulse, value: animatedProgress)
        }
    }

    private func animateMeter() {
        if reduceMotion {
            animatedProgress = clampedProgress
            return
        }

        glow = false

        withAnimation(.smooth(duration: 1.1)) {
            animatedProgress = clampedProgress
        }

        withAnimation(.easeInOut(duration: 0.45).delay(0.75)) {
            glow = true
        }
        withAnimation(.easeOut(duration: 0.55).delay(1.2)) {
            glow = false
        }
    }

    private func positionOffset(for progress: Double) -> CGSize {
        let angle = Angle.degrees(200 + 140 * progress).radians
        let radius: CGFloat = 132
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius + 68)
    }
}

private struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY - 12)
        let radius = min(rect.width, rect.height * 1.55) / 2
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}
