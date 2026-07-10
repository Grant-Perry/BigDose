import SwiftUI

struct DashboardStartNewCaption: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("START")
            Text("NEW")
        }
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(.solarGold)
        .multilineTextAlignment(.center)
    }
}
