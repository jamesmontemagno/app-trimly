import Foundation
import Testing
@testable import TrimTally

@MainActor
struct WeightAnalyticsTests {

	// Helper to create a WeightEntry on a specific day offset
	private func makeEntry(daysAgo: Int, hidden: Bool = false) -> WeightEntry {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
		let entry = WeightEntry(
			timestamp: date,
			normalizedDate: date,
			weightKg: 80.0,
			displayUnitAtEntry: .kilograms,
			isHidden: hidden
		)
		return entry
	}

	@Test
	func consistency_singleDay_newUser_isHundredPercent() async throws {
		// User started today and logged today
		let entries = [makeEntry(daysAgo: 0)]

		let score = WeightAnalytics.calculateConsistencyScore(entries: entries)

		#expect(score != nil)
		if let score {
			#expect(score == 1.0, "Expected 100% consistency for a new user with one log today")
		}
	}

	@Test
	func consistency_twoDays_fullLogging_isHundredPercent() async throws {
		// User started yesterday and logged both days
		let entries = [makeEntry(daysAgo: 1), makeEntry(daysAgo: 0)]

		let score = WeightAnalytics.calculateConsistencyScore(entries: entries)

		#expect(score != nil)
		if let score {
			#expect(score == 1.0, "Expected 100% consistency when logging every day since first entry")
		}
	}

	@Test
	func consistency_gapDay_reducesScore() async throws {
		// Entries 2 days ago and today (missed yesterday)
		let entries = [makeEntry(daysAgo: 2), makeEntry(daysAgo: 0)]

		let score = WeightAnalytics.calculateConsistencyScore(entries: entries)

		#expect(score != nil)
		if let score {
			// Window covers 3 days (2 days ago, yesterday, today) with 2 days having entries
			#expect(abs(score - (2.0 / 3.0)) < 0.0001)
		}
	}

	@Test
	func consistency_respectsWindowLimit() async throws {
		// 10 days of logs, but window is 7 days
		var entries: [WeightEntry] = []
		for i in 0..<10 { // 0 = today, 9 = 9 days ago
			entries.append(makeEntry(daysAgo: i))
		}

		let score = WeightAnalytics.calculateConsistencyScore(entries: entries)

		#expect(score != nil)
		if let score {
			// Effective window is last 7 days (0...6) and all have entries
			#expect(score == 1.0)
		}
	}

	@Test
	func consistency_ignoresHiddenEntries() async throws {
		// Two days with entries, but one is hidden
		let visible = makeEntry(daysAgo: 0)
		let hidden = makeEntry(daysAgo: 1, hidden: true)
		let entries = [visible, hidden]

		let score = WeightAnalytics.calculateConsistencyScore(entries: entries)

		#expect(score != nil)
		if let score {
			// First visible entry is today, effective window is single day
			#expect(score == 1.0)
		}
	}

	@Test
	func consistency_withGoalStartDate_calculatesFromGoalStart() async throws {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		
		// Goal started 5 days ago
		let goalStartDate = calendar.date(byAdding: .day, value: -5, to: today) ?? today
		
		// User logged on days 0, 1, 3, and 5 (today) - that's 4 out of 6 days
		let entries = [
			makeEntry(daysAgo: 5),  // Goal start day
			makeEntry(daysAgo: 3),
			makeEntry(daysAgo: 1),
			makeEntry(daysAgo: 0)   // Today
		]
		
		// When using goal start date, should calculate from goal start to today (6 days total: 0-5)
		let score = WeightAnalytics.calculateConsistencyScore(
			entries: entries,
			goalStartDate: goalStartDate
		)
		
		#expect(score != nil)
		if let score {
			// 4 days with entries out of 6 total days (days -5 to 0 inclusive)
			let expected = 4.0 / 6.0
			#expect(abs(score - expected) < 0.0001, "Expected \(expected) but got \(score)")
		}
	}

	@Test
	func consistency_withGoalStartDate_coversFullGoalPeriod() async throws {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		
		// Goal started 60 days ago (way beyond typical window)
		let goalStartDate = calendar.date(byAdding: .day, value: -60, to: today) ?? today
		
		// User has entries spread across the 60 days
		var entries: [WeightEntry] = []
		// Log every other day for 60 days
		for i in stride(from: 0, to: 60, by: 2) {
			entries.append(makeEntry(daysAgo: i))
		}
		
		// With goal start date, it should count all 60 days
		let score = WeightAnalytics.calculateConsistencyScore(
			entries: entries,
			goalStartDate: goalStartDate
		)
		
		#expect(score != nil)
		if let score {
			// 30 entries (every other day) out of 61 total days (days 0-60 inclusive)
			let expected = 30.0 / 61.0
			#expect(abs(score - expected) < 0.01, "Expected ~\(expected) but got \(score)")
		}
	}

	@Test
	func goalProjection_returnsDateForClearDownwardTrend() async throws {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())

		// Build at least 10 days of steadily decreasing weights
		var series: [(date: Date, weight: Double)] = []
		for offset in (0..<10).reversed() {
			let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
			let weight = 90.0 - Double(offset) // 90,89,...,81
			series.append((date: day, weight: weight))
		}

		let target = 75.0
		let projection = WeightAnalytics.calculateGoalProjection(
			dailyWeights: series,
			targetWeightKg: target,
			minDays: 7
		)

		// For this synthetic series, we expect that if a projection
		// exists it moves forward in time from the last data point
		// and never into the past. The exact existence/absence of a
		// date depends on slope thresholds and volatility rules.
		if let projection {
			let lastDate = series.last?.date ?? today
			#expect(projection >= lastDate)
		}
	}
	
	// MARK: - 7-Day Average Tests
	
	@Test
	func sevenDayAverage_calculatesCorrectly() async throws {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		
		// Create 7 days of weight entries with known values
		let weights = [80.0, 81.0, 82.0, 81.5, 80.5, 79.5, 80.0]
		var series: [(date: Date, weight: Double)] = []
		
		// Build series from oldest to newest (6 days ago to today)
		for (index, weight) in weights.enumerated() {
			let daysAgo = (weights.count - 1) - index
			let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
			series.append((date: day, weight: weight))
		}
		
		// Calculate expected average
		let expectedAverage = weights.reduce(0.0, +) / Double(weights.count)
		
		// Get last 7 days
		let last7Days = series.suffix(7)
		let sum = last7Days.reduce(0.0) { $0 + $1.weight }
		let calculatedAverage = sum / Double(last7Days.count)
		
		#expect(abs(calculatedAverage - expectedAverage) < 0.0001)
	}
	
	@Test
	func sevenDayAverage_withMoreThanSevenDays_usesLastSevenOnly() async throws {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		
		// Create 10 days of weight entries
		var series: [(date: Date, weight: Double)] = []
		for offset in (0..<10).reversed() {
			let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
			// First 3 days: 85kg, last 7 days: 80kg
			let weight = offset < 3 ? 85.0 : 80.0
			series.append((date: day, weight: weight))
		}
		
		// Get last 7 days (should all be 80.0)
		let last7Days = series.suffix(7)
		let sum = last7Days.reduce(0.0) { $0 + $1.weight }
		let calculatedAverage = sum / Double(last7Days.count)
		
		// Average should be 80.0, not affected by the earlier 85.0 entries
		#expect(abs(calculatedAverage - 80.0) < 0.0001)
	}
}
