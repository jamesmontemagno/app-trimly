import Foundation
import Testing
@testable import TrimTally

@MainActor
struct AchievementEnhancementTests {
    @Test func nonconsecutiveLoggingUnlocksSupportiveMilestone() throws {
        let manager = DataManager(inMemory: true)
        let service = AchievementService()
        let today = Calendar.current.startOfDay(for: Date())
        for offset in stride(from: 0, through: 12, by: 2) {
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: today)!
            try manager.addWeightEntry(weightKg: 80, timestamp: day, unit: .kilograms)
        }
        service.refresh(using: manager, isPro: false)
        #expect(manager.achievement(forKey: "habits.sevenDays", createIfMissing: false)?.unlockedAt != nil)
        #expect(service.diagnostics?.uniqueDayCount == 7)
    }

    @Test func historicalChangesDoNotQueueNewAchievementCelebrations() throws {
        let manager = DataManager(inMemory: true)
        let service = AchievementService()
        try manager.addWeightEntry(weightKg: 80, unit: .kilograms)
        service.refresh(using: manager, isPro: false, celebrateUnlocks: false)
        #expect(manager.achievement(forKey: "habits.firstDay", createIfMissing: false)?.unlockedAt != nil)
        #expect(manager.fetchUncelebratedAchievements().isEmpty)
        service.refresh(using: manager, isPro: false)
        #expect(manager.fetchUncelebratedAchievements().isEmpty)
    }
}
