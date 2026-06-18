import SwiftData
import SwiftUI

struct ProfileView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            ProfileContent(profile: profile)
        } else {
            NavigationStack {
                ZStack {
                    BigDoseGradientBackground()
                    ProgressView("Loading profile")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .tint(.solarGold)
                }
                .navigationTitle("Profile")
                .toolbarTitleDisplayMode(.inline)
            }
        }
    }
}

private struct ProfileContent: View {
    @Bindable var profile: UserProfile

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        title
                        profileHero
                        profileCard
                        goalsCard
                        dataLinksCard
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

    private var profileHero: some View {
        NavigationLink {
            DoseDNAEditorView(profile: profile)
        } label: {
            GlassCard {
                HStack(spacing: 16) {
                    ProfileAvatarView(imageData: profile.avatarImageData, diameter: 72)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(profile.displayName.isEmpty ? "Add your name" : profile.displayName)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)

                        Text(profile.doseDNABiologicalSexSummary)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))

                        Label("Edit Profile", systemImage: "pencil")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.solarGold)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var profileCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Personal Inputs")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Spacer()

                    NavigationLink {
                        DoseDNAEditorView(profile: profile)
                    } label: {
                        Text("Edit")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.solarGold)
                    }
                }

                ProfileRow(title: "Skin Type", value: "\(profile.skinType.title) - \(profile.skinType.subtitle)", systemImage: "person.crop.square")
                ProfileRow(title: "Biological Sex", value: profile.doseDNABiologicalSexSummary, systemImage: "figure.stand")
                ProfileRow(title: "Typical Skin Exposed", value: "\(Int(profile.typicalExposedBodySurfaceArea * 100))%", systemImage: "sun.max")
                ProfileRow(title: "Incidental Sun", value: "\(profile.incidentalSunMinutesPerWeek) min/wk", systemImage: "figure.walk")
                ProfileRow(title: "Sunscreen", value: profile.usuallyUsesSunscreen ? "Usually" : "Not usually", systemImage: "shield")
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

                Text("\(Int(profile.goalNanogramsPerMilliliter))")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("ng/mL")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var dataLinksCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                NavigationLink {
                    LabResultsView()
                } label: {
                    ProfileLinkRow(title: "Lab Results", detail: "Record 25(OH)D values", systemImage: "testtube.2")
                }

                Divider().overlay(.white.opacity(0.12))

                NavigationLink {
                    SupplementLogView(profile: profile)
                } label: {
                    ProfileLinkRow(title: "Supplements", detail: "Log daily or one-off IU", systemImage: "pills.fill")
                }

                Divider().overlay(.white.opacity(0.12))

                NavigationLink {
                    RiskProfileView(profile: profile)
                } label: {
                    ProfileLinkRow(title: "Risk Snapshot", detail: "See current guidance inputs", systemImage: "shield.lefthalf.filled")
                }
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
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ProfileLinkRow: View {
    var title: String
    var detail: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(.solarGold)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.42))
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(BigDoseModelContainerFactory.preview)
}
