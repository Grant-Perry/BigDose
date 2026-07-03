import Foundation

enum DebugPrint {
    enum Mode: String, CaseIterable {
        case sunEvents
    }

    #if DEBUG
    static var enabledModes: Set<Mode> = [] // [.sunEvents]
    #else
    static var enabledModes: Set<Mode> = []
    #endif

    static func log(_ message: @autoclosure () -> String, mode: Mode) {
        guard enabledModes.contains(mode) else { return }
        print("[BigDose:\(mode.rawValue)] \(message())")
    }
}
