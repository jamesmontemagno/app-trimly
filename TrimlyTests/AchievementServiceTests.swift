import XCTest
@testable import Trimly

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
	
	private func logSequentialEntries(count: Int) throws {
		let poundsUnit = WeightUnit.pounds
		let calendar = Calendar.current
		for dayOffset in 0..<count {
			let timestamp = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
			let kg = poundsUnit.convertToKg(170 - Double(dayOffset % 5))
			try dataManager.addWeightEntry(weightKg: kg, timestamp: timestamp, unit: poundsUnit)
		}
	}
}
