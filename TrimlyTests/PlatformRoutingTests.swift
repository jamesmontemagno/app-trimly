import Foundation
import Testing
import UserNotifications
@testable import TrimTally

@MainActor
struct PlatformRoutingTests {
    @Test
    func quickLogWaitsForOnboardingAndActiveScene() {
        let router = AppRouter()
        #expect(router.handle(QuickLogLink.url))
        #expect(!router.consumeQuickLog(isReady: false))
        #expect(router.hasPendingQuickLog)
        #expect(router.consumeQuickLog(isReady: true))
        #expect(!router.hasPendingQuickLog)
        #expect(!router.consumeQuickLog(isReady: true))
    }

    @Test
    func repeatedRequestsCoalesceButWarmLaunchCanRouteAgain() {
        let router = AppRouter()
        router.requestQuickLog()
        router.requestQuickLog()
        #expect(router.consumeQuickLog(isReady: true))
        #expect(!router.consumeQuickLog(isReady: true))
        router.requestQuickLog()
        #expect(router.consumeQuickLog(isReady: true))
    }

    @Test(arguments: [
        "https://log", "trimtally://other", "trimtally://log/save",
        "trimtally://log?weight=100", "trimtally://log#save",
        "trimtally://someone@log", "trimtally://log:80"
    ])
    func unrelatedOrParameterizedURLsDoNotSaveOrNavigate(_ value: String) throws {
        let router = AppRouter()
        let url = try #require(URL(string: value))
        #expect(!router.handle(url))
        #expect(!router.hasPendingQuickLog)
    }

    @Test(arguments: ["QUICK_LOG", UNNotificationDefaultActionIdentifier])
    func reminderActionsOpenTheFormWithoutInsertingEntries(_ action: String) {
        let dataManager = DataManager(inMemory: true)
        let router = AppRouter()
        let service = NotificationService()
        service.configure(dataManager: dataManager)
        service.handleResponse(categoryIdentifier: "WEIGHT_REMINDER", actionIdentifier: action, deliveredAt: Date(), router: router)
        #expect(router.hasPendingQuickLog)
        #expect(dataManager.fetchAllEntries().isEmpty)
    }

    @Test
    func unrelatedNotificationDoesNotNavigate() {
        let router = AppRouter()
        NotificationService().handleResponse(
            categoryIdentifier: "OTHER", actionIdentifier: "QUICK_LOG", deliveredAt: Date(), router: router
        )
        #expect(!router.hasPendingQuickLog)
    }

    @Test
    func coldLaunchDismissalIsReplayedAfterConfiguration() {
        let dataManager = DataManager(inMemory: true)
        let router = AppRouter()
        let service = NotificationService()
        service.handleResponse(
            categoryIdentifier: "WEIGHT_REMINDER", actionIdentifier: UNNotificationDismissActionIdentifier,
            deliveredAt: Date(), router: router
        )
        #expect(dataManager.deviceSettings.reminders.consecutiveDismissals == 0)
        service.configure(dataManager: dataManager)
        #expect(dataManager.deviceSettings.reminders.consecutiveDismissals == 1)
        service.configure(dataManager: dataManager)
        #expect(dataManager.deviceSettings.reminders.consecutiveDismissals == 1)
        #expect(!router.hasPendingQuickLog)
    }

    @Test
    func dismissalsRespectAdaptiveSettingAndVisibleLogging() throws {
        let dataManager = DataManager(inMemory: true)
        let service = NotificationService()
        service.configure(dataManager: dataManager)
        dataManager.deviceSettings.updateReminders { $0.adaptiveEnabled = false }
        service.handleResponse(categoryIdentifier: "WEIGHT_REMINDER", actionIdentifier: "DISMISS", deliveredAt: Date())
        #expect(dataManager.deviceSettings.reminders.consecutiveDismissals == 0)
        dataManager.deviceSettings.updateReminders {
            $0.adaptiveEnabled = true
            $0.consecutiveDismissals = 2
        }
        try dataManager.addWeightEntry(weightKg: 80, unit: .kilograms)
        service.handleResponse(categoryIdentifier: "WEIGHT_REMINDER", actionIdentifier: "DISMISS", deliveredAt: Date())
        #expect(dataManager.deviceSettings.reminders.consecutiveDismissals == 0)
        let entry = try #require(dataManager.fetchAllEntries().first)
        try dataManager.setEntryHidden(entry, isHidden: true)
        service.handleResponse(categoryIdentifier: "WEIGHT_REMINDER", actionIdentifier: "DISMISS", deliveredAt: Date())
        #expect(dataManager.deviceSettings.reminders.consecutiveDismissals == 1)
    }

    @Test
    func shortcutOnlyRequestsNavigation() async throws {
        let dataManager = DataManager(inMemory: true)
        AppRouter.shared.consumeQuickLog(isReady: true)
        _ = try await OpenWeightLogIntent().perform()
        #expect(AppRouter.shared.consumeQuickLog(isReady: true))
        #expect(dataManager.fetchAllEntries().isEmpty)
    }
}
