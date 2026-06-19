import SwiftUI

struct HomeHeroHeader: View {
    @Bindable var profile: UserProfile
    var vitaminDWindowDisplay: VitaminDWindowDisplay?
    var detail: String

    var body: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 18) {
                profileRow

                if let vitaminDWindowDisplay {
                    NextDOpportunityBanner(display: vitaminDWindowDisplay, detail: detail)
                } else {
                    fallbackPanel
                }
            }
            .overlay(alignment: .topTrailing) {
                avatarButton
            }
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.solarGold.opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 180, height: 180)
                .offset(x: 36, y: -48)
                .allowsHitTesting(false)
        }
    }

    private var avatarButton: some View {
        NavigationLink {
            DoseDNAEditorContainer(profile: profile)
        } label: {
            ProfileAvatarView(
                imageData: profile.avatarImageData,
                diameter: 76,
                showsEditBadge: profile.avatarImageData == nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit profile photo")
        .offset(x: 4, y: -4)
    }

    private var profileRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))

            nameRow
        }
        .padding(.trailing, 84)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameRow: some View {
        HStack(spacing: 8) {
            Text(displayName)
                .font(.system(.title, weight: .black))
                .foregroundStyle(displayNameIsPlaceholder ? .white.opacity(0.72) : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            NavigationLink {
                DoseDNAEditorContainer(profile: profile)
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.solarGold)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit profile")
        }
    }

    private var fallbackPanel: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sun.max.trianglebadge.exclamationmark.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(.solarGold)

            VStack(alignment: .leading, spacing: 5) {
                Text("Today's Plan")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.solarGold)
                    .textCase(.uppercase)

                Text("Ready when the sun is")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Welcome back"
        }
    }

    private var trimmedDisplayName: String {
        profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayNameIsPlaceholder: Bool {
        trimmedDisplayName.isEmpty
    }

    private var displayName: String {
        displayNameIsPlaceholder ? "Add your name" : trimmedDisplayName
    }
}
