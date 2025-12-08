//
//  AnalyticsDashboardView.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct AnalyticsDashboardView: View {
	let stats: ChartStats
	let data: [ChartDataPoint]
	let range: ChartRange
	@EnvironmentObject var dataManager: DataManager
	@State private var showingConsistencyInfo = false

	var body: some View {
		VStack(spacing: 16) {
			Divider()
			
			// Row 1: Basic Stats (Min/Max/Avg)
			HStack(spacing: 20) {
				StatItem(label: String(localized: L10n.Charts.statMin), value: displayValue(stats.min), color: .green)
				StatItem(label: String(localized: L10n.Charts.statMax), value: displayValue(stats.max), color: .red)
				StatItem(label: String(localized: L10n.Charts.statAvg), value: displayValue(stats.average), color: .blue)
			}
			
			Divider()
			
			// Row 2: Fun Analytics
			LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
				// Trend
				if let trend = calculateTrend() {
					FunStatCard(
						icon: trend.icon,
						title: String(localized: L10n.Dashboard.trendTitle),
						value: trend.text,
						color: trend.color
					)
				}
				
				// Total Change
				if let change = calculateChange() {
					FunStatCard(
						icon: change.value < 0 ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill",
						title: "Total Change",
						value: change.text,
						color: change.value < 0 ? .green : .red
					)
				}
				
				// Goal Projection
				if let projection = calculateProjection() {
					FunStatCard(
						icon: "calendar.badge.clock",
						title: String(localized: L10n.Dashboard.estimatedGoalDate),
						value: projection,
						color: .purple
					)
				}
				
				// Check-ins
				FunStatCard(
					icon: "checkmark.circle.fill",
					title: "Check-ins",
					value: "\(data.count)",
					color: .blue
				)
				
				// Consistency
				if let consistency = calculateConsistency() {
					Button {
						showingConsistencyInfo = true
					} label: {
						FunStatCard(
							icon: "chart.bar.fill",
							title: "Consistency",
							value: consistency,
							color: .indigo
						)
					}
					.buttonStyle(.plain)
					.alert("Consistency Score", isPresented: $showingConsistencyInfo) {
						Button("OK", role: .cancel) {}
					} message: {
						consistencyInfoMessage
					}
				}
				
				// Range Info
				FunStatCard(
					icon: "calendar",
					title: "Timeframe",
					value: range.displayName,
					color: .orange
				)
			}
		}
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f", kg)
		}
		let value = unit.convert(fromKg: kg)
		return String(format: "%.1f", value)
	}
	
	private func calculateTrend() -> (text: String, icon: String, color: Color)? {
		let tuples = data.map { (date: $0.date, weight: $0.weight) }
		let trend = WeightAnalytics.classifyTrend(dailyWeights: tuples)
		
		switch trend {
		case .downward:
			return (trend.description, "chart.line.downtrend.xyaxis", .green)
		case .upward:
			return (trend.description, "chart.line.uptrend.xyaxis", .red)
		case .stable:
			return (trend.description, "arrow.right", .blue)
		}
	}
	
	private func calculateChange() -> (text: String, value: Double)? {
		guard let first = data.first, let last = data.last else { return nil }
		let diff = last.weight - first.weight
		let absDiff = abs(diff)
		let displayDiff = displayValue(absDiff)
		let sign = diff < 0 ? "-" : "+"
		
		guard let unit = dataManager.settings?.preferredUnit else { return nil }
		return ("\(sign)\(displayDiff) \(unit.symbol)", diff)
	}
	
	private func calculateProjection() -> String? {
		guard let goal = dataManager.fetchActiveGoal() else { return nil }
		let tuples = data.map { (date: $0.date, weight: $0.weight) }
		
		if let date = WeightAnalytics.calculateGoalProjection(
			dailyWeights: tuples,
			targetWeightKg: goal.targetWeightKg
		) {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			formatter.timeStyle = .none
			return formatter.string(from: date)
		}
		return nil
	}
	
	private func calculateConsistency() -> String? {
		let entries = dataManager.fetchAllEntries()
		let windowDays = getWindowDays()
		
		// Use goal start date if available, but limit to current window
		let goalStartDate = dataManager.fetchActiveGoal()?.startDate
		let effectiveStartDate: Date?
		
		if let goalStart = goalStartDate {
			let calendar = Calendar.current
			let today = calendar.startOfDay(for: Date())
			let daysSinceGoal = calendar.dateComponents([.day], from: goalStart, to: today).day ?? 0
			
			// Use the smaller of: days since goal started, or window size
			let effectiveDays = min(daysSinceGoal + 1, windowDays)
			effectiveStartDate = calendar.date(byAdding: .day, value: -effectiveDays + 1, to: today)
		} else {
			effectiveStartDate = nil
		}
		
		guard let score = WeightAnalytics.calculateConsistencyScore(
			entries: entries,
			goalStartDate: effectiveStartDate
		) else {
			return nil
		}
		
		let percentage = Int(score * 100)
		return "\(percentage)%"
	}
	
	private var consistencyInfoMessage: Text {
		if let goal = dataManager.fetchActiveGoal(),
		   let startDate = goal.startDate as Date? {
			let entries = dataManager.fetchAllEntries()
			let calendar = Calendar.current
			let today = calendar.startOfDay(for: Date())
			let normalizedStartDate = WeightEntry.normalizeDate(startDate)
			let windowDays = getWindowDays()
			
			// Calculate days since goal started
			let daysSinceGoal = calendar.dateComponents([.day], from: normalizedStartDate, to: today).day ?? 0
			let effectiveDays = min(daysSinceGoal + 1, windowDays)
			
			// Calculate effective start date for window
			let effectiveStartDate = calendar.date(byAdding: .day, value: -effectiveDays + 1, to: today) ?? normalizedStartDate
			
			let uniqueDays = Set(entries.filter { $0.normalizedDate >= effectiveStartDate }.map { $0.normalizedDate }).count
			let percentage = Int((Double(uniqueDays) / Double(effectiveDays)) * 100)
			
			if daysSinceGoal + 1 <= windowDays {
				// Goal is within the window period
				let dateStr = startDate.formatted(date: .long, time: .omitted)
				return Text("How it's calculated:\n\nDays with entries: \(uniqueDays)\nDays since goal start: \(effectiveDays)\nFormula: \(uniqueDays) ÷ \(effectiveDays) = \(percentage)%\n\nGoal start: \(dateStr)\n\nTrack your logging habits over time. Higher consistency helps build sustainable weight management habits.")
			} else {
				// Goal started before the window, use window limit
				return Text("How it's calculated:\n\nDays with entries: \(uniqueDays)\nWindow: \(effectiveDays) days (\(range.displayName.lowercased()))\nFormula: \(uniqueDays) ÷ \(effectiveDays) = \(percentage)%\n\nGoal started before this window - using \(range.displayName.lowercased()) period.\n\nTrack your logging habits over time. Higher consistency helps build sustainable weight management habits.")
			}
		} else {
			let entries = dataManager.fetchAllEntries()
			let windowDays = getWindowDays()
			let uniqueDays = Set(entries.map { $0.normalizedDate }).count
			let percentage = Int((Double(uniqueDays) / Double(windowDays)) * 100)
			
			return Text("How it's calculated:\n\nDays with entries: \(uniqueDays)\nWindow: \(windowDays) days\nFormula: \(uniqueDays) ÷ \(windowDays) = \(percentage)%\n\nNo active goal - using \(range.displayName.lowercased()) window.\n\nTrack your logging habits over time. Higher consistency helps build sustainable weight management habits.")
		}
	}
	
	private func getWindowDays() -> Int {
		switch range {
		case .week: return 7
		case .month: return 30
		case .quarter: return 90
		case .year: return 365
		}
	}
}
