import SwiftUI

struct SunArcMeter: View {
    var progress: Double
    var quality: SunWindowQuality
    var title: String
    var durationTitle: BigDoseDurationComponents?
    var subtitle: String
    var showsQualityBadge = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedProgress = 0.0

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
                    showsInnerShadow: true
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
                    showsInnerShadow: false
                )

                ArcOrbitingSun(progress: animatedProgress) {
                    sun
                }

                VStack(spacing: 2) {
                    if let durationTitle {
                        BigDoseDurationText(
                            durationTitle,
                            font: .system(size: 54, weight: .black),
                            valueColor: .white
                        )
                        .contentTransition(.numericText())
                    } else {
                        Text(title)
                            .font(.system(size: 54, weight: .black))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }

                    Text(subtitle)
                        .font(.bigDoseHeader(.headline).weight(.semibold))
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
        .accessibilityLabel("Vitamin D meter, \(durationTitle?.accessibilityLabel ?? title), \(subtitle), \(quality.title)")
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
                .fill(.white.opacity(0.92))
                .frame(width: 40, height: 40)
                .overlay {
                    Circle()
                        .strokeBorder(.black.opacity(0.18), lineWidth: 1)
                }

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

        withAnimation(.smooth(duration: 1.1)) {
            animatedProgress = clampedProgress
        }
    }
}

private struct ArcGaugeRing: View {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat = 22
    var fill: AnyShapeStyle
    var showsInnerShadow: Bool

    private var ringShape: ArcRingSegmentShape {
        ArcRingSegmentShape(startAngle: startAngle, endAngle: endAngle, lineWidth: lineWidth)
    }

    var body: some View {
        ZStack {
            ringShape
                .fill(fill)

            if showsInnerShadow {
                ArcTrackInnerShadow(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    lineWidth: lineWidth
                )
            }
        }
        .clipShape(ringShape)
    }
}

/// Recessed depth for the empty track — inset shadows only, no outer glow.
private struct ArcTrackInnerShadow: View {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat

    private var ringShape: ArcRingSegmentShape {
        ArcRingSegmentShape(startAngle: startAngle, endAngle: endAngle, lineWidth: lineWidth)
    }

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let midRadius = ArcMeterGeometry.radius(in: rect)
            let innerRadius = max(midRadius - lineWidth / 2, 0)
            let outerRadius = midRadius + lineWidth / 2

            ZStack {
                ringShape
                    .fill(
                        RadialGradient(
                            colors: [
                                .black.opacity(0.62),
                                .black.opacity(0.34),
                                .clear
                            ],
                            center: UnitPoint(x: 0.5, y: 0.24),
                            startRadius: 8,
                            endRadius: 118
                        )
                    )
                    .blendMode(.multiply)

                ArcAtRadiusShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    radius: innerRadius
                )
                .stroke(
                    .black.opacity(0.72),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .blur(radius: 2)
                .offset(y: 1)

                ArcAtRadiusShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    radius: outerRadius
                )
                .stroke(
                    .black.opacity(0.58),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .blur(radius: 2)
                .offset(y: 1)

                ArcAtRadiusShape(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    radius: midRadius
                )
                .stroke(
                    .black.opacity(0.38),
                    style: StrokeStyle(lineWidth: lineWidth * 0.72, lineCap: .round)
                )
                .blur(radius: 5)
                .blendMode(.multiply)
            }
            .mask(ringShape.fill(.black))
        }
    }
}

private struct ArcAtRadiusShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = ArcMeterGeometry.center(in: rect)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

private struct ArcRingSegmentShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = ArcMeterGeometry.center(in: rect)
        let radius = ArcMeterGeometry.radius(in: rect)
        let halfWidth = lineWidth / 2
        let outerRadius = radius + halfWidth
        let innerRadius = max(radius - halfWidth, 0)

        var path = Path()
        path.move(to: point(on: center, radius: innerRadius, angle: startAngle))

        path.addArc(
            center: point(on: center, radius: radius, angle: startAngle),
            radius: halfWidth,
            startAngle: startAngle + .degrees(180),
            endAngle: startAngle,
            clockwise: false
        )

        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        path.addArc(
            center: point(on: center, radius: radius, angle: endAngle),
            radius: halfWidth,
            startAngle: endAngle,
            endAngle: endAngle + .degrees(180),
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

    private func point(on center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle.radians) * radius,
            y: center.y + sin(angle.radians) * radius
        )
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
