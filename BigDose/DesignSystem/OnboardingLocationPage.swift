import CoreLocation
import SwiftUI

struct OnboardingLocationPage: View {
    var authorizationStatus: CLAuthorizationStatus
    var isRequesting = false
    var onEnable: () -> Void
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Turn on location for local weather and UV.")
                    .font(.bigDoseHeader(.largeTitle))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("BigDose uses your location to fetch Apple Weather, calculate sun angle and show today's vitamin D window. Location stays on your device for timing — it is not sold or shared.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                statusCard

                if authorizationStatus == .denied || authorizationStatus == .restricted {
                    Text("You can continue without location, but weather and UV guidance stay limited until you enable Location for BigDose in Settings.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                    BigDosePrimaryButton(title: "Continue", isEnabled: !isRequesting, action: onContinue)
                } else if authorizationStatus == .denied || authorizationStatus == .restricted {
                    BigDosePrimaryButton(title: "Continue Without Location", isEnabled: !isRequesting, action: onContinue)
                } else {
                    BigDosePrimaryButton(
                        title: isRequesting ? "Requesting Location…" : "Enable Location",
                        isEnabled: !isRequesting,
                        action: onEnable
                    )

                    Button("Continue Without Location", action: onContinue)
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .disabled(isRequesting)
                }
            }
            .padding(22)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var statusCard: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 12) {
                Image(systemName: statusSymbolName)
                    .font(.bigDoseHeader(.title2).weight(.semibold))
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Text(statusDetail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var statusSymbolName: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            "location.fill"
        case .denied, .restricted:
            "location.slash.fill"
        default:
            "location.circle.fill"
        }
    }

    private var statusColor: Color {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            .solarGold
        case .denied, .restricted:
            .solarOrange
        default:
            .gpHiLtBlue
        }
    }

    private var statusTitle: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            "Location enabled"
        case .denied, .restricted:
            "Location off"
        default:
            "Location needed for weather"
        }
    }

    private var statusDetail: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            "BigDose can load local weather, UV index and sun timing on Dashboard."
        case .denied, .restricted:
            "Enable Location for BigDose in Settings to load weather and UV on Dashboard."
        default:
            "Tap Enable Location so Dashboard weather and solar guidance work on first launch."
        }
    }
}
