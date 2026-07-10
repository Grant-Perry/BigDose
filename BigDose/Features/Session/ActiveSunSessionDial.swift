import SwiftUI

struct ActiveSunSessionDial: View {
    @Environment(\.colorScheme) private var colorScheme

    var elapsedText: String
    var estimatedIU: Int
    var iuPerMinute: Int
    var goalProgress: Double
    var isTraceVitaminDConditions: Bool
    var isPaused: Bool

    private var clampedProgress: Double {
        min(max(goalProgress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)

            ZStack {
                dialSurface(diameter: diameter)
                trackRing
                progressRing

                if colorScheme == .dark {
                    tickMarks(diameter: diameter)
                }

                progressMarker(diameter: diameter)
                centerContent(diameter: diameter)
            }
            .frame(width: diameter, height: diameter)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 390)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(isPaused ? "Paused" : "Running"), \(elapsedText) elapsed, \(estimatedIU) IU, \(Int(goalProgress * 100)) percent of goal"
        )
    }

    private func dialSurface(diameter: CGFloat) -> some View {
        Circle()
            .fill(
                colorScheme == .dark
                    ? Color.black.opacity(0.34)
                    : Color.white.opacity(0.18)
            )
            .overlay {
                if colorScheme == .dark {
                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                        .padding(diameter * 0.06)
                }
            }
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.42) : .solarGold.opacity(0.1),
                radius: 24,
                y: 12
            )
    }

    @ViewBuilder
    private var trackRing: some View {
        if colorScheme == .dark {
            Circle()
                .stroke(.white.opacity(0.16), lineWidth: 6)
                .padding(10)
        } else {
            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(.solarGold.opacity(0.25), style: .init(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(90))
                .padding(8)
        }
    }

    @ViewBuilder
    private var progressRing: some View {
        if colorScheme == .dark {
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    BigDoseBrandGradients.heroAccent,
                    style: .init(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(10)
                .shadow(color: .solarGold.opacity(0.8), radius: 8)
        } else {
            Circle()
                .trim(from: 0.08, to: 0.08 + (0.84 * clampedProgress))
                .stroke(
                    BigDoseBrandGradients.heroAccent,
                    style: .init(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .padding(8)
        }
    }

    private func tickMarks(diameter: CGFloat) -> some View {
        ZStack {
            ForEach(0..<60, id: \.self) { tick in
                Capsule()
                    .fill(.solarGold.opacity(tick.isMultiple(of: 5) ? 0.72 : 0.3))
                    .frame(
                        width: tick.isMultiple(of: 5) ? 1.5 : 1,
                        height: tick.isMultiple(of: 5) ? 10 : 6
                    )
                    .offset(y: -(diameter / 2) + 20)
                    .rotationEffect(.degrees(Double(tick) * 6))
            }
        }
    }

    private func progressMarker(diameter: CGFloat) -> some View {
        Circle()
            .fill(.solarGoldBright)
            .frame(width: 28, height: 28)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.88), lineWidth: 2)
            }
            .background {
                if colorScheme == .dark {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    Color.solarGold.opacity(0.58),
                                    Color.solarGold.opacity(0.2),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 1,
                                endRadius: 38
                            )
                        )
                        .frame(width: 76, height: 76)
                        .blur(radius: 3)
                }
            }
            .shadow(color: .white.opacity(0.68), radius: 4)
            .shadow(
                color: .solarGold.opacity(colorScheme == .dark ? 0.98 : 0.72),
                radius: colorScheme == .dark ? 24 : 12
            )
            .offset(y: -(diameter / 2) + 16)
            .rotationEffect(.degrees(markerRotation))
    }

    private var markerRotation: Double {
        if colorScheme == .dark {
            return 360 * clampedProgress
        }

        return 208.8 + (302.4 * clampedProgress)
    }

    private func centerContent(diameter: CGFloat) -> some View {
        VStack(spacing: diameter * 0.025) {
            Image(systemName: isPaused ? "pause.fill" : "sun.max.fill")
                .font(.system(size: diameter * 0.07, weight: .light))
                .foregroundStyle(.solarGold)

            Text("ELAPSED SUN TIME")
                .font(.caption)
                .bold()
                .tracking(2)
                .foregroundStyle(secondaryText)

            Text(elapsedText)
                .font(.system(size: diameter * 0.22, weight: .medium, design: .monospaced))
                .foregroundStyle(primaryText)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Rectangle()
                .fill(primaryText.opacity(0.12))
                .frame(width: diameter * 0.32, height: 1)
                .padding(.vertical, diameter * 0.018)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(estimatedIU.formatted())
                    .font(.system(size: diameter * 0.13, weight: .medium, design: .rounded))
                Text("IU")
                    .font(.headline)
                    .bold()
            }
            .foregroundStyle(primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Label(
                isPaused ? "Dose frozen" : "\(iuPerMinute.formatted()) IU / MIN",
                systemImage: isPaused ? "pause.fill" : "bolt.fill"
            )
            .font(.subheadline)
            .bold()
            .foregroundStyle(rateColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(rateColor.opacity(0.1), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(rateColor.opacity(0.42), lineWidth: 1)
            }

            if isTraceVitaminDConditions {
                Text("TRACE VITAMIN D")
                    .font(.caption)
                    .bold()
                    .tracking(1)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(diameter * 0.12)
    }

    private var primaryText: Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.22, green: 0.13, blue: 0.07)
    }

    private var secondaryText: Color {
        primaryText.opacity(0.62)
    }

    private var rateColor: Color {
        if isPaused {
            return colorScheme == .dark ? .gpHiGreen : .green
        }

        if isTraceVitaminDConditions {
            return secondaryText
        }

        return colorScheme == .dark ? .gpHiGreen : .solarOrange
    }
}
