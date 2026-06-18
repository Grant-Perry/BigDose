import SwiftUI

struct ProfileAvatarView: View {
    var imageData: Data?
    var diameter: CGFloat
    var showsEditBadge: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.18), lineWidth: 2)
                }

            if showsEditBadge {
                Image(systemName: "camera.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.solarOrange, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.black.opacity(0.25), lineWidth: 1)
                    }
                    .offset(x: 4, y: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(imageData == nil ? "Profile photo, not set" : "Profile photo")
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: diameter * 0.52, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
    }
}
