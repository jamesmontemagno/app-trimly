import XCTest
import SwiftData
@testable import TrimTally

@MainActor
final class AchievementServiceTests: XCTestCase {
	private var dataManager: DataManager!
	private var achievementService: AchievementService!
	
	override func setUp() async throws {
		dataManager = DataManager(inMemory: true)
		achievementService = AchievementService()
	}
	
	override func tearDown() {
		dataManager = nil
		achievementService = nil
	}
	
	func testLoggingAchievementUnlocksAfterTenEntries() throws {
		try logSequentialEntries(count: 10)
		achievementService.refresh(using: dataManager, isPro: true)
		let newcomer = dataManager.achievement(forKey: "logging.newcomer", createIfMissing: false)
		XCTAssertNotNil(newcomer)
		XCTAssertNotNil(newcomer?.unlockedAt)
		XCTAssertGreaterThanOrEqual(newcomer?.progressValue ?? 0, 1)
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
