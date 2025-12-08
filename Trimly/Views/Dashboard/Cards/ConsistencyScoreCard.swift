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
						.font(.system(size: 36, weight: .bold, design: .rounded))
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
}

func consistencyInfoMessage(dataManager: DataManager) -> Text {
	if let goal = dataManager.fetchActiveGoal(),
	   let startDate = goal.startDate as Date? {
		let entries = dataManager.fetchAllEntries()
		let normalizedStartDate = WeightEntry.normalizeDate(startDate)
		let uniqueDays = Set(entries.filter { $0.normalizedDate >= normalizedStartDate }.map { $0.normalizedDate }).count
		let totalDays = max(1, Calendar.current.dateComponents([.day], from: normalizedStartDate, to: Date()).day ?? 1)
		let percentage = Int((Double(uniqueDays) / Double(totalDays)) * 100)
		let dateStr = startDate.formatted(date: .long, time: .omitted)
		
		return Text("How it's calculated:\n\nDays with entries: \(uniqueDays)\nTotal days since goal start: \(totalDays)\nFormula: \(uniqueDays) ÷ \(totalDays) = \(percentage)%\n\nGoal start date: \(dateStr)\n\nTrack your logging habits over time. Higher consistency helps build sustainable weight management habits.")
	} else {
		let entries = dataManager.fetchAllEntries()
		let windowDays = 30
		let uniqueDays = Set(entries.map { $0.normalizedDate }).count
		let percentage = Int((Double(uniqueDays) / Double(windowDays)) * 100)
		
		return Text("How it's calculated:\n\nDays with entries: \(uniqueDays)\nRolling window: \(windowDays) days\nFormula: \(uniqueDays) ÷ \(windowDays) = \(percentage)%\n\nNo active goal - using 30-day rolling window.\n\nTrack your logging habits over time. Higher consistency helps build sustainable weight management habits.")
	}
}
