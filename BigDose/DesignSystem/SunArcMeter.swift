import SwiftUI

struct SunArcMeter: View {
    var progress: Double
    var quality: SunWindowQuality
    var title: String
    var subtitle: String
    var showsQualityBadge = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress = 0.0
    @State private var glow = false

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ArcGaugeRing(
                    startAngle: .degrees(200),
                    endAngle: .degrees(340),
                    fill: AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                Color.gpDark1.opacity(0.82),
                                Color.gpDark1.opacity(0.66),
                                Color.black.opacity(0.84)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ),
                    innerShadowIntensity: 1
                )

                ArcGaugeRing(
                    startAngle: .degrees(200),
                    endAngle: .degrees(200 + 140 * animatedProgress),
                    fill: AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.gpHiOrange, Color.gpGatePill],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ),
                    innerShadowIntensity: 0.82,
                    outerGlowColor: Color.gpHiOrange.opacity(glow ? 0.75 : 0.35),
                    outerGlowRadius: glow ? 20 : 10
                )

                ArcOrbitingSun(progress: animatedProgress) {
                    sun
                }

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

            if showsQualityBadge {
                Text(quality.title.uppercased())
                    .font(.caption.weight(.black))
                    .tracking(1.6)
                    .foregroundStyle(.solarGold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.solarGold.opacity(0.15), in: .capsule)
            }
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

}

private struct ArcGaugeRing: View {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat = 22
    var fill: AnyShapeStyle
    var innerShadowIntensity: Double = 1
    var outerGlowColor: Color?
    var outerGlowRadius: CGFloat = 0

    var body: some View {
        ZStack {
            ArcRingSegmentShape(startAngle: startAngle, endAngle: endAngle, lineWidth: lineWidth)
                .fill(fill)

            ArcRingSegmentShape(startAngle: startAngle, endAngle: endAngle, lineWidth: lineWidth)
                .fill(
                    RadialGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.18 * innerShadowIntensity),
                            .black.opacity(0.58 * innerShadowIntensity)
                        ],
                        center: UnitPoint(x: 0.5, y: 0.94),
                        startRadius: 8,
                        endRadius: 118
                    )
                )
                .blendMode(.multiply)

            ArcShape(startAngle: startAngle, endAngle: endAngle)
                .stroke(
                    .black.opacity(0.62 * innerShadowIntensity),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .blur(radius: 7)
                .mask {
                    ArcRingSegmentShape(startAngle: startAngle, endAngle: endAngle, lineWidth: lineWidth)
                        .fill(.black)
                }

            ArcShape(startAngle: startAngle, endAngle: endAngle)
                .stroke(
                    .black.opacity(0.34 * innerShadowIntensity),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .blur(radius: 2.5)
                .offset(y: 1.5)
                .mask {
                    ArcRingSegmentShape(startAngle: startAngle, endAngle: endAngle, lineWidth: lineWidth)
                        .fill(.black)
                }
        }
        .shadow(color: outerGlowColor ?? .clear, radius: outerGlowRadius)
    }
}

private struct ArcRingSegmentShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = ArcMeterGeometry.center(in: rect)
        let radius = ArcMeterGeometry.radius(in: rect)
        let outerRadius = radius + lineWidth / 2
        let innerRadius = max(radius - lineWidth / 2, 0)

        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

private struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = ArcMeterGeometry.center(in: rect)
        let radius = ArcMeterGeometry.radius(in: rect)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

private struct ArcOrbitingSun<Content: View>: View, Animatable {
    var progress: Double
    @ViewBuilder var content: () -> Content

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            content()
                .position(ArcMeterGeometry.point(for: progress, in: rect))
        }
        .allowsHitTesting(false)
    }
}

private enum ArcMeterGeometry {
    static let startDegrees = 200.0
    static let sweepDegrees = 140.0

    static func center(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX, y: rect.maxY - 12)
    }

    static func radius(in rect: CGRect) -> CGFloat {
        min(rect.width, rect.height * 1.55) / 2
    }

    static func point(for progress: Double, in rect: CGRect) -> CGPoint {
        let clampedProgress = min(max(progress, 0), 1)
        let angle = Angle.degrees(startDegrees + sweepDegrees * clampedProgress).radians
        let center = center(in: rect)
        let radius = radius(in: rect)

        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}
