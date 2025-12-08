import Foundation
import Testing
@testable import TrimTally

@MainActor
struct CelebrationServiceTests {

	// MARK: - Helpers

	private func makeInMemoryManager() async -> DataManager {
		let suiteName = "com.trimly.tests.celebrations.\(UUID().uuidString)"
		guard let defaults = UserDefaults(suiteName: suiteName) else {
			fatalError("Failed to create UserDefaults suite \(suiteName)")
		}
		defaults.removePersistentDomain(forName: suiteName)
		let deviceSettings = DeviceSettingsStore(userDefaults: defaults)
		return await DataManager(inMemory: true, deviceSettings: deviceSettings)
	}

	// MARK: - Goal Progress Celebration Tests

	@Test
	func goalCelebration_weightLoss_progressTowardGoal_celebratesAtMilestone() async throws {
		// Setup: User wants to lose weight (start 100kg -> target 90kg)
		let manager = await makeInMemoryManager()
		let service = CelebrationService()
		
		// Set start weight
		let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
		try manager.addWeightEntry(weightKg: 100.0, timestamp: startDate, unit: .kilograms, notes: nil)
		
		// Create goal to lose weight
		try manager.setGoal(targetWeightKg: 90.0, startingWeightKg: 100.0)
		
		// Add current weight at 50% progress (95kg - halfway to target)
		let currentDate = Date()
		try manager.addWeightEntry(weightKg: 95.0, timestamp: currentDate, unit: .kilograms, notes: nil)
		
		// Check for celebration
		let celebration = service.checkForCelebrations(dataManager: manager)
		
		// Should celebrate 50% milestone
		#expect(celebration != nil)
		#expect(celebration?.type == .goal50Percent)
	}

	@Test
	func goalCelebration_weightLoss_movingAwayFromGoal_doesNotCelebrate() async throws {
		// Setup: User wants to lose weight (start 100kg -> target 90kg) but is gaining
		let manager = await makeInMemoryManager()
		let service = CelebrationService()
		
		// Set start weight
		let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
		try manager.addWeightEntry(weightKg: 100.0, timestamp: startDate, unit: .kilograms, notes: nil)
		
		// Create goal to lose weight
		try manager.setGoal(targetWeightKg: 90.0, startingWeightKg: 100.0)
		
		// Add current weight that's HIGHER than start (moving wrong direction)
		let currentDate = Date()
		try manager.addWeightEntry(weightKg: 105.0, timestamp: currentDate, unit: .kilograms, notes: nil)
		
		// Check for celebration
		let celebration = service.checkForCelebrations(dataManager: manager)
		
		// Should NOT celebrate any goal milestone
		if let celebration = celebration {
			#expect(celebration.type != .goal25Percent)
			#expect(celebration.type != .goal50Percent)
			#expect(celebration.type != .goal75Percent)
			#expect(celebration.type != .goal100Percent)
		}
	}

	@Test
	func goalCelebration_weightGain_progressTowardGoal_celebratesAtMilestone() async throws {
		// Setup: User wants to gain weight (start 60kg -> target 70kg)
		let manager = await makeInMemoryManager()
		let service = CelebrationService()
		
		// Set start weight
		let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
		try manager.addWeightEntry(weightKg: 60.0, timestamp: startDate, unit: .kilograms, notes: nil)
		
		// Create goal to gain weight
		try manager.setGoal(targetWeightKg: 70.0, startingWeightKg: 60.0)
		
		// Add current weight at 25% progress (62.5kg)
		let currentDate = Date()
		try manager.addWeightEntry(weightKg: 62.5, timestamp: currentDate, unit: .kilograms, notes: nil)
		
		// Check for celebration
		let celebration = service.checkForCelebrations(dataManager: manager)
		
		// Should celebrate 25% milestone
		#expect(celebration != nil)
		#expect(celebration?.type == .goal25Percent)
	}

	@Test
	func goalCelebration_weightGain_movingAwayFromGoal_doesNotCelebrate() async throws {
		// Setup: User wants to gain weight (start 60kg -> target 70kg) but is losing
		let manager = await makeInMemoryManager()
		let service = CelebrationService()
		
		// Set start weight
		let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
		try manager.addWeightEntry(weightKg: 60.0, timestamp: startDate, unit: .kilograms, notes: nil)
		
		// Create goal to gain weight
		try manager.setGoal(targetWeightKg: 70.0, startingWeightKg: 60.0)
		
		// Add current weight that's LOWER than start (moving wrong direction)
		let currentDate = Date()
		try manager.addWeightEntry(weightKg: 55.0, timestamp: currentDate, unit: .kilograms, notes: nil)
		
		// Check for celebration
		let celebration = service.checkForCelebrations(dataManager: manager)
		
		// Should NOT celebrate any goal milestone
		if let celebration = celebration {
			#expect(celebration.type != .goal25Percent)
			#expect(celebration.type != .goal50Percent)
			#expect(celebration.type != .goal75Percent)
			#expect(celebration.type != .goal100Percent)
		}
	}

	@Test
	func goalCelebration_atExactStartWeight_doesNotCelebrate() async throws {
		// Setup: User at exact start weight (no progress)
		let manager = await makeInMemoryManager()
		let service = CelebrationService()
		
		// Set start weight
		let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
		try manager.addWeightEntry(weightKg: 80.0, timestamp: startDate, unit: .kilograms, notes: nil)
		
		// Create goal
		try manager.setGoal(targetWeightKg: 70.0, startingWeightKg: 80.0)
		
		// Add current weight at exact start weight
		let currentDate = Date()
		try manager.addWeightEntry(weightKg: 80.0, timestamp: currentDate, unit: .kilograms, notes: nil)
		
		// Check for celebration
		let celebration = service.checkForCelebrations(dataManager: manager)
		
		// Should NOT celebrate any goal milestone (0% progress)
		if let celebration = celebration {
			#expect(celebration.type != .goal25Percent)
			#expect(celebration.type != .goal50Percent)
			#expect(celebration.type != .goal75Percent)
			#expect(celebration.type != .goal100Percent)
		}
	}
}
