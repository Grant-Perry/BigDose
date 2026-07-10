import SwiftUI

struct BigDoseAlertAction: Identifiable {
    let id = UUID()
    var title: String
    var role: ButtonRole?
    var action: () -> Void

    init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
        self.title = title
        self.role = role
        self.action = action
    }

    static func `default`(_ title: String, action: @escaping () -> Void = {}) -> BigDoseAlertAction {
        BigDoseAlertAction(title, action: action)
    }

    static func cancel(_ title: String, action: @escaping () -> Void = {}) -> BigDoseAlertAction {
        BigDoseAlertAction(title, role: .cancel, action: action)
    }

    static func destructive(_ title: String, action: @escaping () -> Void = {}) -> BigDoseAlertAction {
        BigDoseAlertAction(title, role: .destructive, action: action)
    }
}

struct BigDoseAlertContent {
    var title: String
    var message: String
    var actions: [BigDoseAlertAction]
}

struct BigDoseAlertView: View {
    @Environment(\.colorScheme) private var colorScheme

    var title: String
    var message: String
    var actions: [BigDoseAlertAction]
    var cornerRadius: CGFloat = 22
    var trailingImageName: String?
    var isOpaque = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.bigDoseHeader(.headline).weight(.bold))
                    .foregroundStyle(primaryTextColor)
                    .accessibilityAddTraits(.isHeader)

                if !message.isEmpty {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(primaryTextColor.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.trailing, 42)

            VStack(spacing: 10) {
                ForEach(actions) { action in
                    Button {
                        action.action()
                    } label: {
                        Text(action.title)
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(foregroundColor(for: action.role))
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(backgroundColor(for: action.role))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .bigDoseGlass(
            cornerRadius: cornerRadius,
            opaqueColor: isOpaque ? opaqueSurfaceColor : nil
        )
        .overlay(alignment: .topTrailing) {
            if let trailingImageName {
                Image(trailingImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(.rect(cornerRadius: 8, style: .continuous))
                    .padding(14)
                    .accessibilityLabel("Apple Health app icon")
            } else {
                AppLogoMark(size: 34)
                    .padding(14)
            }
        }
        .padding(.horizontal, 36)
        .accessibilityElement(children: .contain)
    }

    private func foregroundColor(for role: ButtonRole?) -> Color {
        switch role {
        case .destructive:
            .red
        default:
            primaryTextColor
        }
    }

    private func backgroundColor(for role: ButtonRole?) -> Color {
        switch role {
        case .destructive:
            .red.opacity(0.18)
        default:
            primaryTextColor.opacity(0.1)
        }
    }

    private var usesLightOpaqueSurface: Bool {
        isOpaque && colorScheme == .dark
    }

    private var opaqueSurfaceColor: Color {
        usesLightOpaqueSurface ? .white : .deepSpace
    }

    private var primaryTextColor: Color {
        usesLightOpaqueSurface ? .black : .white
    }
}

extension View {
    func bigDoseAlert(
        _ title: String,
        isPresented: Binding<Bool>,
        message: String = "",
        actions: [BigDoseAlertAction],
        backdropOpacity: Double = 0.35,
        trailingImageName: String? = nil,
        isOpaque: Bool = false
    ) -> some View {
        modifier(
            BigDoseAlertPresentationModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                actions: actions,
                backdropOpacity: backdropOpacity,
                trailingImageName: trailingImageName,
                isOpaque: isOpaque
            )
        )
    }

    func bigDoseAlert<Item: Identifiable & Equatable>(
        item: Binding<Item?>,
        isOpaque: Bool = false,
        content: @escaping (Item) -> BigDoseAlertContent
    ) -> some View {
        modifier(
            BigDoseAlertItemModifier(
                item: item,
                isOpaque: isOpaque,
                content: content
            )
        )
    }
}

private struct BigDoseAlertPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    var title: String
    var message: String
    var actions: [BigDoseAlertAction]
    var backdropOpacity: Double
    var trailingImageName: String?
    var isOpaque: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                BigDoseAlertOverlay(
                    title: title,
                    message: message,
                    actions: wrappedActions,
                    backdropOpacity: backdropOpacity,
                    trailingImageName: trailingImageName,
                    isOpaque: isOpaque
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(999)
            }
        }
        .animation(.smooth(duration: 0.28), value: isPresented)
    }

    private var wrappedActions: [BigDoseAlertAction] {
        actions.map { action in
            BigDoseAlertAction(action.title, role: action.role) {
                isPresented = false
                action.action()
            }
        }
    }
}

private struct BigDoseAlertItemModifier<Item: Identifiable & Equatable>: ViewModifier {
    @Binding var item: Item?
    var isOpaque: Bool
    var content: (Item) -> BigDoseAlertContent

    func body(content view: Content) -> some View {
        view.overlay {
            if let currentItem = item {
                let alertContent = content(currentItem)
                BigDoseAlertOverlay(
                    title: alertContent.title,
                    message: alertContent.message,
                    actions: wrappedActions(for: alertContent.actions),
                    isOpaque: isOpaque
                )
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(999)
            }
        }
        .animation(.smooth(duration: 0.28), value: item)
    }

    private func wrappedActions(for actions: [BigDoseAlertAction]) -> [BigDoseAlertAction] {
        actions.map { action in
            BigDoseAlertAction(action.title, role: action.role) {
                item = nil
                action.action()
            }
        }
    }
}

private struct BigDoseAlertOverlay: View {
    var title: String
    var message: String
    var actions: [BigDoseAlertAction]
    var backdropOpacity: Double = 0.35
    var trailingImageName: String?
    var isOpaque = false

    var body: some View {
        ZStack {
            Color.black.opacity(backdropOpacity)
                .ignoresSafeArea()

            BigDoseAlertView(
                title: title,
                message: message,
                actions: actions,
                trailingImageName: trailingImageName,
                isOpaque: isOpaque
            )
        }
        .accessibilityAddTraits(.isModal)
    }
}
