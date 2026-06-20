import SwiftUI

struct StartSunSessionActionButton: View {
    enum Size {
        case compact
        case regular
        case prominent

        var diameter: CGFloat {
            switch self {
            case .compact:
                54
            case .regular:
                76
            case .prominent:
                88
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .compact:
                22
            case .regular:
                30
            case .prominent:
                34
            }
        }
    }

    var isEnabled = true
    var showsNoUsefulUV = false
    var size: Size
    var action: () -> Void

    private var usesActiveStartStyle: Bool {
        isEnabled && !showsNoUsefulUV
    }

    private var availableStartGradient: LinearGradient {
        LinearGradient(
            colors: [.gpBtnOn, .gpBtnOnL],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var noUsefulUVGradient: LinearGradient {
        LinearGradient(
            colors: [.gpBtnOff, .gpBtnOffL],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Start sun session")
        .accessibilityValue(showsNoUsefulUV ? "No useful UV" : "Use current UV")
    }

    @ViewBuilder
    private var content: some View {
        switch size {
        case .compact:
            VStack(spacing: 6) {
                sunCircle

                if !showsNoUsefulUV {
                    Text("Start")
                        .font(.caption.weight(.black))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.48))
                }
            }
            .frame(maxWidth: .infinity)

        case .regular, .prominent:
            HStack(spacing: 14) {
                sunCircle

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Sun Session")
                        .font(size == .prominent ? .title3.weight(.black) : .headline.weight(.black))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.48))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(showsNoUsefulUV ? "No Useful UV" : "Use current UV")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(isEnabled ? 0.64 : 0.38))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.bigDoseHeader(.headline).weight(.black))
                    .foregroundStyle(.white.opacity(isEnabled ? 0.58 : 0.28))
            }
            .frame(maxWidth: .infinity, minHeight: size == .prominent ? 96 : 76, alignment: .leading)
            .padding(size == .prominent ? 16 : 12)
            .background(cardBackground, in: .rect(cornerRadius: size == .prominent ? 28 : 26))
            .overlay(
                RoundedRectangle(cornerRadius: size == .prominent ? 28 : 26)
                    .stroke(cardBorderColor, lineWidth: 1)
            )
        }
    }

    private var cardBackground: LinearGradient {
        if usesActiveStartStyle {
            return availableStartGradient
        }

        if isEnabled && showsNoUsefulUV {
            return noUsefulUVGradient
        }

        return LinearGradient(
            colors: [.white.opacity(0.06), .white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardBorderColor: Color {
        if usesActiveStartStyle {
            .gpBtnOn.opacity(0.55)
        } else if isEnabled && showsNoUsefulUV {
            .gpBtnOff.opacity(0.55)
        } else {
            .white.opacity(0.1)
        }
    }

    private var sunCircle: some View {
        ZStack {
            Circle()
                .fill(sunCircleGradient)
                .frame(width: size.diameter, height: size.diameter)
                .shadow(color: sunCircleShadowColor, radius: usesActiveStartStyle || (isEnabled && showsNoUsefulUV) ? 18 : 0)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(isEnabled ? 0.24 : 0.1), lineWidth: 1)
                )

            Image(systemName: "sun.max.fill")
                .font(.system(size: size.iconSize, weight: .black))
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.42))
                .shadow(color: .deepSpace.opacity(0.35), radius: 3, y: 1)
        }
    }

    private var sunCircleGradient: LinearGradient {
        if usesActiveStartStyle {
            return availableStartGradient
        }

        if isEnabled && showsNoUsefulUV {
            return noUsefulUVGradient
        }

        return LinearGradient(
            colors: [.white.opacity(0.14), .white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var sunCircleShadowColor: Color {
        if usesActiveStartStyle {
            .gpBtnOn.opacity(0.65)
        } else if showsNoUsefulUV {
            .gpBtnOff.opacity(0.65)
        } else {
            .clear
        }
    }
}
