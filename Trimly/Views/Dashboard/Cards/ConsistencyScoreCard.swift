//
//  ConsistencyScoreCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct ConsistencyScoreCard: View {
	@EnvironmentObject var dataManager: DataManager
	@Binding var showingInfo: Bool
	let score: Double?
	@ScaledMetric(relativeTo: .title) private var scoreFontSize: CGFloat = 36
	
	var body: some View {
		Button {
			showingInfo = true
		} label: {
			VStack(spacing: 8) {
				HStack {
					Text(L10n.Dashboard.consistencyScore)
						.font(.subheadline)
						.foregroundStyle(.secondary)
					Spacer()
					Image(systemName: "info.circle")
						.font(.caption)
						.foregroundStyle(.blue)
				}
				
				if let score {
					let percentage = Int(score * 100)
					Text("\(percentage)%")
						.font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
						.foregroundStyle(consistencyColor(score))
					
					Text(consistencyLabel(score))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 16))
		}
		.buttonStyle(.plain)
		.accessibilityLabel(String(localized: L10n.Accessibility.consistencyScore))
		.accessibilityValue(accessibilityValue)
		.accessibilityHint(String(localized: L10n.Accessibility.consistencyScoreHint))
	}
	
	private func consistencyColor(_ score: Double) -> Color {
		if score >= 0.85 { return .green }
		if score >= 0.70 { return .blue }
		if score >= 0.50 { return .orange }
		return .red
	}
	
	private func consistencyLabel(_ score: Double) -> String {
		if score >= 0.85 { return String(localized: L10n.Dashboard.consistencyVery) }
		if score >= 0.70 { return String(localized: L10n.Dashboard.consistencyConsistent) }
		if score >= 0.50 { return String(localized: L10n.Dashboard.consistencyModerate) }
		return String(localized: L10n.Dashboard.consistencyBuilding)
	}
	
	private var accessibilityValue: String {
		if let score {
			let percentage = Int(score * 100)
			let label = consistencyLabel(score)
			return "\(percentage)%, \(label)"
		}
		return "No data available"
	}
}

func consistencyInfoMessage(dataManager: DataManager) -> Text {
	let calendar = Calendar.current
	let today = calendar.startOfDay(for: Date())
	
	if let goal = dataManager.fetchActiveGoal(),
	   let startDate = goal.startDate as Date? {
		let entries = dataManager.fetchAllEntries().filter { !$0.isHidden }
		let normalizedStartDate = calendar.startOfDay(for: startDate)
		let uniqueDays = Set(entries.filter { $0.normalizedDate >= normalizedStartDate && $0.normalizedDate <= today }.map { $0.normalizedDate }).count
		let totalDays = calendar.dateComponents([.day], from: normalizedStartDate, to: today).day ?? 0
		let totalDaysInclusive = totalDays + 1 // Include today
		let percentage = Int((Double(uniqueDays) / Double(totalDaysInclusive)) * 100)
		let dateStr = startDate.formatted(date: .long, time: .omitted)
		
		return Text(L10n.Dashboard.consistencyInfoWithGoalStart(uniqueDays, totalDaysInclusive, percentage, dateStr))
	} else {
		let visibleEntries = dataManager.fetchAllEntries().filter { !$0.isHidden }
		guard !visibleEntries.isEmpty else {
			return Text(L10n.Dashboard.consistencyNoEntriesMessage)
		}
		
		let sortedEntries = visibleEntries.sorted { $0.normalizedDate < $1.normalizedDate }
		guard let firstDate = sortedEntries.first?.normalizedDate else {
			return Text(L10n.Dashboard.consistencyNoEntriesMessage)
		}
		
		let effectiveStart = firstDate
		let uniqueDays = Set(visibleEntries.filter { $0.normalizedDate >= effectiveStart && $0.normalizedDate <= today }.map { $0.normalizedDate }).count
		let totalDays = calendar.dateComponents([.day], from: effectiveStart, to: today).day ?? 0
		let totalDaysInclusive = totalDays + 1 // Include today
		let percentage = Int((Double(uniqueDays) / Double(totalDaysInclusive)) * 100)
		let dateStr = firstDate.formatted(date: .long, time: .omitted)
		
		return Text(L10n.Dashboard.consistencyInfoWithFirstEntry(uniqueDays, totalDaysInclusive, percentage, dateStr))
	}
}
