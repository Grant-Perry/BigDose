import UIKit

/// Chains short background tasks so Live Activity ContentState keeps updating while the phone is locked.
@MainActor
enum SunSessionLiveActivityBackgroundPusher {
    static func run(
        shouldContinue: @escaping @MainActor () -> Bool,
        tick: @escaping @MainActor () -> Void
    ) async {
        while !Task.isCancelled, shouldContinue() {
            tick()

            let slept = await sleepOneSecondWithBackgroundTask()
            if !slept || Task.isCancelled || !shouldContinue() {
                break
            }
        }
    }

    private static func sleepOneSecondWithBackgroundTask() async -> Bool {
        await withCheckedContinuation { continuation in
            var taskID = UIBackgroundTaskIdentifier.invalid
            var didResume = false

            func resume(_ value: Bool) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: value)
            }

            taskID = UIApplication.shared.beginBackgroundTask(withName: "BigDose.SunSessionLiveActivity") {
                if taskID != .invalid {
                    UIApplication.shared.endBackgroundTask(taskID)
                    taskID = .invalid
                }
                resume(false)
            }

            guard taskID != .invalid else {
                resume(false)
                return
            }

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                if taskID != .invalid {
                    UIApplication.shared.endBackgroundTask(taskID)
                }
                resume(true)
            }
        }
    }
}
