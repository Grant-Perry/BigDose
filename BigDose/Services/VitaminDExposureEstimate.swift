import Foundation

struct VitaminDExposureEstimate {
    var estimatedIU: Double
    var targetDurationSeconds: TimeInterval
    var erythemaRiskFraction: Double
    var quality: SunWindowQuality

    var targetDurationMinutes: Int {
        max(0, Int((targetDurationSeconds / 60).rounded()))
    }

    var riskPercent: Int {
        Int((erythemaRiskFraction * 100).rounded())
    }
}
