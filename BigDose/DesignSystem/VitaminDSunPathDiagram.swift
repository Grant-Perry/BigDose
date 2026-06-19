import SwiftUI

struct VitaminDSunPathDiagram: View {
    var display: VitaminDWindowDisplay

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { proxy in
                let layout = SunPathLayout(size: proxy.size, snapshot: display.snapshot)
                ZStack {
                    thresholdBand(layout: layout)
                    horizonLine(layout: layout)
                    sunPath(layout: layout)
                    thresholdLine(layout: layout)
                    markerLayer(layout: layout)
                }
            }
            .frame(height: 210)

            summaryRow
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private func horizonLine(layout: SunPathLayout) -> some View {
        Path { path in
            path.move(to: CGPoint(x: layout.leftX, y: layout.horizonY))
            path.addLine(to: CGPoint(x: layout.rightX, y: layout.horizonY))
        }
        .stroke(.white.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }

    private func sunPath(layout: SunPathLayout) -> some View {
        Path { path in
            let points = layout.sunPathPoints()
            guard let first = points.first else { return }

            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            LinearGradient(
                colors: [.white.opacity(0.18), .solarGold.opacity(0.72), .white.opacity(0.18)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 7])
        )
    }

    private func thresholdBand(layout: SunPathLayout) -> some View {
        Path { path in
            guard
                let startX = layout.x(for: display.snapshot.windowStart),
                let endX = layout.x(for: display.snapshot.windowEnd)
            else { return }

            let topY = layout.y(forAltitude: display.snapshot.solarNoonAltitudeDegrees)
            path.move(to: CGPoint(x: startX, y: layout.thresholdY))
            path.addLine(to: CGPoint(x: endX, y: layout.thresholdY))
            path.addLine(to: CGPoint(x: endX, y: topY))
            path.addLine(to: CGPoint(x: startX, y: topY))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [.solarGold.opacity(0.18), .solarOrange.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func thresholdLine(layout: SunPathLayout) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: layout.leftX, y: layout.thresholdY))
                path.addLine(to: CGPoint(x: layout.rightX, y: layout.thresholdY))
            }
            .stroke(.white.opacity(0.34), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))

            Text("\(Int(display.snapshot.thresholdDegrees.rounded()))°")
                .font(.caption2.weight(.black))
                .foregroundStyle(.solarGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.72), in: .capsule)
                .overlay {
                    Capsule().stroke(.solarGold.opacity(0.35), lineWidth: 1)
                }
                .position(x: layout.size.width / 2, y: layout.thresholdY)
        }
    }

    private func markerLayer(layout: SunPathLayout) -> some View {
        ZStack {
            if let sunrise = display.snapshot.sunrise {
                sunMarker(
                    layout: layout,
                    date: sunrise,
                    label: sunrise.formatted(date: .omitted, time: .shortened),
                    isPeak: false,
                    size: 24
                )
            }

            if let windowStart = display.snapshot.windowStart {
                sunMarker(
                    layout: layout,
                    date: windowStart,
                    label: windowStart.formatted(date: .omitted, time: .shortened),
                    isPeak: false,
                    size: 28
                )
            }

            sunMarker(
                layout: layout,
                date: display.snapshot.solarNoon,
                label: display.snapshot.solarNoon.formatted(date: .omitted, time: .shortened),
                detail: "\(Int(display.snapshot.solarNoonAltitudeDegrees.rounded()))°",
                isPeak: true,
                size: 38
            )

            if let windowEnd = display.snapshot.windowEnd {
                sunMarker(
                    layout: layout,
                    date: windowEnd,
                    label: windowEnd.formatted(date: .omitted, time: .shortened),
                    isPeak: false,
                    size: 28
                )
            }

            if let sunset = display.snapshot.sunset {
                sunMarker(
                    layout: layout,
                    date: sunset,
                    label: sunset.formatted(date: .omitted, time: .shortened),
                    isPeak: false,
                    size: 24
                )
            }
        }
    }

    private func sunMarker(
        layout: SunPathLayout,
        date: Date,
        label: String,
        detail: String? = nil,
        isPeak: Bool,
        size: CGFloat
    ) -> some View {
        let point = layout.point(for: date)

        return ZStack {
            sunGlyph(at: point, isPeak: isPeak, size: size)

            if isPeak {
                VStack(spacing: 2) {
                    Text("Solar Noon")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white.opacity(0.72))

                    if let detail {
                        Text(detail)
                            .font(.caption.weight(.black))
                            .foregroundStyle(.solarGold)
                    }
                }
                .position(x: point.x, y: point.y - size * 0.95)

                Text(label)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.92))
                    .position(x: point.x, y: point.y + size * 0.72)
            } else {
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .position(x: point.x, y: point.y + size * 0.72)
            }
        }
    }

    private func sunGlyph(at point: CGPoint, isPeak: Bool, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.solarGold.opacity(isPeak ? 0.55 : 0.38),
                            Color.solarOrange.opacity(isPeak ? 0.22 : 0.14),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.95
                    )
                )
                .frame(width: size * 1.85, height: size * 1.85)
                .blur(radius: isPeak ? 7 : 5)
                .position(point)

            Circle()
                .fill(Color.gpGatePill.opacity(isPeak ? 0.42 : 0.26))
                .frame(width: size * 0.72, height: size * 0.72)
                .blur(radius: isPeak ? 9 : 6)
                .position(point)

            Image(systemName: "sun.max.fill")
                .font(.system(size: size * 0.56, weight: .bold))
                .foregroundStyle(
                    isPeak
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.gpHiOrange, Color.gpGatePill],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color.solarGold)
                )
                .shadow(color: .solarGold.opacity(isPeak ? 0.85 : 0.55), radius: isPeak ? 10 : 6)
                .shadow(color: .solarOrange.opacity(isPeak ? 0.45 : 0.28), radius: isPeak ? 4 : 2)
                .position(point)
        }
    }

    private var summaryRow: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("D for")
                    .font(.bigDoseHeader(.title3).weight(.black))
                    .foregroundStyle(.white)

                Text(display.snapshot.durationLabel ?? "Unavailable")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.solarGold)
                    .contentTransition(.numericText())

                Spacer(minLength: 0)
            }

            Text(display.dayLabel.uppercased())
                .font(.caption.weight(.black))
                .tracking(1.8)
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var accessibilitySummary: String {
        let duration = display.snapshot.durationLabel ?? "unknown duration"
        let start = display.snapshot.windowStart?.formatted(date: .omitted, time: .shortened) ?? "unknown"
        let end = display.snapshot.windowEnd?.formatted(date: .omitted, time: .shortened) ?? "unknown"
        return "Vitamin D window \(display.dayLabel.lowercased()) from \(start) to \(end), lasting \(duration). Solar noon \(Int(display.snapshot.solarNoonAltitudeDegrees.rounded())) degrees."
    }
}

private struct SunPathLayout {
    var size: CGSize
    var snapshot: VitaminDWindowSnapshot

    var leftX: CGFloat { size.width * 0.07 }
    var rightX: CGFloat { size.width * 0.93 }
    var horizonY: CGFloat { size.height * 0.78 }
    var peakY: CGFloat { size.height * 0.12 }

    var thresholdY: CGFloat {
        y(forAltitude: snapshot.thresholdDegrees)
    }

    func x(for date: Date?) -> CGFloat? {
        guard let date, let sunrise = snapshot.sunrise, let sunset = snapshot.sunset else { return nil }
        let span = sunset.timeIntervalSince(sunrise)
        guard span > 0 else { return nil }
        let progress = min(max(date.timeIntervalSince(sunrise) / span, 0), 1)
        return leftX + CGFloat(progress) * (rightX - leftX)
    }

    func y(forAltitude altitude: Double) -> CGFloat {
        let maxAltitude = max(snapshot.solarNoonAltitudeDegrees, snapshot.thresholdDegrees, 1)
        let normalized = min(max(altitude / maxAltitude, 0), 1)
        return horizonY - CGFloat(normalized) * (horizonY - peakY)
    }

    func altitude(at date: Date) -> Double {
        guard let sunrise = snapshot.sunrise, let sunset = snapshot.sunset else { return 0 }
        let span = sunset.timeIntervalSince(sunrise)
        guard span > 0 else { return 0 }
        let progress = min(max(date.timeIntervalSince(sunrise) / span, 0), 1)
        return snapshot.solarNoonAltitudeDegrees * sin(progress * .pi)
    }

    func point(for date: Date) -> CGPoint {
        let xPosition = x(for: date) ?? size.width / 2
        return CGPoint(x: xPosition, y: y(forAltitude: altitude(at: date)))
    }

    func sunPathPoints() -> [CGPoint] {
        guard let sunrise = snapshot.sunrise, let sunset = snapshot.sunset else { return [] }

        let samples = 36
        let span = sunset.timeIntervalSince(sunrise)
        guard span > 0 else { return [] }

        return (0...samples).map { index in
            let date = sunrise.addingTimeInterval(span * Double(index) / Double(samples))
            return point(for: date)
        }
    }
}
