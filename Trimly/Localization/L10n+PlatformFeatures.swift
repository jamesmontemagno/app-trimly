import Foundation

extension L10n {
    enum PlatformFeatures {
        static let quickLogTitle = LocalizedStringResource("platform.quickLog.title", defaultValue: "Log Weight", table: "PlatformFeatures")
        static let quickLogDescription = LocalizedStringResource("platform.quickLog.description", defaultValue: "Open the weight entry form. Nothing is saved until you confirm.", table: "PlatformFeatures")
        static let healthLocalOnly = LocalizedStringResource("platform.health.localOnly", defaultValue: "Edits and deletions in TrimTally affect this app only. They do not change or delete records in Apple Health. Deleted imports may return on a later import.", table: "PlatformFeatures")
        static let healthDuplicateExplanation = LocalizedStringResource("platform.health.duplicateExplanation", defaultValue: "Duplicate checking compares weight and time (within 5 minutes), not Apple Health record IDs. Matching samples are skipped, not imported as hidden entries. Turning this off may import duplicates.", table: "PlatformFeatures")
        static let healthSkipDuplicates = LocalizedStringResource("platform.health.skipDuplicates", defaultValue: "Skip matching samples", table: "PlatformFeatures")
        static let healthNotAuthorized = LocalizedStringResource("platform.health.notAuthorized", defaultValue: "HealthKit access not authorized", table: "PlatformFeatures")
        static let healthNotAvailable = LocalizedStringResource("platform.health.notAvailable", defaultValue: "HealthKit is not available on this device", table: "PlatformFeatures")

        static func healthSkipped(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("platform.health.skipped", defaultValue: "Matching samples skipped: \(count)", table: "PlatformFeatures")
        }

        static func healthImportFailed(_ message: String) -> LocalizedStringResource {
            LocalizedStringResource("platform.health.importFailed", defaultValue: "Import failed: \(message)", table: "PlatformFeatures")
        }
    }
}
