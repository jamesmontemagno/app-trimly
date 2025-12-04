//
//  AchievementsView.swift
//  TrimTally
//
//  Created by Trimly on 11/29/25.
//

import SwiftUI
import Combine
import Foundation

struct AchievementsView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var storeManager: StoreManager
	@StateObject private var achievementService = AchievementService()
	@State private var selectedSnapshot: AchievementSnapshot?
	
	var body: some View {
		NavigationStack {
			ScrollView {
				LazyVStack(alignment: .leading, spacing: 24) {
					ForEach(groupedSnapshots) { group in
						Section {
							ForEach(group.snapshots) { snapshot in
								AchievementCard(snapshot: snapshot, diagnostics: achievementService.diagnostics) {
									selectedSnapshot = snapshot
								}
							}
						} header: {
							Text(group.category.title)
								.font(.headline)
								.frame(maxWidth: .infinity, alignment: .leading)
						}
					}
					if hasPremiumLock && !storeManager.isPro {
						premiumUpsellHint
					}
				}
				.padding(.horizontal)
			}
			.navigationTitle(Text(L10n.Achievements.navigationTitle))
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button(action: refresh) {
						Image(systemName: "arrow.clockwise")
					}
					.accessibilityLabel(Text(L10n.Common.refresh))
				}
			}
			.onAppear(perform: refresh)
			.onReceive(dataManager.objectWillChange) { _ in
				refresh()
			}
			.onChange(of: storeManager.isPro) { _, _ in
				refresh()
			}
			.sheet(item: $selectedSnapshot) { snapshot in
				AchievementDiagnosticsSheet(
					snapshot: snapshot,
					diagnostics: achievementService.diagnostics
				)
			}
		}
	}
	
	private var groupedSnapshots: [AchievementCategoryGroup] {
		let groups = Dictionary(grouping: achievementService.snapshots) { $0.descriptor.category }
		return AchievementCategory.allCases.compactMap { category in
			guard let snapshots = groups[category], !snapshots.isEmpty else { return nil }
			return AchievementCategoryGroup(category: category, snapshots: snapshots)
		}
	}
	
	private var hasPremiumLock: Bool {
		achievementService.snapshots.contains { $0.requiresPro }
	}
	
	private var premiumUpsellHint: some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: "star.fill")
				.foregroundStyle(.yellow)
			Text(L10n.Achievements.sectionPremiumHint)
				.font(.callout)
				.foregroundStyle(.secondary)
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
	
	private func refresh() {
		achievementService.refresh(using: dataManager, isPro: storeManager.isPro)
	}
}

private struct AchievementCard: View {
	let snapshot: AchievementSnapshot
	let diagnostics: AchievementDiagnostics?
	var onInspect: (() -> Void)? = nil
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .top) {
				Label {
					Text(snapshot.descriptor.title)
						.font(.headline)
				} icon: {
					Image(systemName: snapshot.descriptor.iconName)
						.symbolRenderingMode(.hierarchical)
				}
				Spacer()
				badgeStack
			}
			if snapshot.requiresPro {
				Text(L10n.Achievements.proUnlockLine)
					.font(.subheadline)
					.foregroundStyle(.secondary)
			} else {
				Text(snapshot.descriptor.detail)
					.font(.subheadline)
					.foregroundStyle(.secondary)
				// Show detailed progress text
				if let detailedProgress = detailedProgressText {
					Text(detailedProgress)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				ProgressView(value: min(max(snapshot.progressValue, 0), 1)) {
					Text(L10n.Achievements.progressLabel)
						.font(.caption)
						.foregroundStyle(.secondary)
				} currentValueLabel: {
					Text(progressDisplay)
						.font(.caption)
				}
				if !snapshot.isUnlocked {
					Text(L10n.Achievements.lockedBadge)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.contentShape(RoundedRectangle(cornerRadius: 16))
		.onTapGesture {
			onInspect?()
		}
		.overlay(alignment: .topTrailing) {
			if snapshot.isUnlocked {
				Image(systemName: "seal.fill")
					.symbolRenderingMode(.palette)
					.foregroundStyle(.green, .white)
					.padding(8)
			}
		}
	}
	
	private var badgeStack: some View {
		HStack(spacing: 6) {
			if snapshot.descriptor.isPremium {
				Text(L10n.Achievements.proBadge)
					.font(.caption.bold())
					.padding(.vertical, 4)
					.padding(.horizontal, 8)
					.background(Color.yellow.opacity(0.15))
					.clipShape(Capsule())
			}
			if snapshot.isUnlocked {
				Image(systemName: "checkmark.seal.fill")
					.foregroundStyle(.green)
			}
		}
	}
	
	private var progressDisplay: String {
		let percent = Int(snapshot.progressValue * 100)
		return "\(percent)%"
	}
	
	/// Provides detailed progress text based on achievement type and current status
	private var detailedProgressText: String? {
		guard let diag = diagnostics else { return nil }
		switch snapshot.descriptor.metric {
		case .totalEntries(let target):
			return String(localized: L10n.Achievements.progressEntries(diag.totalEntries, target))
		case .uniqueDays(let target):
			return String(localized: L10n.Achievements.progressUniqueDays(diag.uniqueDayCount, target))
		case .streakDays(let target):
			return String(localized: L10n.Achievements.progressStreakDays(diag.longestStreak, target))
		case .consistency(let threshold):
			let currentPercent = Int((diag.consistencyScore * 100).rounded())
			let targetPercent = Int((threshold * 100).rounded())
			let minDaysRequired = 10
			if diag.uniqueDayCount < minDaysRequired {
				return String(localized: L10n.Achievements.progressConsistencyWithDays(
					currentPercent, targetPercent, diag.uniqueDayCount, minDaysRequired
				))
			} else {
				return String(localized: L10n.Achievements.progressConsistency(currentPercent, targetPercent))
			}
		case .goalsAchieved(let target):
			return String(localized: L10n.Achievements.progressGoals(diag.goalsAchieved, target))
		case .remindersEnabled:
			return diag.remindersEnabled
				? String(localized: L10n.Achievements.progressRemindersOn)
				: String(localized: L10n.Achievements.progressRemindersOff)
		case .reminderConsistency(let targetRatio):
			let currentPercent = Int((diag.recentReminderRatio * 100).rounded())
			let targetPercent = Int((targetRatio * 100).rounded())
			return String(localized: L10n.Achievements.progressReminderConsistency(currentPercent, targetPercent))
		}
	}
}

private struct AchievementDiagnosticsSheet: View {
	let snapshot: AchievementSnapshot
	let diagnostics: AchievementDiagnostics?
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			List {
				metricSection
				contextSection
			}
			.navigationTitle(Text(L10n.Debug.Achievements.sheetTitle))
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(L10n.Common.doneButton, action: dismiss.callAsFunction)
				}
			}
		}
	}

	private var metricSection: some View {
		Section(header: Text(L10n.Debug.Achievements.metricSection)) {
			LabeledContent {
				Text(progressDisplay)
			} label: {
				Text(L10n.Achievements.progressLabel)
			}
			LabeledContent {
				Text(snapshot.isUnlocked ? yesText : noText)
			} label: {
				Text(L10n.Debug.Achievements.unlockStatus)
			}
			if snapshot.requiresPro {
				Text(L10n.Debug.Achievements.requiresPro)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			ForEach(metricDetails) { detail in
				LabeledContent {
					Text(detail.value)
				} label: {
					Text(detail.title)
				}
			}
		}
	}

	private var contextSection: some View {
		Section(header: Text(L10n.Debug.Achievements.contextSection)) {
			if let diagnostics {
				LabeledContent {
					Text("\(diagnostics.totalEntries)")
				} label: {
					Text(L10n.Debug.Achievements.totalEntries)
				}
				LabeledContent {
					Text("\(diagnostics.uniqueDayCount)")
				} label: {
					Text(L10n.Debug.Achievements.uniqueDays)
				}
				LabeledContent {
					Text("\(diagnostics.longestStreak)")
				} label: {
					Text(L10n.Debug.Achievements.longestStreak)
				}
				LabeledContent {
					Text(percentString(diagnostics.consistencyScore))
				} label: {
					Text(L10n.Debug.Achievements.consistencyScore)
				}
				LabeledContent {
					Text("\(diagnostics.consistencyWindowDays)")
				} label: {
					Text(L10n.Debug.Achievements.consistencyWindow)
				}
				LabeledContent {
					Text("\(diagnostics.goalsAchieved)")
				} label: {
					Text(L10n.Debug.Achievements.goalsAchieved)
				}
				LabeledContent {
					Text(diagnostics.remindersEnabled ? yesText : noText)
				} label: {
					Text(L10n.Debug.Achievements.remindersEnabled)
				}
				LabeledContent {
					Text(percentString(diagnostics.recentReminderRatio))
				} label: {
					Text(L10n.Debug.Achievements.reminderRatio)
				}
				LabeledContent {
					Text(diagnostics.evaluatedAt.formatted(date: .abbreviated, time: .shortened))
				} label: {
					Text(L10n.Debug.Achievements.evaluatedAt)
				}
			} else {
				Text(L10n.Debug.Achievements.noDiagnostics)
			}
		}
	}

	private var progressDisplay: String {
		"\(Int(snapshot.progressValue * 100))%"
	}

	private var metricDetails: [MetricDetail] {
		switch snapshot.descriptor.metric {
		case .totalEntries(let target):
			return [MetricDetail(title: L10n.Debug.Achievements.targetValue, value: "\(target)")]
		case .uniqueDays(let target):
			return [MetricDetail(title: L10n.Debug.Achievements.targetUniqueDays, value: "\(target)")]
		case .streakDays(let target):
			return [MetricDetail(title: L10n.Debug.Achievements.targetStreakDays, value: "\(target)")]
		case .consistency(let threshold):
			return [MetricDetail(title: L10n.Debug.Achievements.consistencyThreshold, value: percentString(threshold))]
		case .goalsAchieved(let target):
			return [MetricDetail(title: L10n.Debug.Achievements.targetGoals, value: "\(target)")]
		case .remindersEnabled:
			return [MetricDetail(title: L10n.Debug.Achievements.remindersRequired, value: yesText)]
		case .reminderConsistency(let ratio):
			return [MetricDetail(title: L10n.Debug.Achievements.reminderRatioTarget, value: percentString(ratio))]
		}
	}

	private func percentString(_ value: Double) -> String {
		let percent = Int((value * 100).rounded())
		return "\(percent)%"
	}

	private var yesText: String { String(localized: L10n.Common.booleanYes) }
	private var noText: String { String(localized: L10n.Common.booleanNo) }

	private struct MetricDetail: Identifiable {
		let id = UUID()
		let title: LocalizedStringResource
		let value: String
	}
}

private struct AchievementCategoryGroup: Identifiable {
	let category: AchievementCategory
	let snapshots: [AchievementSnapshot]
	var id: AchievementCategory { category }
}

#Preview {
	NavigationStack {
		AchievementsView()
			.environmentObject(DataManager(inMemory: true))
			.environmentObject(StoreManager())
	}
}
