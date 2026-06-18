import SwiftUI

struct WeatherTemperatureCard: View {
    var current: Double
    var feelsLike: Double
    var low: Double
    var high: Double

    private var gaugeRange: ClosedRange<Double> {
        let adjustedLow = min(low, current)
        let adjustedHigh = max(high, current, adjustedLow + 1)
        return adjustedLow...adjustedHigh
    }

    var body: some View {
        BigDoseWeatherTile(accent: BigDoseTemperatureColor.color(for: current)) {
            VStack(spacing: 7) {
                WeatherTileHeader(icon: "thermometer.medium", title: "Temp", accent: BigDoseTemperatureColor.color(for: current))

                Gauge(value: current, in: gaugeRange) {
                    Text("Temp")
                } currentValueLabel: {
                    Text("\(Int(current.rounded()))")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(
                    Gradient(colors: [
                        Color.gpHiDkBlue,
                        Color.gpSideBarLow,
                        BigDoseTemperatureColor.color(for: high)
                    ])
                )
                .frame(width: 58, height: 58)
                .scaleEffect(1.18)

                HStack(spacing: 3) {
                    Text("\(Int(low.rounded()))°")
                        .foregroundStyle(Color.gpSideBarLow)
                    Text("/")
                        .foregroundStyle(.white.opacity(0.55))
                    Text("\(Int(high.rounded()))°")
                        .foregroundStyle(BigDoseTemperatureColor.color(for: high))
                }
                .font(.caption.weight(.semibold))

                Text("Feels \(Int(feelsLike.rounded()))°")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }
}

struct WeatherRingMetricCard: View {
    var icon: String
    var title: String
    var value: String
    var subtitle: String
    var progress: Double
    var accent: Color

    @State private var animatedProgress = 0.0

    var body: some View {
        BigDoseWeatherTile(accent: accent) {
            VStack(spacing: 7) {
                WeatherTileHeader(icon: icon, title: title, accent: accent)

                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.14), lineWidth: 9)

                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            LinearGradient(colors: [accent.opacity(0.75), accent], startPoint: .bottomLeading, endPoint: .topTrailing),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text(value)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: 62, height: 62)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .onAppear {
            animate()
        }
        .onChange(of: progress) {
            animate()
        }
    }

    private func animate() {
        withAnimation(.smooth(duration: 0.8)) {
            animatedProgress = min(max(progress, 0), 1)
        }
    }
}

struct WeatherWindCard: View {
    var speed: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        BigDoseWeatherTile(accent: .gpActivePlanGlow) {
            VStack(spacing: 7) {
                WeatherTileHeader(icon: "wind", title: "Wind", accent: .gpActivePlanGlow)

                ZStack {
                    Circle()
                        .stroke(Color.gpActivePlanGlow.opacity(0.22), lineWidth: 9)

                    Circle()
                        .stroke(Color.gpActivePlanGlow.opacity(0.42), lineWidth: 9)
                        .scaleEffect(pulse ? 1.04 : 0.96)

                    Image(systemName: "location.north.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.gpActivePlanGlow)
                        .rotationEffect(.degrees(225))

                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(Int(speed.rounded()))")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("mph")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.66))
                    }
                    .offset(y: 14)
                }
                .frame(width: 62, height: 62)
            }
        }
        .onAppear {
            playPulse()
        }
        .onChange(of: speed) {
            playPulse()
        }
    }

    private func playPulse() {
        guard !reduceMotion else { return }
        pulse = false
        withAnimation(.easeInOut(duration: 0.75)) {
            pulse = true
        }
    }
}

struct BigDoseWeatherTile<Content: View>: View {
    var accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 118)
            .padding(9)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(accent.opacity(0.10))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    }
            }
            .shadow(color: accent.opacity(0.14), radius: 8, x: 0, y: 5)
    }
}

struct WeatherTileHeader: View {
    var icon: String
    var title: String
    var accent: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(accent)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}
