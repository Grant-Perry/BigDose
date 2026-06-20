import Foundation

nonisolated enum SunSessionLiveActivityCommand: String, Codable, Sendable {
    case pause
    case resume
    case end
}

nonisolated enum SunSessionLiveActivityCommandStore {
    private static let commandKey = "bigdose.liveactivity.command"
    private static let sessionIDKey = "bigdose.liveactivity.command.sessionID"
    private static let postedAtKey = "bigdose.liveactivity.command.postedAt"

    nonisolated static func request(_ command: SunSessionLiveActivityCommand, sessionID: String) {
        guard let defaults = UserDefaults(suiteName: BigDoseAppGroup.identifier) else { return }
        defaults.set(command.rawValue, forKey: commandKey)
        defaults.set(sessionID, forKey: sessionIDKey)
        defaults.set(Date.now.timeIntervalSince1970, forKey: postedAtKey)
    }

    nonisolated static func consume(for sessionID: String) -> SunSessionLiveActivityCommand? {
        guard let command = peek(for: sessionID) else { return nil }
        clearPending(for: sessionID)
        return command
    }

    nonisolated static func peek(for sessionID: String) -> SunSessionLiveActivityCommand? {
        guard let defaults = UserDefaults(suiteName: BigDoseAppGroup.identifier) else { return nil }
        guard defaults.string(forKey: sessionIDKey) == sessionID,
              let raw = defaults.string(forKey: commandKey),
              let command = SunSessionLiveActivityCommand(rawValue: raw)
        else {
            return nil
        }

        return command
    }

    nonisolated static func hasPendingEnd(for sessionID: String) -> Bool {
        peek(for: sessionID) == .end
    }

    nonisolated static func clearPending(for sessionID: String) {
        guard let defaults = UserDefaults(suiteName: BigDoseAppGroup.identifier) else { return }
        guard defaults.string(forKey: sessionIDKey) == sessionID else { return }
        defaults.removeObject(forKey: commandKey)
        defaults.removeObject(forKey: sessionIDKey)
        defaults.removeObject(forKey: postedAtKey)
    }
}
