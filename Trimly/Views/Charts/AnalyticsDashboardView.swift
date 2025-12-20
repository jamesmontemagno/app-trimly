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
						title: String(localized: L10n.Charts.statTotalChange),
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
					title: String(localized: L10n.Charts.statCheckIns),
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
							title: String(localized: L10n.Charts.statConsistency),
							value: consistency,
							color: .indigo
						)
					}
					.buttonStyle(.plain)
					.alert(String(localized: L10n.Charts.consistencyScoreAlertTitle), isPresented: $showingConsistencyInfo) {
						Button(String(localized: L10n.Common.okButton), role: .cancel) {}
					} message: {
						consistencyInfoMessage
					}
				}
				
				// Range Info
				FunStatCard(
					icon: "calendar",
					title: String(localized: L10n.Charts.statTimeframe),
					value: range.displayName,
					color: .orange
				)
			}
			
			Divider()
			
			// Average Weight Block
			VStack(spacing: 8) {
				Text(L10n.Charts.statAverageWeight)
					.font(.caption)
					.foregroundStyle(.secondary)
				
				Text(displayValueWithUnit(stats.average))
					.font(.title2.bold())
					.foregroundStyle(.primary)
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 8)
		}
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f", kg)
		}
		let value = unit.convert(fromKg: kg)
		return String(format: "%.1f", value)
	}
	
	private func displayValueWithUnit(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
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
		let entries = dataManager.fetchAllEntries().filter { !$0.isHidden }
		let windowDays = getWindowDays()
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		
		// Use goal start date if available, but limit to current window
		let goalStartDate = dataManager.fetchActiveGoal()?.startDate
		let effectiveStartDate: Date
		
		if let goalStart = goalStartDate {
			let normalizedGoalStart = calendar.startOfDay(for: goalStart)
			let daysSinceGoal = calendar.dateComponents([.day], from: normalizedGoalStart, to: today).day ?? 0
			
			// Use the smaller of: days since goal started, or window size
			if daysSinceGoal < windowDays {
				// Goal is within window - use goal start date
				effectiveStartDate = normalizedGoalStart
			} else {
				// Goal started before window - use window start date
				effectiveStartDate = calendar.date(byAdding: .day, value: -windowDays + 1, to: today) ?? normalizedGoalStart
			}
		} else {
			// No goal - use window start date
			effectiveStartDate = calendar.date(byAdding: .day, value: -windowDays + 1, to: today) ?? today
		}
		
		// Count unique days with entries in the effective window
		let uniqueDays = Set(entries.filter { $0.normalizedDate >= effectiveStartDate && $0.normalizedDate <= today }.map { $0.normalizedDate }).count
		
		// Calculate total days from effective start to today (inclusive)
		let totalDays = calendar.dateComponents([.day], from: effectiveStartDate, to: today).day ?? 0
		let totalDaysInclusive = totalDays + 1 // Include today
		
		guard totalDaysInclusive > 0 else { return nil }
		
		let score = Double(uniqueDays) / Double(totalDaysInclusive)
		let percentage = Int(score * 100)
		return "\(percentage)%"
	}
	
	private var consistencyInfoMessage: Text {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let windowDays = getWindowDays()
		
		if let goal = dataManager.fetchActiveGoal(),
		   let startDate = goal.startDate as Date? {
			let entries = dataManager.fetchAllEntries().filter { !$0.isHidden }
			let normalizedStartDate = calendar.startOfDay(for: startDate)
			
			// Calculate days since goal started
			let daysSinceGoal = calendar.dateComponents([.day], from: normalizedStartDate, to: today).day ?? 0
			
			if daysSinceGoal < windowDays {
				// Goal is within the window period - use goal start date
				let uniqueDays = Set(entries.filter { $0.normalizedDate >= normalizedStartDate && $0.normalizedDate <= today }.map { $0.normalizedDate }).count
				let totalDays = daysSinceGoal
				let totalDaysInclusive = totalDays + 1 // Include today
				let percentage = Int((Double(uniqueDays) / Double(totalDaysInclusive)) * 100)
				let dateStr = startDate.formatted(date: .long, time: .omitted)
				
				return Text(L10n.Charts.consistencyInfoWithGoal(uniqueDays, totalDaysInclusive, percentage, dateStr))
			} else {
				// Goal started before the window - use window limit
				let effectiveStartDate = calendar.date(byAdding: .day, value: -windowDays + 1, to: today) ?? normalizedStartDate
				let uniqueDays = Set(entries.filter { $0.normalizedDate >= effectiveStartDate && $0.normalizedDate <= today }.map { $0.normalizedDate }).count
				let percentage = Int((Double(uniqueDays) / Double(windowDays)) * 100)
				
				return Text(L10n.Charts.consistencyInfoGoalBeforeWindow(uniqueDays, windowDays, percentage, range.displayName.lowercased()))
			}
		} else {
			// No goal - use window
			let entries = dataManager.fetchAllEntries().filter { !$0.isHidden }
			let effectiveStartDate = calendar.date(byAdding: .day, value: -windowDays + 1, to: today) ?? today
			let uniqueDays = Set(entries.filter { $0.normalizedDate >= effectiveStartDate && $0.normalizedDate <= today }.map { $0.normalizedDate }).count
			let percentage = Int((Double(uniqueDays) / Double(windowDays)) * 100)
			
			return Text(L10n.Charts.consistencyInfoWithWindow(uniqueDays, windowDays, percentage, range.displayName.lowercased()))
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
