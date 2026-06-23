import SwiftUI

struct BigDosePrimaryButton: View {
    enum Style {
        case prominent
        case light
        case success
        case accent

        var gradient: LinearGradient {
            switch self {
            case .prominent:
                LinearGradient(
                    colors: [.solarOrange, Color(red: 1.0, green: 0.58, blue: 0.14), .solarGold],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .light:
                LinearGradient(
                    colors: [.white, Color.white.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .success:
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.78, blue: 0.44), Color(red: 0.10, green: 0.62, blue: 0.34)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .accent:
                LinearGradient(
                    colors: [Color(red: 0.22, green: 0.52, blue: 0.98), Color(red: 0.12, green: 0.38, blue: 0.86)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        var glowColor: Color {
            switch self {
            case .prominent:
                .solarOrange
            case .light:
                .white
            case .success:
                Color(red: 0.18, green: 0.78, blue: 0.44)
            case .accent:
                Color(red: 0.22, green: 0.52, blue: 0.98)
            }
        }

        var foregroundStyle: Color {
            switch self {
            case .prominent, .success, .accent:
                .white
            case .light:
                .solarOrange
            }
        }
    }

    var title: String
    var systemImage: String?
    var style: Style = .prominent
    var isEnabled: Bool = true
    var action: () -> Void

    private let cornerRadius: CGFloat = 22

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.bigDoseHeader(.headline).weight(.semibold))
            .foregroundStyle(style.foregroundStyle)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(style.gradient)
                    .shadow(color: style.glowColor.opacity(isEnabled ? 0.55 : 0), radius: 18, y: 8)
                    .shadow(color: style.glowColor.opacity(isEnabled ? 0.28 : 0), radius: 6, y: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.42)
    }
}
