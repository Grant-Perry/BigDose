import SwiftUI

struct InfoBoxView: View {
    var title: String
    var bodyText: String
    var sources: [BigDoseMedicalSource] = []
    var width: CGFloat = 280
    var maxBodyHeight: CGFloat = 340
    var titleIcon: String?
    var titleIconColor: Color = .cyan
    var onClose: (() -> Void)?

    private var formattedBody: AttributedString {
        InfoBoxMarkdown.attributedBody(from: bodyText)
    }

    var body: some View {
        InfoPanelChrome {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    if let titleIcon {
                        Image(systemName: titleIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(titleIconColor)
                    }

                    Text(title)
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Spacer(minLength: 0)

                    if let onClose {
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(formattedBody)
                            .lineLimit(nil)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !sources.isEmpty {
                            sourcesSection
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: maxBodyHeight)
            }
            .padding(18)
            .frame(width: width, alignment: .leading)
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .overlay(.white.opacity(0.18))

            Text("Sources")
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.72))

            ForEach(sources) { source in
                Link(destination: source.url) {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.solarGold)

                        Text(source.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.white.opacity(0.82))
            }
        }
        .accessibilityElement(children: .combine)
    }
}
