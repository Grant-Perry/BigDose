import AudioToolbox
import UIKit

enum BigDoseAlertFeedback {
    enum Kind {
        case informational
        case warning
        case critical

        var haptic: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .informational:
                .success
            case .warning:
                .warning
            case .critical:
                .error
            }
        }

        var alertSoundID: SystemSoundID {
            switch self {
            case .informational:
                1_007
            case .warning:
                1_007
            case .critical:
                1_005
            }
        }
    }

    @MainActor
    static func present(kind: Kind = .warning) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(kind.haptic)
        AudioServicesPlayAlertSound(kind.alertSoundID)
    }
}
