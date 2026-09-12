import Foundation
import Testing
@testable import TrimTally

@MainActor
struct HealthKitDuplicateTests {
    @Test
    func matchingSamplesAreSkippedEvenWhenExistingEntryIsHidden() throws {
        let manager = DataManager(inMemory: true)
        let service = HealthKitService()
        let date = Date().addingTimeInterval(-60)
        try manager.addWeightEntry(weightKg: 80, timestamp: date, unit: .kilograms)
        let entry = try #require(manager.fetchAllEntries().first)
        try manager.setEntryHidden(entry, isHidden: true)
        #expect(try service.isDuplicate(weightKg: 80.05, timestamp: date.addingTimeInterval(30), dataManager: manager))
        #expect(manager.fetchAllEntries().count == 1)
    }

    @Test
    func duplicateComparisonWorksAcrossMidnightAndHonorsTolerance() throws {
        let manager = DataManager(inMemory: true)
        let service = HealthKitService()
        let day = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())))
        try manager.addWeightEntry(weightKg: 80, timestamp: day.addingTimeInterval(-60), unit: .kilograms)
        #expect(try service.isDuplicate(weightKg: 80.05, timestamp: day.addingTimeInterval(60), dataManager: manager))
        #expect(try !service.isDuplicate(weightKg: 81, timestamp: day, dataManager: manager))
        #expect(try !service.isDuplicate(weightKg: 80, timestamp: day.addingTimeInterval(600), dataManager: manager))
        manager.deviceSettings.updateHealthKit { $0.autoHideDuplicates = false }
        #expect(try !service.isDuplicate(weightKg: 80, timestamp: day, dataManager: manager))
    }
}
