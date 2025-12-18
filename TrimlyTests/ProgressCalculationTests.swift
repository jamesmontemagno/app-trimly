import Foundation
import Testing
@testable import TrimTally

@MainActor
struct ProgressCalculationTests {
	
	// Helper function that mirrors the progress calculation in ProgressSummaryCard
	private func calculateProgress(startWeight: Double, currentWeight: Double, targetWeight: Double) -> Int {
		let totalChange = targetWeight - startWeight
		let currentChange = currentWeight - startWeight
		let progress = totalChange != 0 ? (currentChange / totalChange) * 100 : 0
		return Int(min(100, progress))
	}
	
	// MARK: - Weight Loss Scenarios
	
	@Test
	func progress_weightLoss_normalProgress() async throws {
		// Start: 100kg, Target: 80kg, Current: 90kg
		// Expected: 50% progress (lost 10kg out of 20kg goal)
		let result = calculateProgress(startWeight: 100, currentWeight: 90, targetWeight: 80)
		#expect(result == 50)
	}
	
	@Test
	func progress_weightLoss_goalAchieved() async throws {
		// Start: 100kg, Target: 80kg, Current: 80kg
		// Expected: 100% progress (goal achieved)
		let result = calculateProgress(startWeight: 100, currentWeight: 80, targetWeight: 80)
		#expect(result == 100)
	}
	
	@Test
	func progress_weightLoss_exceededGoal() async throws {
		// Start: 100kg, Target: 80kg, Current: 75kg
		// Expected: 100% (capped at 100%, even though mathematically 125%)
		let result = calculateProgress(startWeight: 100, currentWeight: 75, targetWeight: 80)
		#expect(result == 100)
	}
	
	@Test
	func progress_weightLoss_gainedInsteadOfLost() async throws {
		// Start: 100kg, Target: 80kg, Current: 105kg
		// Expected: -25% (moved 5kg in wrong direction, opposite of 20kg goal)
		let result = calculateProgress(startWeight: 100, currentWeight: 105, targetWeight: 80)
		#expect(result == -25)
	}
	
	@Test
	func progress_weightLoss_noChange() async throws {
		// Start: 100kg, Target: 80kg, Current: 100kg
		// Expected: 0% (no progress yet)
		let result = calculateProgress(startWeight: 100, currentWeight: 100, targetWeight: 80)
		#expect(result == 0)
	}
	
	// MARK: - Weight Gain Scenarios
	
	@Test
	func progress_weightGain_normalProgress() async throws {
		// Start: 60kg, Target: 80kg, Current: 70kg
		// Expected: 50% progress (gained 10kg out of 20kg goal)
		let result = calculateProgress(startWeight: 60, currentWeight: 70, targetWeight: 80)
		#expect(result == 50)
	}
	
	@Test
	func progress_weightGain_goalAchieved() async throws {
		// Start: 60kg, Target: 80kg, Current: 80kg
		// Expected: 100% progress (goal achieved)
		let result = calculateProgress(startWeight: 60, currentWeight: 80, targetWeight: 80)
		#expect(result == 100)
	}
	
	@Test
	func progress_weightGain_exceededGoal() async throws {
		// Start: 60kg, Target: 80kg, Current: 85kg
		// Expected: 100% (capped at 100%, even though mathematically 125%)
		let result = calculateProgress(startWeight: 60, currentWeight: 85, targetWeight: 80)
		#expect(result == 100)
	}
	
	@Test
	func progress_weightGain_lostInsteadOfGained() async throws {
		// Start: 60kg, Target: 80kg, Current: 55kg
		// Expected: -25% (moved 5kg in wrong direction, opposite of 20kg goal)
		let result = calculateProgress(startWeight: 60, currentWeight: 55, targetWeight: 80)
		#expect(result == -25)
	}
	
	@Test
	func progress_weightGain_noChange() async throws {
		// Start: 60kg, Target: 80kg, Current: 60kg
		// Expected: 0% (no progress yet)
		let result = calculateProgress(startWeight: 60, currentWeight: 60, targetWeight: 80)
		#expect(result == 0)
	}
	
	// MARK: - Edge Cases
	
	@Test
	func progress_sameStartAndTarget() async throws {
		// Start: 80kg, Target: 80kg, Current: 80kg
		// Expected: 0% (division by zero case, returns 0)
		let result = calculateProgress(startWeight: 80, currentWeight: 80, targetWeight: 80)
		#expect(result == 0)
	}
	
	@Test
	func progress_smallChanges() async throws {
		// Start: 70kg, Target: 69kg, Current: 69.5kg
		// Expected: 50% progress
		let result = calculateProgress(startWeight: 70, currentWeight: 69.5, targetWeight: 69)
		#expect(result == 50)
	}
}
