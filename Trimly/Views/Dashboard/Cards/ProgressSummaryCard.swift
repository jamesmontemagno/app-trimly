//
//  ProgressSummaryCard.swift
//  TrimTally
//
//  Created by Trimly on 12/7/2025.
//

import SwiftUI
import SwiftData

struct ProgressSummaryCard: View {
	@EnvironmentObject var dataManager: DataManager
	let goal: Goal?
	let currentWeight: Double?
	let startWeight: Double?
	
	/// Determine if user is trying to gain or lose weight based on goal
	private var isGaining: Bool {
		guard let goal, let startWeight else { return false }
		return goal.targetWeightKg > startWeight
	}
	
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
							.foregroundStyle(deltaColor(delta: delta, isGaining: isGaining))
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
					let checkInsCount = countCheckIns(since: goalStartDate)
					
					Divider()
					
					HStack(spacing: 16) {
						VStack(alignment: .leading, spacing: 4) {
							Text(String(localized: L10n.Dashboard.progressMetaStart(startDisplay)))
								.font(.caption)
								.foregroundStyle(.secondary)
							Text(String(localized: L10n.Dashboard.progressMetaTarget(targetDisplay)))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						VStack(alignment: .trailing, spacing: 4) {
							Text(String(localized: L10n.Dashboard.progressMetaStartDate(dateDisplay)))
								.font(.caption)
								.foregroundStyle(.secondary)
							Text(String(localized: L10n.Dashboard.progressMetaCheckIns(checkInsCount)))
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
					.frame(maxWidth: .infinity)
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
	
	/// Determine the color for the delta based on goal direction
	private func deltaColor(delta: Double, isGaining: Bool) -> Color {
		if delta == 0 { return .primary }
		
		// For gaining goals: positive delta is good (green), negative is not ideal (orange)
		// For losing goals: negative delta is good (green), positive is not ideal (orange)
		if isGaining {
			return delta > 0 ? .green : .orange
		} else {
			return delta < 0 ? .green : .orange
		}
	}
	
	/// Count check-ins (weight entries) since the goal start date
	private func countCheckIns(since startDate: Date) -> Int {
		let normalizedStartDate = WeightEntry.normalizeDate(startDate)
		let descriptor = FetchDescriptor<WeightEntry>(
			predicate: #Predicate { entry in
				!entry.isHidden && entry.normalizedDate >= normalizedStartDate
			}
		)
		return (try? dataManager.modelContext.fetch(descriptor))?.count ?? 0
	}
}
