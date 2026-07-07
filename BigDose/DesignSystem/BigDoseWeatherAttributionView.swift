import SwiftUI

struct BigDoseWeatherAttribution: Equatable, Sendable {
    var attributionURL: URL
    var combinedMarkLightURL: URL?
    var combinedMarkDarkURL: URL?

    static let standard = BigDoseWeatherAttribution(
        attributionURL: BigDoseWeatherAttributionLegal.pageURL
    )

    init(
        attributionURL: URL,
        combinedMarkLightURL: URL? = nil,
        combinedMarkDarkURL: URL? = nil
    ) {
        self.attributionURL = attributionURL
        self.combinedMarkLightURL = combinedMarkLightURL
        self.combinedMarkDarkURL = combinedMarkDarkURL
    }

    init(weather: BigDoseWeatherSnapshot) {
        self.init(
            attributionURL: weather.attributionURL ?? Self.standard.attributionURL,
            combinedMarkLightURL: weather.combinedMarkLightURL,
            combinedMarkDarkURL: weather.combinedMarkDarkURL
        )
    }
}

struct BigDoseWeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme

    var attribution: BigDoseWeatherAttribution
    var foregroundOpacity: Double = 0.58

    init(weather: BigDoseWeatherSnapshot, foregroundOpacity: Double = 0.58) {
        self.attribution = BigDoseWeatherAttribution(weather: weather)
        self.foregroundOpacity = foregroundOpacity
    }

    init(attribution: BigDoseWeatherAttribution, foregroundOpacity: Double = 0.58) {
        self.attribution = attribution
        self.foregroundOpacity = foregroundOpacity
    }

    private var markURL: URL? {
        colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }

    var body: some View {
        HStack(spacing: 8) {
            appleWeatherMark

            Link(destination: attribution.attributionURL) {
                Text("Weather Data Sources")
                    .font(.caption2.weight(.semibold))
                    .underline()
            }
            .tint(.white.opacity(min(foregroundOpacity + 0.22, 0.88)))

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(foregroundOpacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Apple Weather data. Weather data sources legal attribution.")
        .accessibilityHint("Opens Apple's weather data sources page.")
    }

    @ViewBuilder
    private var appleWeatherMark: some View {
        if let markURL {
            AsyncImage(url: markURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 16)
                default:
                    Text("Weather")
                        .font(.caption2.weight(.bold))
                }
            }
        } else {
            Text("Weather")
                .font(.caption2.weight(.bold))
        }
    }
}
