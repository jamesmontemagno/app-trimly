import AppIntents
import Foundation

nonisolated struct OpenWeightLogIntent: AppIntent {
    static let title = LocalizedStringResource(
        "platform.quickLog.title", defaultValue: "Log Weight", table: "PlatformFeatures"
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "platform.quickLog.description",
            defaultValue: "Open the weight entry form. Nothing is saved until you confirm.",
            table: "PlatformFeatures"
        )
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.requestQuickLog()
        return .result()
    }
}

nonisolated struct MyWeightShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenWeightLogIntent(),
            phrases: ["Log my weight in \(.applicationName)", "Open weight log in \(.applicationName)"],
            shortTitle: LocalizedStringResource(
                "platform.quickLog.title", defaultValue: "Log Weight", table: "PlatformFeatures"
            ),
            systemImageName: "plus.circle"
        )
    }
}
