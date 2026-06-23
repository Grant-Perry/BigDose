import SwiftUI

struct HomeHeroHeader: View {
    @Bindable var profile: UserProfile
    var todayGoalProgress: Double
    var todaySunIU: Double
    var targetIU: Int
    var vitaminDWindowDisplay: VitaminDWindowDisplay?
    var now: Date
    var isSunSessionStartEnabled = true
    var showsNoUsefulUV = false
    var onStartSunSession: () -> Void = {}

    private let avatarDiameter: CGFloat = 88

    private var avatarOverflow: CGFloat {
        avatarDiameter * 0.5
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GlassCard(cornerRadius: 28) {
                VStack(alignment: .leading, spacing: 18) {
                    profileRow

                    if let vitaminDWindowDisplay {
                        NextDOpportunityBanner(
                            display: vitaminDWindowDisplay,
                            now: now,
                            todayGoalProgress: todayGoalProgress,
                            todaySunIU: todaySunIU,
                            targetIU: targetIU,
                            isSunSessionStartEnabled: isSunSessionStartEnabled,
                            showsNoUsefulUV: showsNoUsefulUV,
                            onStartSunSession: onStartSunSession
                        )
                    } else {
                        fallbackPanel
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            avatarCluster
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .offset(x: avatarOverflow, y: -avatarOverflow)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, avatarOverflow)
        .padding(.bottom, -avatarOverflow)
        .offset(y: -avatarOverflow)
    }

    private var avatarCluster: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.solarGold.opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 72
                    )
                )
                .frame(width: 150, height: 150)
                .opacity(0.9)
                .allowsHitTesting(false)

            avatarButton
        }
    }

    private var avatarButton: some View {
        NavigationLink {
            DoseDNAEditorContainer(profile: profile)
        } label: {
            ProfileAvatarView(
                imageData: profile.avatarImageData,
                diameter: avatarDiameter,
                showsEditBadge: profile.avatarImageData == nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit profile photo")
    }

    private var profileRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))

            nameRow
        }
        .padding(.trailing, avatarDiameter * 0.62)
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
                    .font(.bigDoseHeader(.title2).weight(.semibold))
                    .foregroundStyle(.solarGold)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit profile")
        }
    }

    private var fallbackPanel: some View {
        let goalDialDiameter: CGFloat = 96 * 0.85

        return HStack(alignment: .center, spacing: 14) {
            Image(systemName: "sun.max.trianglebadge.exclamationmark.fill")
                .font(.bigDoseHeader(.title2).weight(.bold))
                .foregroundStyle(.solarGold)

            VStack(alignment: .leading, spacing: 5) {
                Text("Today's Plan")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.solarGold)
                    .textCase(.uppercase)

                Text("Ready when the sun is")
                    .font(.bigDoseHeader(.headline).weight(.black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(Int(todaySunIU.rounded())) / \(targetIU) IU sun")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))

                HStack(spacing: 4) {
                    Text("Recommended sun target")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.42))
                    InfoCircleButton(topic: .dailyIUTarget, iconSize: 10, compact: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .padding(.trailing, goalDialDiameter + 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .overlay(alignment: .trailing) {
            todayGoalDialButton(diameter: goalDialDiameter, showsNoUsefulUV: showsNoUsefulUV)
                .padding(.trailing, 12)
        }
    }

    private func todayGoalDialButton(diameter: CGFloat, showsNoUsefulUV: Bool = false) -> some View {
        Button(action: onStartSunSession) {
            SunSessionGoalDialView(
                goalProgress: todayGoalProgress,
                goalTimerInterval: nil,
                isPaused: true,
                diameter: diameter,
                lineWidth: 5,
                progressCaption: "IU goal",
                showsNoUsefulUV: showsNoUsefulUV
            )
            .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .disabled(!isSunSessionStartEnabled)
        .opacity(isSunSessionStartEnabled ? 1 : 0.48)
        .accessibilityLabel("Start sun session")
        .accessibilityValue("\(Int(todayGoalProgress * 100)) percent of daily goal")
        .accessibilityHint(isSunSessionStartEnabled ? "Starts a new sun session" : "Weather data required to start a sun session")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
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
