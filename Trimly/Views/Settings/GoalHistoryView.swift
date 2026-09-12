//
//  GoalHistoryView.swift
//  Weigh
//
//  Created by Trimly on 12/07/2025.
//

import SwiftUI

struct GoalHistoryView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject private var deviceSettings: DeviceSettingsStore
	@Environment(\.dismiss) var dismiss
	@State private var selectedGoal: Goal?
    
	var body: some View {
		NavigationStack {
			let archived = dataManager.fetchGoalHistory()
			let activeAchieved = dataManager.fetchActiveGoal().flatMap { $0.completionReason == .achieved ? $0 : nil }
			let history = activeAchieved.map { [$0] + archived } ?? archived
			ScrollView {
				LazyVStack(spacing: 16) {
					ForEach(history) { goal in
						Button { selectedGoal = goal } label: { historyCard(goal) }
							.buttonStyle(.plain)
							.accessibilityHint(Text(L10n.EntryFeatures.goalHistoryDetail))
					}
				}
				.padding(24)
			}
			.navigationTitle(Text(L10n.Goals.historyTitle))
			.sheet(item: $selectedGoal) { GoalHistoryDetailView(goal: $0) }
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.doneButton)) { dismiss() }
						.buttonStyle(.borderedProminent)
						.tint(.accentColor)
				}
			}
			.overlay {
				if history.isEmpty {
					ContentUnavailableView(
						String(localized: L10n.Goals.noHistoryTitle),
						systemImage: "flag",
						description: Text(L10n.Goals.noHistoryDescription)
					)
				}
			}
		}
	}
    
	private func historyCard(_ goal: Goal) -> some View {
		WeighCardContainer(style: .popup) {
			VStack(alignment: .leading, spacing: 10) {
				HStack(alignment: .firstTextBaseline) {
					if deviceSettings.presentation.hideWeights {
						Text(L10n.Insights.privacyTitle)
					} else {
						Text(displayValue(goal.targetWeightKg))
							.font(.title3.weight(.semibold))
					}
					Spacer()
					if let reason = goal.completionReason {
						let pill = completionPillColors(for: reason)
						Text(completionLabel(for: reason))
							.font(.caption.weight(.semibold))
							.padding(.horizontal, 10)
							.padding(.vertical, 4)
							.background(pill.background)
							.foregroundStyle(pill.foreground)
							.clipShape(Capsule())
					}
				}
				Text(L10n.Goals.setOn(goal.startDate.formatted(date: .abbreviated, time: .omitted)))
					.font(.caption)
					.foregroundStyle(.secondary)
				if let completedDate = goal.completedDate {
					Text(L10n.Goals.completedOn(completedDate.formatted(date: .abbreviated, time: .omitted)))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				if !deviceSettings.presentation.hideWeights, let notes = goal.notes, !notes.isEmpty {
					Text(notes)
						.font(.callout)
						.foregroundStyle(.secondary)
				}
			}
		}
	}

	private func completionPillColors(for reason: CompletionReason) -> (foreground: Color, background: Color) {
		switch reason {
		case .achieved:
			return (Color.green, Color.green.opacity(0.15))
		case .changed:
			return (Color.blue, Color.blue.opacity(0.15))
		case .abandoned:
			return (Color.orange, Color.orange.opacity(0.15))
		}
	}

	private func completionLabel(for reason: CompletionReason) -> String {
		switch reason {
		case .achieved:
			return String(localized: L10n.Goals.completionAchieved)
		case .changed:
			return String(localized: L10n.Goals.completionChanged)
		case .abandoned:
			return String(localized: L10n.Goals.completionAbandoned)
		}
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
}
