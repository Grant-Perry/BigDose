import SwiftUI

struct BigDoseAlertAction: Identifiable {
    let id = UUID()
    var title: String
    var systemImage: String?
    var role: ButtonRole?
    var action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        role: ButtonRole? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    static func `default`(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) -> BigDoseAlertAction {
        BigDoseAlertAction(title, systemImage: systemImage, action: action)
    }

    static func cancel(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) -> BigDoseAlertAction {
        BigDoseAlertAction(title, systemImage: systemImage, role: .cancel, action: action)
    }

    static func destructive(
        _ title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) -> BigDoseAlertAction {
        BigDoseAlertAction(title, systemImage: systemImage, role: .destructive, action: action)
    }
}

struct BigDoseAlertContent {
    var title: String
    var message: String
    var actions: [BigDoseAlertAction]
}

struct BigDoseAlertView: View {
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

            actionsRow
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

    @ViewBuilder
    private var actionsRow: some View {
        switch actions.count {
        case 2:
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    actionButton(action)
                }
            }
        case 3:
            VStack(spacing: 10) {
                actionButton(actions[0])
                HStack(spacing: 10) {
                    actionButton(actions[1])
                    actionButton(actions[2])
                }
            }
        default:
            VStack(spacing: 10) {
                ForEach(actions) { action in
                    actionButton(action)
                }
            }
        }
    }

    private func actionButton(_ action: BigDoseAlertAction) -> some View {
        Button {
            action.action()
        } label: {
            Group {
                if let systemImage = action.systemImage {
                    Label(action.title, systemImage: systemImage)
                } else {
                    Text(action.title)
                }
            }
            .font(.bigDoseHeader(.subheadline).weight(.semibold))
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 10)
            .foregroundStyle(foregroundColor(for: action.role))
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor(for: action.role))
            }
        }
        .buttonStyle(.plain)
    }

    private func foregroundColor(for role: ButtonRole?) -> Color {
        switch role {
        case .destructive:
            isOpaque ? .black : .red
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

    private var opaqueSurfaceColor: Color {
        isOpaque ? .white : .deepSpace
    }

    private var primaryTextColor: Color {
        isOpaque ? .black : .white
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
            BigDoseAlertAction(action.title, systemImage: action.systemImage, role: action.role) {
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
            BigDoseAlertAction(action.title, systemImage: action.systemImage, role: action.role) {
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
