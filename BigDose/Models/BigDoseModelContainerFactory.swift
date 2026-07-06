import Foundation
import SwiftData

enum BigDoseModelContainerFactory {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            SkinAssessment.self,
            ExposureSession.self,
            DailySunPlan.self,
            SupplementDose.self,
            FoodVitaminDEntry.self,
            LabResult.self,
            HealthImportBatch.self,
            HealthImportItem.self,
            BadgeAward.self,
            DailyProgressSummary.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )

        if inMemory {
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            guard isMigrationFailure(error) else { throw error }
            try backupStoreFiles(at: configuration.url)
            try removeStoreFiles(at: configuration.url)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
    }

    @MainActor
    static var preview: ModelContainer = {
        do {
            let container = try make(inMemory: true)
            container.mainContext.insert(UserProfile.preview)
            return container
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }()

    private static func isMigrationFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain && nsError.code == 134110 {
            return true
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSCocoaErrorDomain,
           underlying.code == 134110 {
            return true
        }

        return false
    }

    private static func backupStoreFiles(at url: URL) throws {
        let fileManager = FileManager.default
        let backupDirectory = url.deletingLastPathComponent().appending(
            path: "migration-backup-\(Int(Date.now.timeIntervalSince1970))",
            directoryHint: .isDirectory
        )

        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        let basePath = url.path
        for suffix in ["", "-shm", "-wal"] {
            let fileURL = URL(fileURLWithPath: basePath + suffix)
            guard fileManager.fileExists(atPath: fileURL.path) else { continue }
            let destination = backupDirectory.appending(path: fileURL.lastPathComponent)
            try fileManager.copyItem(at: fileURL, to: destination)
        }
    }

    private static func removeStoreFiles(at url: URL) throws {
        let fileManager = FileManager.default
        let basePath = url.path

        for suffix in ["", "-shm", "-wal"] {
            let fileURL = URL(fileURLWithPath: basePath + suffix)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }
}
