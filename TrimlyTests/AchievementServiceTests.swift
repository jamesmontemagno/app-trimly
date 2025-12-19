import Foundation
import XCTest
import SwiftData
@testable import TrimTally

@MainActor
final class AchievementServiceTests: XCTestCase {
	private var dataManager: DataManager!
	private var deviceSettings: DeviceSettingsStore!
	private var achievementService: AchievementService!
	
	override func setUp() async throws {
		deviceSettings = makeDeviceSettingsStore()
		dataManager = DataManager(inMemory: true, deviceSettings: deviceSettings)
		achievementService = AchievementService()
	}
	
	override func tearDown() {
		dataManager = nil
		deviceSettings = nil
		achievementService = nil
	}

	private func makeDeviceSettingsStore() -> DeviceSettingsStore {
		let suiteName = "com.trimly.tests.devicesettings.\(UUID().uuidString)"
		guard let defaults = UserDefaults(suiteName: suiteName) else {
			fatalError("Failed to create UserDefaults suite \(suiteName)")
		}
		defaults.removePersistentDomain(forName: suiteName)
		return DeviceSettingsStore(userDefaults: defaults)
	}
	
	func testLoggingAchievementUnlocksAfterTenEntries() throws {
		try logSequentialEntries(count: 10)
		achievementService.refresh(using: dataManager, isPro: true)
		let newcomer = dataManager.achievement(forKey: "logging.newcomer", createIfMissing: false)
		XCTAssertNotNil(newcomer)
		XCTAssertNotNil(newcomer?.unlockedAt)
		// Progress should be reset to 0 when achievement is unlocked
		XCTAssertEqual(newcomer?.progressValue, 0)
	}

	func testConsistencyAchievementsRequireMinimumDays() throws {
		// Simulate high consistency over only 5 unique days: should not unlock
		try logSequentialEntries(count: 5)
		achievementService.refresh(using: dataManager, isPro: true)
		let habitBuilderEarly = dataManager.achievement(forKey: "consistency.solid", createIfMissing: false)
		let consistencyIconEarly = dataManager.achievement(forKey: "consistency.excellent", createIfMissing: false)
		XCTAssertNil(habitBuilderEarly?.unlockedAt)
		XCTAssertNil(consistencyIconEarly?.unlockedAt)

		// Add more days to reach the 10-day minimum
		try logSequentialEntries(count: 5, startOffset: 5)
		achievementService.refresh(using: dataManager, isPro: true)
		let habitBuilder = dataManager.achievement(forKey: "consistency.solid", createIfMissing: false)
		XCTAssertNotNil(habitBuilder)
		XCTAssertNotNil(habitBuilder?.unlockedAt)
	}

	func testConsistencyAchievementsIgnoreHiddenEntries() throws {
		try logSequentialEntries(count: 10)
		let entries = dataManager.fetchAllEntries()
		for entry in entries.dropLast() {
			entry.isHidden = true
		}
		try dataManager.modelContext.save()
		achievementService.refresh(using: dataManager, isPro: true)
		let habitBuilder = dataManager.achievement(forKey: "consistency.solid", createIfMissing: false)
		XCTAssertNil(habitBuilder?.unlockedAt)
	}
	
	func testPremiumAchievementRequiresProUnlock() throws {
		try logSequentialEntries(count: 370)
		achievementService.refresh(using: dataManager, isPro: false)
		let ledgerLocked = dataManager.achievement(forKey: "logging.ledger", createIfMissing: false)
		XCTAssertNotNil(ledgerLocked)
		XCTAssertNil(ledgerLocked?.unlockedAt)
		XCTAssertLessThan(ledgerLocked?.progressValue ?? 0, 1)
		achievementService.refresh(using: dataManager, isPro: true)
		let ledgerUnlocked = dataManager.achievement(forKey: "logging.ledger", createIfMissing: false)
		XCTAssertNotNil(ledgerUnlocked?.unlockedAt)
	}

	func testConsistencyProgressAccountsForBothRequirements() throws {
		// With 5 unique days and high consistency, progress should be less than 100%
		// because the 10-day minimum isn't met
		try logSequentialEntries(count: 5)
		achievementService.refresh(using: dataManager, isPro: true)
		let habitBuilder = dataManager.achievement(forKey: "consistency.solid", createIfMissing: false)
		XCTAssertNotNil(habitBuilder)
		// Progress should be around 75%: 50% from days (5/10) = 25% + 50% from consistency (high) ≈ 50%
		// So total should be less than 100%
		XCTAssertLessThan(habitBuilder?.progressValue ?? 0, 1.0)
		XCTAssertNil(habitBuilder?.unlockedAt)
	}

	func testGoalAchievementCountsActiveAchievedGoals() throws {
		// Set up an initial weight entry
		let poundsUnit = WeightUnit.pounds
		let startWeightKg = poundsUnit.convertToKg(180)
		let targetWeightKg = poundsUnit.convertToKg(175)
		try dataManager.addWeightEntry(weightKg: startWeightKg, timestamp: Date(), unit: poundsUnit)
		
		// Create and achieve a goal (it stays active)
		try dataManager.setGoal(targetWeightKg: targetWeightKg, startingWeightKg: startWeightKg)
		
		// Log weight at or below goal to trigger automatic achievement
		try dataManager.addWeightEntry(weightKg: targetWeightKg, timestamp: Date(), unit: poundsUnit)
		
		// Verify goal was marked as achieved
		let activeGoal = dataManager.fetchActiveGoal()
		XCTAssertNotNil(activeGoal)
		XCTAssertEqual(activeGoal?.completionReason, .achieved)
		
		// Verify countAchievedGoals includes this active achieved goal
		let achievedCount = dataManager.countAchievedGoals()
		XCTAssertEqual(achievedCount, 1)
		
		// Verify achievements reflect the achieved goal
		achievementService.refresh(using: dataManager, isPro: true)
		let goalFirstAchievement = dataManager.achievement(forKey: "goals.first", createIfMissing: false)
		XCTAssertNotNil(goalFirstAchievement?.unlockedAt)
	}
	
	func testAchievementProgressResetToZeroWhenUnlocked() throws {
		// Log 5 entries to build up progress (50% for logging.newcomer which requires 10)
		try logSequentialEntries(count: 5)
		achievementService.refresh(using: dataManager, isPro: true)
		let partialProgress = dataManager.achievement(forKey: "logging.newcomer", createIfMissing: false)
		XCTAssertNotNil(partialProgress)
		XCTAssertNil(partialProgress?.unlockedAt)
		XCTAssertEqual(partialProgress?.progressValue, 0.5, accuracy: 0.01)
		
		// Log 5 more entries to unlock the achievement (total 10)
		try logSequentialEntries(count: 5, startOffset: 5)
		achievementService.refresh(using: dataManager, isPro: true)
		let unlocked = dataManager.achievement(forKey: "logging.newcomer", createIfMissing: false)
		XCTAssertNotNil(unlocked)
		XCTAssertNotNil(unlocked?.unlockedAt)
		// Progress should be reset to 0 upon unlock
		XCTAssertEqual(unlocked?.progressValue, 0)
		
		// Log more entries - progress should remain 0 once unlocked
		try logSequentialEntries(count: 5, startOffset: 10)
		achievementService.refresh(using: dataManager, isPro: true)
		let stillUnlocked = dataManager.achievement(forKey: "logging.newcomer", createIfMissing: false)
		XCTAssertNotNil(stillUnlocked?.unlockedAt)
		XCTAssertEqual(stillUnlocked?.progressValue, 0)
	}
	
	// MARK: - Helpers
	
	private func logSequentialEntries(count: Int, startOffset: Int = 0) throws {
		let poundsUnit = WeightUnit.pounds
		let calendar = Calendar.current
		for index in 0..<count {
			let dayOffset = startOffset + index
			let timestamp = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
			let kg = poundsUnit.convertToKg(170 - Double(dayOffset % 5))
			try dataManager.addWeightEntry(weightKg: kg, timestamp: timestamp, unit: poundsUnit)
		}
	}
}
