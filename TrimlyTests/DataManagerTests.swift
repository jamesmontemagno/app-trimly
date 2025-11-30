import Foundation
import Testing
@testable import TrimTally

@MainActor
struct DataManagerTests {

	// MARK: - Helpers

	private func makeInMemoryManager() async -> DataManager {
		await DataManager(inMemory: true)
	}

	@Test
	func settings_areCreatedOnFirstLaunch() async throws {
		let manager = await makeInMemoryManager()
		#expect(manager.settings != nil)
	}

	@Test
	func updateSettings_persistsChanges() async throws {
		let manager = await makeInMemoryManager()
		let originalDate = manager.settings?.updatedAt
		let originalWindow = manager.settings?.consistencyScoreWindow

		manager.updateSettings { settings in
			settings.consistencyScoreWindow = 14
		}

		#expect(manager.settings?.consistencyScoreWindow == 14)
		if let originalDate, let updated = manager.settings?.updatedAt {
			#expect(updated >= originalDate)
		}
		if let originalWindow {
			#expect(originalWindow != manager.settings?.consistencyScoreWindow)
		}
	}

	// MARK: - Weight Entries

	@Test
	func addWeightEntry_createsAndFetchesEntry() async throws {
		let manager = await makeInMemoryManager()
		let now = Date()
		try manager.addWeightEntry(weightKg: 80.0, timestamp: now, unit: .kilograms, notes: "Test")

		let entries = manager.fetchAllEntries()
		#expect(entries.count == 1)
		if let entry = entries.first {
			#expect(entry.weightKg == 80.0)
			#expect(entry.displayUnitAtEntry == .kilograms)
			#expect(entry.notes == "Test")
		}
	}

	@Test
	func fetchEntriesForDate_returnsOnlyMatchingDay() async throws {
		let manager = await makeInMemoryManager()
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

		try manager.addWeightEntry(weightKg: 80.0, timestamp: today, unit: .kilograms)
		try manager.addWeightEntry(weightKg: 81.0, timestamp: yesterday, unit: .kilograms)

		let todayEntries = manager.fetchEntriesForDate(today)
		#expect(todayEntries.count == 1)
		#expect(todayEntries.first?.weightKg == 80.0)
	}

	@Test
	func deleteEntry_removesItFromStore() async throws {
		let manager = await makeInMemoryManager()
		try manager.addWeightEntry(weightKg: 80.0, unit: .kilograms)
		let entries = manager.fetchAllEntries()
		#expect(entries.count == 1)
		if let entry = entries.first {
			try manager.deleteEntry(entry)
		}
		#expect(manager.fetchAllEntries().isEmpty)
	}

	@Test
	func updateEntry_changesNotesAndTimestamp() async throws {
		let manager = await makeInMemoryManager()
		try manager.addWeightEntry(weightKg: 80.0, unit: .kilograms)
		guard let entry = manager.fetchAllEntries().first else {
			Issue.record("Expected an entry")
			return
		}

		let originalUpdatedAt = entry.updatedAt
		try manager.updateEntry(entry, notes: "Updated")

		#expect(entry.notes == "Updated")
		#expect(entry.updatedAt >= originalUpdatedAt)
	}

	// MARK: - Goals

	@Test
	func setGoal_createsActiveGoal() async throws {
		let manager = await makeInMemoryManager()
		try manager.setGoal(targetWeightKg: 75.0, startingWeightKg: 80.0)

		let active = manager.fetchActiveGoal()
		#expect(active != nil)
		#expect(active?.targetWeightKg == 75.0)
		#expect(active?.startingWeightKg == 80.0)
	}

	@Test
	func setGoal_archivesPreviousActiveGoal() async throws {
		let manager = await makeInMemoryManager()
		try manager.setGoal(targetWeightKg: 75.0, startingWeightKg: 80.0)
		try manager.setGoal(targetWeightKg: 70.0, startingWeightKg: 78.0)

		let active = manager.fetchActiveGoal()
		let history = manager.fetchGoalHistory()

		#expect(active?.targetWeightKg == 70.0)
		#expect(history.count == 1)
		#expect(history.first?.isActive == false)
	}

	@Test
	func completeGoal_achievedKeepsGoalActive() async throws {
		let manager = await makeInMemoryManager()
		try manager.setGoal(targetWeightKg: 75.0, startingWeightKg: 80.0)
		try manager.completeGoal(reason: .achieved)

		let active = manager.fetchActiveGoal()
		#expect(active != nil)
		#expect(active?.completionReason == .achieved)
		#expect(active?.isActive == true)
		#expect(active?.completedDate != nil)
		#expect(manager.consumeGoalAchievementCelebrationIfNeeded() == true)
		#expect(manager.consumeGoalAchievementCelebrationIfNeeded() == false)
	}

	@Test
	func completeGoal_abandonedMovesActiveGoalToHistory() async throws {
		let manager = await makeInMemoryManager()
		try manager.setGoal(targetWeightKg: 75.0, startingWeightKg: 80.0)
		try manager.completeGoal(reason: .abandoned)

		let active = manager.fetchActiveGoal()
		let history = manager.fetchGoalHistory()

		#expect(active == nil)
		#expect(history.count == 1)
		#expect(history.first?.completionReason == .abandoned)
		#expect(history.first?.isActive == false)
	}

	@Test
	func goal_autoCompletesWhenTargetMet() async throws {
		let manager = await makeInMemoryManager()
		try manager.setGoal(targetWeightKg: 75.0, startingWeightKg: 80.0)
		try manager.addWeightEntry(weightKg: 80.0, unit: .kilograms)
		try manager.addWeightEntry(weightKg: 75.0, unit: .kilograms)

		guard let goal = manager.fetchActiveGoal() else {
			Issue.record("Expected an active goal")
			return
		}
		#expect(goal.completionReason == .achieved)
		#expect(goal.completedDate != nil)
		#expect(goal.isActive == true)
		#expect(manager.consumeGoalAchievementCelebrationIfNeeded() == true)
		#expect(manager.consumeGoalAchievementCelebrationIfNeeded() == false)
	}

	@Test
	func setGoal_requiresStartingWeightWhenUnavailable() async throws {
		let manager = await makeInMemoryManager()
		do {
			try manager.setGoal(targetWeightKg: 75.0, startingWeightKg: nil)
			Issue.record("Expected missing starting weight error")
		} catch let error as DataManagerError {
			guard case .missingStartingWeight = error else {
				Issue.record("Unexpected DataManagerError: \(error)")
				return
			}
		} catch {
			Issue.record("Unexpected error: \(error)")
		}
	}

	// MARK: - Analytics helpers

	@Test
	func getDailyWeights_respectsAggregationMode() async throws {
		let manager = await makeInMemoryManager()
		let now = Date()
		// Two entries same day, different weights
		try manager.addWeightEntry(weightKg: 80.0, timestamp: now, unit: .kilograms)
		try manager.addWeightEntry(weightKg: 82.0, timestamp: now.addingTimeInterval(3600), unit: .kilograms)

		// Latest mode (default)
		let latestDaily = manager.getDailyWeights(mode: .latest)
		#expect(latestDaily.count == 1)
		#expect(latestDaily.first?.weight == 82.0)

		// Average mode
		let averageDaily = manager.getDailyWeights(mode: .average)
		#expect(averageDaily.count == 1)
		if let avg = averageDaily.first?.weight {
			#expect(abs(avg - 81.0) < 0.0001)
		}
	}

	@Test
	func getConsistencyScore_respectsWindowAndGaps() async throws {
		let manager = await makeInMemoryManager()
		// Use a short window for deterministic behavior
		manager.updateSettings { settings in
			settings.consistencyScoreWindow = 7
		}

		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today
		let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today) ?? today

		// Entries on fourDaysAgo, twoDaysAgo, and today -> one missed day inside window
		try manager.addWeightEntry(weightKg: 80.0, timestamp: fourDaysAgo, unit: .kilograms)
		try manager.addWeightEntry(weightKg: 79.5, timestamp: twoDaysAgo, unit: .kilograms)
		try manager.addWeightEntry(weightKg: 79.0, timestamp: today, unit: .kilograms)

		guard let score = manager.getConsistencyScore() else {
			Issue.record("Expected a consistency score")
			return
		}

		// Window from fourDaysAgo to today is 5 calendar days inclusive.
		// We have entries on 3 of those days -> 3/5.
		let expected = 3.0 / 5.0
		#expect(abs(score - expected) < 0.0001)
	}

	@Test
	func getCurrentAndStartWeight_returnExpectedValues() async throws {
		let manager = await makeInMemoryManager()
		let calendar = Calendar.current
		let today = Date()
		let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

		try manager.addWeightEntry(weightKg: 80.0, timestamp: yesterday, unit: .kilograms)
		try manager.addWeightEntry(weightKg: 78.0, timestamp: today, unit: .kilograms)

		#expect(manager.getCurrentWeight() == 78.0)
		#expect(manager.getStartWeight() == 80.0)
	}

	@Test
	func getGoalProjection_nilWhenInsufficientHistory() async throws {
		let manager = await makeInMemoryManager()
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())

		manager.updateSettings { settings in
			settings.minDaysForProjection = 10
		}

		// Fewer points than minDaysForProjection
		for offset in (0..<5).reversed() {
			let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
			let weight = 85.0 - Double(offset)
			try manager.addWeightEntry(weightKg: weight, timestamp: day, unit: .kilograms)
		}

		try manager.setGoal(targetWeightKg: 80.0, startingWeightKg: 85.0)
		let projection = manager.getGoalProjection()
		#expect(projection == nil)
	}

	// MARK: - Data Deletion

	@Test
	func deleteAllData_clearsEntriesGoalsAndResetsOnboarding() async throws {
		let manager = await makeInMemoryManager()
		// Seed entries and goal
		try manager.addWeightEntry(weightKg: 80.0, unit: .kilograms)
		try manager.setGoal(targetWeightKg: 75.0, startingWeightKg: 80.0)
		manager.updateSettings { settings in
			settings.hasCompletedOnboarding = true
			settings.eulaAcceptedDate = Date()
			settings.consecutiveReminderDismissals = 3
		}

		try manager.deleteAllData()

		#expect(manager.fetchAllEntries().isEmpty)
		#expect(manager.fetchActiveGoal() == nil)
		#expect(manager.fetchGoalHistory().isEmpty)
		#expect(manager.settings?.hasCompletedOnboarding == false)
		#expect(manager.settings?.eulaAcceptedDate == nil)
		#expect(manager.settings?.consecutiveReminderDismissals == 0)
	}

	// MARK: - CSV Export

	@Test
	func exportToCSV_includesHeaderAndEntriesInChronologicalOrder() async throws {
		let manager = await makeInMemoryManager()
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

		try manager.addWeightEntry(weightKg: 80.0, timestamp: yesterday, unit: .kilograms, notes: "First")
		try manager.addWeightEntry(weightKg: 78.5, timestamp: today, unit: .kilograms, notes: "Second")

		let csv = manager.exportToCSV()
		let lines = csv.split(separator: "\n").map(String.init)

		#expect(lines.count == 3) // header + 2 rows
		#expect(lines.first == "id,timestamp,normalizedDate,weight_kg,displayUnitAtEntry,weight_display_value,source,notes,createdAt,updatedAt")

		// Oldest entry should appear first after header
		let firstDataRow = lines.dropFirst().first ?? ""
		#expect(firstDataRow.contains(",80.00,kg,"))
		#expect(firstDataRow.contains("\"First\""))
	}
}
