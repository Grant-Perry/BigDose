import SwiftUI

struct InfoPanelChrome<Content: View>: View {
    var cornerRadius: CGFloat = 22
    var lineWidth: CGFloat = 4
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .siriBorder(cornerRadius: cornerRadius, lineWidth: lineWidth)
    }
}
