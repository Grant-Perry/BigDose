import SwiftUI

struct ProfileView: View {
    var profile: UserProfile?

    private var activeProfile: UserProfile {
        profile ?? .preview
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        title
                        profileCard
                        goalsCard
                        educationLink
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Profile")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(profile: profile)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.headline.weight(.semibold))
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Dose DNA")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("The inputs that make the sun meter personal.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var profileCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                ProfileRow(title: "Skin Type", value: "\(activeProfile.skinType.title) - \(activeProfile.skinType.subtitle)", systemImage: "person.crop.square")
                ProfileRow(title: "Biological Sex", value: activeProfile.biologicalSex.title, systemImage: "figure.stand")
                ProfileRow(title: "Typical Skin Exposed", value: "\(Int(activeProfile.typicalExposedBodySurfaceArea * 100))%", systemImage: "sun.max")
                ProfileRow(title: "Sunscreen", value: activeProfile.usuallyUsesSunscreen ? "Usually" : "Not usually", systemImage: "shield")
            }
        }
    }

    private var goalsCard: some View {
        GlassCard {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Vitamin D")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("Estimate only. Labs are the source of truth.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Text("\(Int(activeProfile.goalNanogramsPerMilliliter))")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("ng/mL")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var educationLink: some View {
        NavigationLink {
            EducationView()
        } label: {
            GlassCard(cornerRadius: 24) {
                Label("How BigDose Works", systemImage: "book.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(.solarGold)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.56))

                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    ProfileView(profile: .preview)
}
