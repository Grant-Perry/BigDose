import SwiftUI

struct TemperatureRangeGauge: View {
    var low: Double
    var current: Double
    var high: Double

    private var progress: Double {
        guard high > low else { return 0.5 }
        return min(max((current - low) / (high - low), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(Int(low.rounded()))°")
                Spacer()
                Text("\(Int(current.rounded()))° now")
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(high.rounded()))°")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.62))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.14))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.gpHiLtBlue, Color.gpGatePill, Color.gpHiOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                        .offset(x: max(0, proxy.size.width * progress - 7))
                }
            }
            .frame(height: 12)
        }
    }
}

#Preview {
    TemperatureRangeGauge(low: 71, current: 82, high: 91)
        .padding()
        .background(.black)
}
