//
//  ProgressSummaryCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI

struct ProgressSummaryCard: View {
	@EnvironmentObject var dataManager: DataManager
	let goal: Goal?
	let currentWeight: Double?
	let startWeight: Double?
	
	var body: some View {
		VStack(spacing: 12) {
			if let goal, let currentWeight, let startWeight {
				HStack(spacing: 20) {
					VStack(alignment: .leading, spacing: 4) {
						Text(L10n.Dashboard.fromStart)
							.font(.caption)
							.foregroundStyle(.secondary)
						
						let delta = currentWeight - startWeight
						let deltaDisplay = formatDelta(delta)
						Text(deltaDisplay)
							.font(.title3.bold())
							.foregroundStyle(delta < 0 ? .green : delta > 0 ? .orange : .primary)
					}
					
					Divider()
					
					VStack(alignment: .leading, spacing: 4) {
						Text(L10n.Dashboard.toGoal)
							.font(.caption)
							.foregroundStyle(.secondary)
						
						let remaining = currentWeight - goal.targetWeightKg
						let remainingDisplay = formatDelta(abs(remaining))
						Text(remainingDisplay)
							.font(.title3.bold())
							.foregroundStyle(.blue)
					}
					
					Divider()
					
					VStack(alignment: .leading, spacing: 4) {
						Text(L10n.Dashboard.progress)
							.font(.caption)
							.foregroundStyle(.secondary)
						
						let totalChange = goal.targetWeightKg - startWeight
						let currentChange = currentWeight - startWeight
						let progress = totalChange != 0 ? (currentChange / totalChange) * 100 : 0
						
						Text("\(Int(min(100, max(0, progress))))%")
							.font(.title3.bold())
							.foregroundStyle(.purple)
					}
				}
				.frame(maxWidth: .infinity)
				
				if let goalStartDate = goal.startDate as Date? {
					let startDisplay = displayValue(startWeight)
					let targetDisplay = displayValue(goal.targetWeightKg)
					let dateDisplay = goalStartDate.formatted(date: .abbreviated, time: .omitted)
					
					Divider()
					
					VStack(alignment: .leading, spacing: 6) {
						HStack(spacing: 10) {
							Text(String(localized: L10n.Dashboard.progressMetaStart(startDisplay)))
								.font(.caption)
								.foregroundStyle(.secondary)
							Text(String(localized: L10n.Dashboard.progressMetaSeparator))
								.font(.caption)
								.foregroundStyle(.tertiary)
							Text(String(localized: L10n.Dashboard.progressMetaTarget(targetDisplay)))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						HStack(spacing: 10) {
							Text(String(localized: L10n.Dashboard.progressMetaStartDate(dateDisplay)))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
				}
			} else {
				Text(L10n.Dashboard.setGoalPrompt)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
		.padding()
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}

		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
	
	private func formatDelta(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}

		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
}
