import SwiftUI

private enum PrecipitationChartStyle {
    static let precipBlue = Color(red: 0.38, green: 0.72, blue: 0.98)
    static let trackFill = Color.white.opacity(0.10)
    static let trackStroke = Color.white.opacity(0.14)
}

struct BigDoseHourlyForecastStrip: View {
    var forecast: [BigDoseHourlyForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(forecast) { hour in
                        BigDoseHourlyForecastItem(forecast: hour)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .background(forecastPanelBackground(accent: .gpHiLtBlue))
    }
}

private struct BigDoseHourlyForecastItem: View {
    var forecast: BigDoseHourlyForecast

    var body: some View {
        VStack(spacing: 6) {
            Text(hourLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))

            Image(systemName: forecast.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.solarGold)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 22)

            Text("\(Int(forecast.temperatureFahrenheit.rounded()))°")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
        }
        .frame(width: 54)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
    }

    private var hourLabel: String {
        forecast.date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }
}

struct BigDoseThreeDayForecastRow: View {
    var forecast: [BigDoseDailyForecast]
    var hourlyForecast: [BigDoseHourlyForecast]

    private var threeDayForecast: [BigDoseDailyForecast] {
        Array(forecast.prefix(3))
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(threeDayForecast) { day in
                BigDoseForecastDayColumn(
                    forecast: day,
                    hourlyChances: Self.hourlyPrecipChances(for: day.date, hourlyForecast: hourlyForecast, dailyChance: day.precipitationChance)
                )
            }
        }
        .padding(14)
        .background(forecastPanelBackground(accent: .gpSideBarLow))
    }

    static func hourlyPrecipChances(
        for day: Date,
        hourlyForecast: [BigDoseHourlyForecast],
        dailyChance: Double
    ) -> [Double] {
        let calendar = Calendar.current
        let dayHours = hourlyForecast.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let chances = dayHours.isEmpty ? Array(repeating: dailyChance, count: 12) : dayHours.map(\.precipitationChance)
        return downsampleChances(chances, targetCount: 12)
    }

    private static func downsampleChances(_ chances: [Double], targetCount: Int) -> [Double] {
        guard chances.count > targetCount else { return chances }

        return (0..<targetCount).map { index in
            let start = Int(Double(index) / Double(targetCount) * Double(chances.count))
            let end = Int(Double(index + 1) / Double(targetCount) * Double(chances.count))
            let slice = chances[start..<max(end, start + 1)]
            return slice.max() ?? 0
        }
    }
}

private struct BigDoseForecastDayColumn: View {
    var forecast: BigDoseDailyForecast
    var hourlyChances: [Double]

    var body: some View {
        VStack(spacing: 8) {
            Text(dayLabel)
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.72))

            Image(systemName: forecast.symbolName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.solarGold)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 24)

            PrecipDailySparkline(chances: hourlyChances)
                .frame(height: 34)

            precipSummary

            HStack(spacing: 4) {
                Text("\(Int(forecast.lowTemperatureFahrenheit.rounded()))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.52))

                Text("\(Int(forecast.highTemperatureFahrenheit.rounded()))")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(.white.opacity(0.05), in: .rect(cornerRadius: 16))
    }

    private var precipSummary: some View {
        HStack(spacing: 4) {
            if forecast.precipitationAmountInches > 0.005 {
                Text(forecast.precipitationAmountInches.formatted(.number.precision(.fractionLength(2))) + "\"")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PrecipitationChartStyle.precipBlue)
            }

            Text("\(Int(forecast.precipitationChance * 100))%")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(forecast.precipitationChance > 0 ? PrecipitationChartStyle.precipBlue : .white.opacity(0.42))
        }
    }

    private var dayLabel: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(forecast.date) {
            return "Today"
        }

        if calendar.isDateInTomorrow(forecast.date) {
            return "Tomorrow"
        }

        return forecast.date.formatted(.dateTime.weekday(.abbreviated))
    }
}

struct WeatherNextSixHoursPrecipPanel: View {
    var hourlyForecast: [BigDoseHourlyForecast]
    var totalRainInches: Double

    private let maxBarHeight: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Next 6 Hours", systemImage: "cloud.rain.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("Chance of rain")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.52))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(totalRainInches.formatted(.number.precision(.fractionLength(2))) + "\"")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)

                    Text(totalRainInches > 0.005 ? "Expected rain" : "Staying dry")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(totalRainInches > 0.005 ? PrecipitationChartStyle.precipBlue : .white.opacity(0.52))
                }
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(hourlyForecast) { hour in
                    PrecipHourlyColumn(
                        chance: hour.precipitationChance,
                        hourLabel: compactHourLabel(for: hour.date),
                        maxHeight: maxBarHeight
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(forecastPanelBackground(accent: .gpHiLtBlue))
    }

    private func compactHourLabel(for date: Date) -> String {
        date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
            .lowercased()
            .replacingOccurrences(of: "m", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

private struct PrecipHourlyColumn: View {
    var chance: Double
    var hourLabel: String
    var maxHeight: CGFloat

    private var normalizedChance: Double {
        min(max(chance, 0), 1)
    }

    private var hasPrecip: Bool {
        normalizedChance > 0
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(hasPrecip ? PrecipitationChartStyle.trackFill : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PrecipitationChartStyle.trackStroke, lineWidth: hasPrecip ? 0 : 1)
                    }
                    .frame(height: maxHeight)

                if hasPrecip {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(PrecipitationChartStyle.precipBlue)
                        .frame(height: max(maxHeight * normalizedChance, 6))
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 3) {
                if hasPrecip {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(PrecipitationChartStyle.precipBlue)
                }

                Text("\(Int(normalizedChance * 100))%")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(hasPrecip ? PrecipitationChartStyle.precipBlue : .white.opacity(0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(hourLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PrecipDailySparkline: View {
    var chances: [Double]

    private var displayChances: [Double] {
        let capped = Array(chances.prefix(24))
        guard !capped.isEmpty else { return [0] }
        return capped
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(displayChances.enumerated()), id: \.offset) { _, chance in
                PrecipThinBar(chance: chance)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PrecipThinBar: View {
    var chance: Double

    private let barHeight: CGFloat = 30
    private var normalizedChance: Double { min(max(chance, 0), 1) }
    private var hasPrecip: Bool { normalizedChance > 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(hasPrecip ? PrecipitationChartStyle.trackFill : .clear)
                .frame(width: 3, height: barHeight)

            if hasPrecip {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(PrecipitationChartStyle.precipBlue)
                    .frame(width: 3, height: max(barHeight * normalizedChance, 3))
            }
        }
    }
}

private func forecastPanelBackground(accent: Color) -> some View {
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
