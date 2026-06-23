import SwiftUI

enum CollapsibleGlassCardStyle {
    case textPreview(maxHeight: CGFloat = 48)
    case hidden
}

struct CollapsibleGlassCard<Header: View, Content: View>: View {
    var style: CollapsibleGlassCardStyle = .textPreview()
    var startsExpanded: Bool = false

    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    @State private var isExpanded: Bool

    init(
        style: CollapsibleGlassCardStyle = .textPreview(),
        startsExpanded: Bool = false,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.startsExpanded = startsExpanded
        _isExpanded = State(initialValue: startsExpanded)
        self.header = header
        self.content = content
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                header()

                Group {
                    switch style {
                    case .textPreview(let maxHeight):
                        if isExpanded {
                            content()
                        } else {
                            content()
                                .frame(maxHeight: maxHeight, alignment: .top)
                                .clipped()
                                .mask {
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .fill(.black)

                                        LinearGradient(
                                            colors: [.black, .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 22)
                                    }
                                }
                        }

                    case .hidden:
                        if isExpanded {
                            content()
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }

                toggleButton
            }
        }
        .animation(.snappy(duration: 0.28), value: isExpanded)
    }

    private var toggleButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 4) {
                Text(isExpanded ? "Show less" : "Read more")
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.solarGold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Show less" : "Read more")
    }
}
