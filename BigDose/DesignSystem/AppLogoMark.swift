import SwiftUI

struct AppLogoMark: View {
    var size: CGFloat = 34

    var body: some View {
        Group {
            if let image = UIImage(named: "AppLogo") {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFill()
            } else {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: size * 0.55, weight: .bold))
                    .foregroundStyle(.solarGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.08))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
