import SwiftUI

struct BigDoseCompactWeatherAttributionView: View {
    var attributionURL: URL = BigDoseWeatherAttributionLegal.pageURL

    var body: some View {
        HStack(spacing: 6) {
            Text("Weather")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.52))

            Link(destination: attributionURL) {
                Text("Weather Data Sources")
                    .font(.system(size: 9, weight: .semibold))
                    .underline()
            }
            .tint(.white.opacity(0.72))

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Apple Weather data. Weather data sources legal attribution.")
    }
}
