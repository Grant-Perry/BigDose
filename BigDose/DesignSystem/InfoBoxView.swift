import SwiftUI

struct InfoBoxView: View {
    var title: String
    var bodyText: String
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
                    Text(formattedBody)
                        .lineLimit(nil)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: maxBodyHeight)
            }
            .padding(18)
            .frame(width: width, alignment: .leading)
        }
    }
}
