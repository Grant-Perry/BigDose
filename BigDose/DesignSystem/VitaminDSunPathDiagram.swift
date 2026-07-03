import SwiftUI

struct VitaminDSunPathDiagram: View {
    var display: VitaminDWindowDisplay
    var now: Date
    var currentSunAltitude: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var nowBeaconPulse = false

    private var chartSnapshot: VitaminDWindowSnapshot {
        display.snapshot
    }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { proxy in
                let layout = SunPathLayout(size: proxy.size, snapshot: chartSnapshot)
                ZStack {
                    thresholdBand(layout: layout)
                    horizonLine(layout: layout)
                    sunPath(layout: layout)
                    thresholdLine(layout: layout)
                    markerLayer(layout: layout)
                    daylightDurationLabels(layout: layout)
                    currentSunMarker(layout: layout)
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

    @ViewBuilder
    private func daylightDurationLabels(layout: SunPathLayout) -> some View {
        if let components = chartSnapshot.daylightDurationComponents {
            BigDoseDurationText(
                components,
                font: .caption2.weight(.semibold),
                valueColor: .white.opacity(0.44),
                unitColor: .white.opacity(0.3)
            )
            .position(x: layout.size.width / 2, y: layout.horizonY - 9)

            if !daylightDurationDeltaLabel.isEmpty {
                Text(daylightDurationDeltaLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .position(x: layout.size.width / 2, y: layout.horizonY + 11)
            }
        }
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
            if let sunrise = chartSnapshot.sunrise {
                sunMarker(
                    layout: layout,
                    date: sunrise,
                    label: BigDoseSunTimeFormat.label(for: sunrise),
                    isPeak: false,
                    size: 24
                )
            }

            if let windowStart = chartSnapshot.windowStart {
                sunMarker(
                    layout: layout,
                    date: windowStart,
                    label: BigDoseSunTimeFormat.label(for: windowStart),
                    isPeak: false,
                    size: 28
                )
            }

            sunMarker(
                layout: layout,
                date: chartSnapshot.solarNoon,
                label: BigDoseSunTimeFormat.label(for: chartSnapshot.solarNoon),
                detail: "\(Int(chartSnapshot.solarNoonAltitudeDegrees.rounded()))°",
                isPeak: true,
                size: 38
            )

            if let windowEnd = chartSnapshot.windowEnd {
                sunMarker(
                    layout: layout,
                    date: windowEnd,
                    label: BigDoseSunTimeFormat.label(for: windowEnd),
                    isPeak: false,
                    size: 28
                )
            }

            if let sunset = chartSnapshot.sunset {
                sunMarker(
                    layout: layout,
                    date: sunset,
                    label: BigDoseSunTimeFormat.label(for: sunset),
                    isPeak: false,
                    size: 24
                )
            }
        }
    }

    @ViewBuilder
    private func currentSunMarker(layout: SunPathLayout) -> some View {
        if let point = currentSunPoint(layout: layout),
           let altitude = currentSunAltitude {
            let roundedAltitude = Int(altitude.rounded())
            let dotSize: CGFloat = 15
            let noonX = layout.point(for: chartSnapshot.solarNoon).x
            let isBeforeNoon = point.x < noonX
            let labelX = point.x + (isBeforeNoon ? -22 : 22)
            let labelY = point.y - 30
            let stemEnd = CGPoint(
                x: labelX + (isBeforeNoon ? 10 : -10),
                y: labelY + 11
            )

            ZStack {
                Circle()
                    .stroke(Color.gpHiYellow.opacity(reduceMotion ? 0.35 : (nowBeaconPulse ? 0 : 0.6)), lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .scaleEffect(reduceMotion ? 1.25 : (nowBeaconPulse ? 1.85 : 1))
                    .position(point)

                Circle()
                    .fill(Color.gpHiYellow)
                    .frame(width: dotSize, height: dotSize)
                    .overlay {
                        Circle()
                            .strokeBorder(.black.opacity(0.22), lineWidth: 1.5)
                    }
                    .shadow(color: Color.gpHiYellow.opacity(0.85), radius: 10)
                    .position(point)

                Path { path in
                    path.move(to: point)
                    path.addLine(to: stemEnd)
                }
                .stroke(Color.gpHiYellow.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2, 3]))

                Text("Now")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.55), in: .capsule)
                    .overlay {
                        Capsule()
                            .stroke(Color.gpHiYellow.opacity(0.55), lineWidth: 1)
                    }
                    .position(x: labelX, y: labelY)
            }
            .onAppear {
                startNowBeaconPulse()
            }
            .accessibilityLabel("Sun now at \(roundedAltitude) degrees")
        }
    }

    private func startNowBeaconPulse() {
        guard !reduceMotion else { return }

        nowBeaconPulse = false
        withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
            nowBeaconPulse = true
        }
    }

    private func currentSunPoint(layout: SunPathLayout) -> CGPoint? {
        guard
            display.isToday,
            let altitude = currentSunAltitude,
            altitude > 0,
            let sunrise = chartSnapshot.sunrise,
            let sunset = chartSnapshot.sunset,
            now >= sunrise,
            now <= sunset
        else { return nil }

        return layout.point(for: now)
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
            sunGlyph(at: point, isPeak: isPeak, size: size, accent: nil)

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

    private func sunGlyph(at point: CGPoint, isPeak: Bool, size: CGFloat, accent: Color?) -> some View {
        let glowColor = accent ?? .solarGold
        let iconStyle: AnyShapeStyle = {
            if isPeak {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.gpHiOrange, Color.gpGatePill],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            if let accent {
                return AnyShapeStyle(accent)
            }
            return AnyShapeStyle(Color.solarGold)
        }()

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(isPeak ? 0.55 : accent == nil ? 0.38 : 0.48),
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
                .fill(Color.gpGatePill.opacity(isPeak ? 0.42 : accent == nil ? 0.26 : 0.34))
                .frame(width: size * 0.72, height: size * 0.72)
                .blur(radius: isPeak ? 9 : 6)
                .position(point)

            Image(systemName: "sun.max.fill")
                .font(.system(size: size * 0.56, weight: .bold))
                .foregroundStyle(iconStyle)
                .shadow(color: glowColor.opacity(isPeak ? 0.85 : 0.72), radius: isPeak ? 10 : 8)
                .shadow(color: .solarOrange.opacity(isPeak ? 0.45 : 0.32), radius: isPeak ? 4 : 3)
                .position(point)
        }
    }

    private var summaryRow: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("D for")
                    .font(.bigDoseHeader(.title3).weight(.black))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 0) {
                    if let components = display.snapshot.durationComponents {
                        BigDoseDurationText(
                            components,
                            font: .system(size: 34, weight: .black),
                            valueColor: .solarGold
                        )
                        .contentTransition(.numericText())
                    } else {
                        Text("Unavailable")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.solarGold)
                    }

                    if let remainingComponents = display.remainingWindowDurationComponents(at: now) {
                        HStack(spacing: 0) {
                            BigDoseDurationText(
                                remainingComponents,
                                font: .caption.weight(.semibold),
                                valueColor: .secondary
                            )

                            Text(" remaining")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .offset(y: -5)
                    }
                }

                InfoCircleButton(topic: .dForDuration, iconSize: 16)

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
        let duration = chartSnapshot.durationLabel ?? "unknown duration"
        let remaining = display.remainingWindowDurationLabel(at: now).map { "\($0) remaining" }
        let start = chartSnapshot.windowStart?.formatted(date: .omitted, time: .shortened) ?? "unknown"
        let end = chartSnapshot.windowEnd?.formatted(date: .omitted, time: .shortened) ?? "unknown"
        let remainingPhrase = remaining.map { ", \($0)" } ?? ""
        let sunNowPhrase = currentSunAltitude.map { altitude in
            display.isToday && altitude > 0 ? ", sun now at \(Int(altitude.rounded())) degrees" : ""
        } ?? ""
        let daylightPhrase = chartSnapshot.daylightDurationLabel.map { ", \($0) of daylight" } ?? ""
        let daylightDeltaPhrase = daylightDurationDeltaLabel.isEmpty ? "" : ", \(daylightDurationDeltaLabel)"
        return "Vitamin D window \(display.dayLabel.lowercased()) from \(start) to \(end), lasting \(duration)\(remainingPhrase)\(daylightPhrase)\(daylightDeltaPhrase)\(sunNowPhrase). Solar noon \(Int(chartSnapshot.solarNoonAltitudeDegrees.rounded())) degrees."
    }

    private var daylightDurationDeltaLabel: String {
        guard let current = chartSnapshot.daylightDuration else { return "" }
        guard let previous = display.previousDaylightDuration else {
            return "Compared to yesterday unavailable"
        }
        return VitaminDWindowDisplay.daylightDurationDeltaLabel(
            current: current,
            previous: previous,
            referenceDayName: display.isToday ? "yesterday" : "today"
        )
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
