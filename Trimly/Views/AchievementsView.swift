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
	@State private var showingAddEntry = false
	@State private var showingPaywall = false
	
	var body: some View {
		NavigationStack {
			ScrollView {
				LazyVStack(alignment: .leading, spacing: 24) {
					// Unlock progress summary card
					unlockProgressCard
					
					ForEach(groupedSnapshots) { group in
						Section {
							ForEach(group.snapshots) { snapshot in
								AchievementCard(snapshot: snapshot, diagnostics: achievementService.diagnostics) {
									if snapshot.requiresPro {
										showingPaywall = true
									} else {
										selectedSnapshot = snapshot
									}
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
					Button {
						showingAddEntry = true
					} label: {
						Image(systemName: "plus")
					}
					.accessibilityLabel(Text(L10n.Common.addWeight))
					.accessibilityHint("Opens form to log a new weight")
				}
				#if os(iOS)
				ToolbarItem(placement: .topBarLeading) {
					Button(action: refresh) {
						Image(systemName: "arrow.clockwise")
					}
					.accessibilityLabel(Text(L10n.Common.refresh))
					.accessibilityHint("Recalculates achievement progress")
				}
				#else
				ToolbarItem(placement: .navigation) {
					Button(action: refresh) {
						Image(systemName: "arrow.clockwise")
					}
					.accessibilityLabel(Text(L10n.Common.refresh))
					.accessibilityHint("Recalculates achievement progress")
				}
				#endif
			}
			.sheet(isPresented: $showingAddEntry) {
				AddWeightEntryView()
			}
			.sheet(isPresented: $showingPaywall) {
				PaywallView()
			}
			.onAppear(perform: refresh)
			.onReceive(dataManager.objectWillChange) { _ in
				refresh()
			}
			.onChange(of: storeManager.isPro) { _, _ in
				refresh()
			}
			#if DEBUG
			.sheet(item: $selectedSnapshot) { snapshot in
				AchievementDiagnosticsSheet(
					snapshot: snapshot,
					diagnostics: achievementService.diagnostics
				)
			}
			#endif
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
	
	private var unlockedCount: Int {
		achievementService.snapshots.filter { $0.isUnlocked }.count
	}
	
	private var totalCount: Int {
		achievementService.snapshots.count
	}
	
	private var unlockProgressCard: some View {
		HStack(spacing: 16) {
			// Trophy icon
			ZStack {
				Circle()
					.fill(.yellow.opacity(0.15))
					.frame(width: 60, height: 60)
				Image(systemName: "trophy.fill")
					.font(.system(size: 28))
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.yellow)
			}
			.accessibilityHidden(true)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(L10n.Achievements.unlockedProgress(unlockedCount, totalCount))
					.font(.headline)
				
				ProgressView(value: totalCount > 0 ? Double(unlockedCount) / Double(totalCount) : 0) {
					Text(L10n.Achievements.progressLabel)
				}
				.tint(.yellow)
				
				Text(L10n.Achievements.keepGoingHint)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.accessibilityElement(children: .combine)
		.accessibilityLabel("Achievement progress")
		.accessibilityValue("\(unlockedCount) of \(totalCount) achievements unlocked")
	}
	
	private var premiumUpsellHint: some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: "star.fill")
				.foregroundStyle(.yellow)
				.accessibilityHidden(true)
			Text(L10n.Achievements.sectionPremiumHint)
				.font(.callout)
				.foregroundStyle(.secondary)
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.contentShape(RoundedRectangle(cornerRadius: 16))
		.onTapGesture {
			showingPaywall = true
		}
		.accessibilityElement(children: .combine)
		.accessibilityHint("Opens TrimTally Pro upgrade page")
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
						.accessibilityHidden(true)
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
				// Only show progress details and bar for locked achievements
				if !snapshot.isUnlocked {
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
					Text(L10n.Achievements.lockedBadge)
						.font(.caption)
						.foregroundStyle(.secondary)
				} else {
					// Show unlocked date for unlocked achievements
					if let unlockedDate = snapshot.model.unlockedAt {
						Text(L10n.Achievements.unlockedDate(unlockedDate))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
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
				Image(systemName: "medal.fill")
					.symbolRenderingMode(.palette)
					.foregroundStyle(.orange, .yellow)
					.padding(8)
					.accessibilityLabel("Unlocked")
			}
		}
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibilityLabel)
		.accessibilityValue(accessibilityValue)
		.accessibilityHint(accessibilityHint)
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
		}
	}
	
	private var progressDisplay: String {
		let percent = Int(snapshot.progressValue * 100)
		return "\(percent)%"
	}
	
	private var accessibilityLabel: String {
		var label = "Achievement: \(snapshot.descriptor.title)"
		if snapshot.isUnlocked {
			label += ", unlocked"
		} else {
			label += ", locked"
		}
		if snapshot.descriptor.isPremium {
			label += ", premium"
		}
		return label
	}
	
	private var accessibilityValue: String {
		if snapshot.requiresPro {
			return "Requires TrimTally Pro to unlock"
		}
		if snapshot.isUnlocked {
			if let unlockedDate = snapshot.model.unlockedAt {
				let formatter = DateFormatter()
				formatter.dateStyle = .medium
				return "Unlocked on \(formatter.string(from: unlockedDate))"
			}
			return "Unlocked"
		}
		return "Progress: \(progressDisplay)"
	}
	
	private var accessibilityHint: String {
		if snapshot.requiresPro {
			return "Tap to upgrade to TrimTally Pro"
		}
		#if DEBUG
		return "Tap to view diagnostic details"
		#else
		return ""
		#endif
	}
	
	/// Provides detailed progress text based on achievement type and current status
	private var detailedProgressText: String? {
		#if DEBUG
		guard let diag = diagnostics else { return nil }
		switch snapshot.descriptor.metric {
		case .totalEntries(let target):
			return String(localized: L10n.Achievements.progressEntries(diag.totalEntries, target))
		case .uniqueDays(let target):
			return String(localized: L10n.Achievements.progressUniqueDays(diag.uniqueDayCount, target))
		case .streakDays(let target):
			return String(localized: L10n.Achievements.progressStreakDays(diag.currentStreak, target))
		case .consistency(let threshold, let minDays):
			let currentPercent = Int((diag.consistencyScore * 100).rounded())
			let targetPercent = Int((threshold * 100).rounded())
			if diag.uniqueDayCount < minDays {
				return String(localized: L10n.Achievements.progressConsistencyWithDays(
					currentPercent, targetPercent, diag.uniqueDayCount, minDays
				))
			} else {
				return String(localized: L10n.Achievements.progressConsistency(currentPercent, targetPercent))
			}
		case .goalsAchieved(let target):
			return String(localized: L10n.Achievements.progressGoals(diag.goalsAchieved, target))
		case .goalProgress:
			let currentPercent = Int(diag.goalProgressPercent.rounded())
			return String(localized: L10n.Achievements.progressGoalHalfway(currentPercent))
		case .sameWeightStreak(let days):
			return String(localized: L10n.Achievements.progressSteadyState(diag.sameWeightStreakDays, days))
		case .remindersEnabled:
			return diag.remindersEnabled
				? String(localized: L10n.Achievements.progressRemindersOn)
				: String(localized: L10n.Achievements.progressRemindersOff)
		case .reminderConsistency(let targetRatio):
			let currentPercent = Int((diag.recentReminderRatio * 100).rounded())
			let targetPercent = Int((targetRatio * 100).rounded())
			return String(localized: L10n.Achievements.progressReminderConsistency(currentPercent, targetPercent))
		}
		#else
		return nil
		#endif
	}
}

#if DEBUG
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
						.buttonStyle(.borderedProminent)
						.tint(.accentColor)
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
					Text("\(diagnostics.currentStreak)")
				} label: {
					Text(L10n.Debug.Achievements.currentStreak)
				}
				LabeledContent {
					Text(percentString(diagnostics.consistencyScore))
				} label: {
					Text(L10n.Debug.Achievements.consistencyScore)
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
		case .consistency(let threshold, let minDays):
			return [
				MetricDetail(title: L10n.Debug.Achievements.consistencyThreshold, value: percentString(threshold)),
				MetricDetail(title: "Min Days", value: "\(minDays)")
			]
		case .goalsAchieved(let target):
			return [MetricDetail(title: L10n.Debug.Achievements.targetGoals, value: "\(target)")]
		case .goalProgress(let threshold):
			return [MetricDetail(title: "Goal Progress Threshold", value: "\(Int(threshold))%")]
		case .sameWeightStreak(let days):
			return [MetricDetail(title: "Same Weight Days", value: "\(days)")]
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
#endif

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
