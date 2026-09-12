import Foundation
import Testing
@testable import TrimTally

@MainActor
struct DataManagerEnhancementTests {
    @Test func manualEditPreservesIdentityAndNormalizesDay() throws {
        let manager = DataManager(inMemory: true)
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        try manager.addWeightEntry(weightKg: 80, timestamp: today, unit: .kilograms)
        let entry = try #require(manager.fetchAllEntries().first)
        let id = entry.id
        let createdAt = entry.createdAt
        try manager.updateEntry(entry, weightKg: 79, timestamp: yesterday, unit: .pounds, notes: "Corrected")
        #expect(entry.id == id)
        #expect(entry.createdAt == createdAt)
        #expect(entry.normalizedDate == yesterday)
        #expect(manager.fetchEntriesForDate(today).isEmpty)
        #expect(manager.fetchEntriesForDate(yesterday).count == 1)
    }

    @Test func invalidMeasurementsDoNotMutateEntries() throws {
        let manager = DataManager(inMemory: true)
        for value in [Double.nan, .infinity, -.infinity, 0, -1] {
            #expect(throws: DataManagerError.self) {
                try manager.addWeightEntry(weightKg: value, unit: .kilograms)
            }
        }
        #expect(manager.fetchAllEntries().isEmpty)
    }

    @Test func importedMeasurementsPermitOnlyNotesAndVisibility() throws {
        let manager = DataManager(inMemory: true)
        try manager.addWeightEntry(weightKg: 80, unit: .kilograms, source: .healthKit)
        let entry = try #require(manager.fetchAllEntries().first)
        #expect(throws: DataManagerError.self) {
            try manager.updateEntry(entry, weightKg: 79, timestamp: entry.timestamp, unit: .kilograms, notes: nil)
        }
        try manager.updateEntry(entry, notes: "Local context")
        try manager.setEntryHidden(entry, isHidden: true)
        #expect(entry.notes == "Local context")
        #expect(manager.getCurrentWeight() == nil)
        #expect(manager.getStartWeight() == nil)
        #expect(manager.getDailyWeights().isEmpty)
        #expect(manager.fetchEntriesForDate(Date()).isEmpty)
        #expect(try manager.fetchEntries(includeHidden: true).count == 1)
        try manager.setEntryHidden(entry, isHidden: false)
        #expect(manager.getCurrentWeight() == 80)
    }

    @Test func filtersCombineWithoutChangingStoredHistory() throws {
        let manager = DataManager(inMemory: true)
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        try manager.addWeightEntry(weightKg: 80, timestamp: today, unit: .kilograms, notes: "Morning walk")
        try manager.addWeightEntry(weightKg: 81, timestamp: today, unit: .kilograms, source: .healthKit)
        let results = try manager.fetchEntries(
            startDate: today, endDate: tomorrow, source: .manual, notesOnly: true, searchText: "MORNING"
        )
        #expect(results.count == 1)
        #expect(manager.fetchAllEntries().count == 2)
        #expect(throws: DataManagerError.self) {
            try manager.fetchEntries(startDate: tomorrow, endDate: today)
        }
    }

    @Test func importValidatesEntireBatchBeforeSaving() throws {
        let manager = DataManager(inMemory: true)
        let drafts = [
            WeightEntryDraft(weightKg: 80, timestamp: Date(), unit: .kilograms, notes: "Valid"),
            WeightEntryDraft(weightKg: -1, timestamp: Date(), unit: .kilograms, notes: nil)
        ]
        #expect(throws: DataManagerError.self) { try manager.importWeightEntries(drafts) }
        #expect(manager.fetchAllEntries().isEmpty)
    }

    @Test func editsAndImportsDoNotTriggerLoggingCelebrations() throws {
        let manager = DataManager(inMemory: true)
        try manager.addWeightEntry(weightKg: 80, unit: .kilograms)
        let entry = try #require(manager.fetchAllEntries().first)
        let celebrationRevision = manager.celebrationRevision
        let dataRevision = manager.dataRevision
        try manager.updateEntry(entry, notes: "Updated")
        try manager.importWeightEntries([
            WeightEntryDraft(weightKg: 79, timestamp: Date(), unit: .kilograms, notes: nil)
        ])
        #expect(manager.dataRevision > dataRevision)
        #expect(manager.celebrationRevision == celebrationRevision)
    }

    @Test func failedGoalValidationDoesNotArchiveCurrentGoal() throws {
        let manager = DataManager(inMemory: true)
        try manager.setGoal(targetWeightKg: 75, startingWeightKg: 80)
        let id = manager.fetchActiveGoal()?.id
        #expect(throws: DataManagerError.self) {
            try manager.setGoal(targetWeightKg: -1, startingWeightKg: 80)
        }
        #expect(manager.fetchActiveGoal()?.id == id)
        #expect(manager.fetchGoalHistory().isEmpty)
    }

    @Test func goalDeadlineCanBeSetAndCleared() throws {
        let manager = DataManager(inMemory: true)
        let deadline = Calendar.current.date(byAdding: .day, value: 90, to: Date())!
        try manager.setGoal(targetWeightKg: 75, startingWeightKg: 80, targetDate: deadline)
        #expect(manager.fetchActiveGoal()?.targetDate == deadline)
        try manager.updateGoal(targetWeightKg: 76, startingWeightKg: 80, targetDate: nil)
        #expect(manager.fetchActiveGoal()?.targetDate == nil)
    }

    @Test func newGoalAndStartingEntryAreSavedTogether() throws {
        let manager = DataManager(inMemory: true)
        try manager.setGoal(targetWeightKg: 75, startingWeightKg: 80, startingEntryUnit: .kilograms)
        let goal = try #require(manager.fetchActiveGoal())
        let entry = try #require(manager.fetchAllEntries().first)
        #expect(entry.timestamp == goal.startDate)
        #expect(entry.weightKg == goal.startingWeightKg)
        #expect(manager.celebrationRevision == 0)
    }
}
