//
//  AchievementService.swift
//  TrimTally
//
//  Created by Trimly on 11/29/25.
//

import Foundation
import Combine
import SwiftUI
import OSLog

@MainActor
final class AchievementService: ObservableObject {
	@Published private(set) var snapshots: [AchievementSnapshot] = []
#if DEBUG
	@Published private(set) var diagnostics: AchievementDiagnostics?
#else
	// Diagnostics are debug-only; expose a nil placeholder in release builds
	var diagnostics: AchievementDiagnostics? { nil }
#endif
	
	private let definitions: [AchievementDescriptor] = AchievementDescriptor.catalog
	private let logger = Logger(subsystem: "com.trimly.TrimTally", category: "Achievements")
	
	func refresh(using dataManager: DataManager, isPro: Bool) {
		let context = EvaluationContext(dataManager: dataManager)
		#if DEBUG
		diagnostics = context.makeDiagnosticsSnapshot()
		#endif
		logger.debug(
			"Refresh stats — entries: \(context.totalEntries, privacy: .public), unique days: \(context.uniqueDayCount, privacy: .public), consistency: \(context.consistencyScore, privacy: .public)"
		)
		var updated: [AchievementSnapshot] = []
		for descriptor in definitions {
			let evaluation = evaluate(descriptor, context: context)
			let canUnlock = !descriptor.isPremium || isPro
			let achievement = dataManager.updateAchievement(
				key: descriptor.key,
				isPremium: descriptor.isPremium,
				progress: evaluation.progress,
				unlocked: evaluation.unlocked && canUnlock
			)
			let snapshot = AchievementSnapshot(
				descriptor: descriptor,
				model: achievement,
				computedUnlocked: evaluation.unlocked,
				canUnlock: canUnlock
			)
			updated.append(snapshot)
		}
		snapshots = updated
	}
	
	private func evaluate(_ descriptor: AchievementDescriptor, context: EvaluationContext) -> AchievementEvaluation {
		switch descriptor.metric {
		case .totalEntries(let target):
			return progressMetric(current: Double(context.totalEntries), target: Double(target))
		case .uniqueDays(let target):
			return progressMetric(current: Double(context.uniqueDayCount), target: Double(target))
		case .streakDays(let target):
			return progressMetric(current: Double(context.currentStreak), target: Double(target))
		case .consistency(let threshold, let minDays):
			// Require at least minDays unique days of logging before unlocking
			let hasEnoughHistory = context.uniqueDayCount >= minDays
			let meetsThreshold = context.consistencyScore >= threshold && context.consistencyScore > 0
			let unlocked = hasEnoughHistory && meetsThreshold
			// Progress accounts for both: days progress + consistency progress
			// Each requirement contributes equally to the progress bar
			let requirementWeight = 0.5
			let daysProgress = min(Double(context.uniqueDayCount) / Double(minDays), 1.0) * requirementWeight
			let consistencyProgress = min(context.consistencyScore / threshold, 1.0) * requirementWeight
			let progress = daysProgress + consistencyProgress
			return AchievementEvaluation(progress: progress, unlocked: unlocked)
		case .goalsAchieved(let target):
			return progressMetric(current: Double(context.goalsAchieved), target: Double(target))
		case .remindersEnabled:
			return AchievementEvaluation(progress: context.remindersEnabled ? 1 : 0, unlocked: context.remindersEnabled)
		case .reminderConsistency(let targetRatio):
			let progress = min(max(context.recentReminderRatio / targetRatio, 0), 1)
			return AchievementEvaluation(progress: progress, unlocked: context.recentReminderRatio >= targetRatio)
		}
	}
	
	private func progressMetric(current: Double, target: Double) -> AchievementEvaluation {
		guard target > 0 else { return AchievementEvaluation(progress: 0, unlocked: false) }
		let progress = min(current / target, 1)
		return AchievementEvaluation(progress: progress, unlocked: current >= target)
	}
}

// MARK: - Supporting Models

struct AchievementDescriptor: Identifiable {
	let key: String
	let title: LocalizedStringResource
	let detail: LocalizedStringResource
	let iconName: String
	let category: AchievementCategory
	let metric: AchievementMetric
	let isPremium: Bool
	
	var id: String { key }
	
	static let catalog: [AchievementDescriptor] = [
		AchievementDescriptor(
			key: "logging.newcomer",
			title: L10n.Achievements.loggingNewcomerTitle,
			detail: L10n.Achievements.loggingNewcomerDetail,
			iconName: "square.and.pencil",
			category: .logging,
			metric: .totalEntries(10),
			isPremium: false
		),
		AchievementDescriptor(
			key: "logging.regular",
			title: L10n.Achievements.loggingRegularTitle,
			detail: L10n.Achievements.loggingRegularDetail,
			iconName: "checkmark.circle.fill",
			category: .logging,
			metric: .totalEntries(50),
			isPremium: false
		),
		AchievementDescriptor(
			key: "logging.ledger",
			title: L10n.Achievements.loggingLedgerTitle,
			detail: L10n.Achievements.loggingLedgerDetail,
			iconName: "book.closed.fill",
			category: .logging,
			metric: .totalEntries(365),
			isPremium: true
		),
		AchievementDescriptor(
			key: "streak.week",
			title: L10n.Achievements.streakWeekTitle,
			detail: L10n.Achievements.streakWeekDetail,
			iconName: "flame.fill",
			category: .streaks,
			metric: .streakDays(7),
			isPremium: false
		),
		AchievementDescriptor(
			key: "streak.month",
			title: L10n.Achievements.streakMonthTitle,
			detail: L10n.Achievements.streakMonthDetail,
			iconName: "calendar.circle.fill",
			category: .streaks,
			metric: .streakDays(30),
			isPremium: false
		),
		AchievementDescriptor(
			key: "streak.quarter",
			title: L10n.Achievements.streakQuarterTitle,
			detail: L10n.Achievements.streakQuarterDetail,
			iconName: "sparkles",
			category: .streaks,
			metric: .streakDays(90),
			isPremium: true
		),
		AchievementDescriptor(
			key: "habits.month",
			title: L10n.Achievements.habitsMonthTitle,
			detail: L10n.Achievements.habitsMonthDetail,
			iconName: "calendar",
			category: .habits,
			metric: .uniqueDays(30),
			isPremium: false
		),
		AchievementDescriptor(
			key: "habits.season",
			title: L10n.Achievements.habitsSeasonTitle,
			detail: L10n.Achievements.habitsSeasonDetail,
			iconName: "leaf.fill",
			category: .habits,
			metric: .uniqueDays(90),
			isPremium: false
		),
		AchievementDescriptor(
			key: "habits.year",
			title: L10n.Achievements.habitsYearTitle,
			detail: L10n.Achievements.habitsYearDetail,
			iconName: "sun.max.fill",
			category: .habits,
			metric: .uniqueDays(365),
			isPremium: true
		),
		AchievementDescriptor(
			key: "consistency.solid",
			title: L10n.Achievements.consistencySolidTitle,
			detail: L10n.Achievements.consistencySolidDetail,
			iconName: "chart.bar.fill",
			category: .habits,
			metric: .consistency(threshold: 0.70, minDays: 10),
			isPremium: false
		),
		AchievementDescriptor(
			key: "consistency.excellent",
			title: L10n.Achievements.consistencyExcellentTitle,
			detail: L10n.Achievements.consistencyExcellentDetail,
			iconName: "chart.line.uptrend.xyaxis",
			category: .habits,
			metric: .consistency(threshold: 0.90, minDays: 30),
			isPremium: true
		),
		AchievementDescriptor(
			key: "goals.first",
			title: L10n.Achievements.goalFirstTitle,
			detail: L10n.Achievements.goalFirstDetail,
			iconName: "flag.checkered",
			category: .goals,
			metric: .goalsAchieved(1),
			isPremium: false
		),
		AchievementDescriptor(
			key: "goals.triple",
			title: L10n.Achievements.goalTripleTitle,
			detail: L10n.Achievements.goalTripleDetail,
			iconName: "medal.fill",
			category: .goals,
			metric: .goalsAchieved(3),
			isPremium: false
		),
		AchievementDescriptor(
			key: "goals.major",
			title: L10n.Achievements.goalMajorTitle,
			detail: L10n.Achievements.goalMajorDetail,
			iconName: "crown.fill",
			category: .goals,
			metric: .goalsAchieved(5),
			isPremium: true
		),
		AchievementDescriptor(
			key: "reminders.enabled",
			title: L10n.Achievements.remindersEnabledTitle,
			detail: L10n.Achievements.remindersEnabledDetail,
			iconName: "bell.badge.fill",
			category: .habits,
			metric: .remindersEnabled,
			isPremium: false
		),
		AchievementDescriptor(
			key: "reminders.routine",
			title: L10n.Achievements.remindersRoutineTitle,
			detail: L10n.Achievements.remindersRoutineDetail,
			iconName: "clock.badge.checkmark",
			category: .habits,
			metric: .reminderConsistency(0.85),
			isPremium: false
		)
	]

	static func descriptor(for key: String) -> AchievementDescriptor? {
		catalog.first { $0.key == key }
	}
}

struct AchievementSnapshot: Identifiable {
	let descriptor: AchievementDescriptor
	let model: Achievement
	let computedUnlocked: Bool
	let canUnlock: Bool
	
	var id: String { descriptor.key }
	
	var progressValue: Double { model.progressValue }
	var isUnlocked: Bool { model.unlockedAt != nil }
	var requiresPro: Bool { descriptor.isPremium && !canUnlock }
}

enum AchievementCategory: String, CaseIterable, Identifiable {
	case logging
	case streaks
	case habits
	case goals
	case health
	
	var id: String { rawValue }
	
	var title: LocalizedStringResource {
		switch self {
		case .logging: return L10n.Achievements.categoryLogging
		case .streaks: return L10n.Achievements.categoryStreaks
		case .habits: return L10n.Achievements.categoryHabits
		case .goals: return L10n.Achievements.categoryGoals
		case .health: return L10n.Achievements.categoryHealth
		}
	}
}

struct AchievementEvaluation {
	let progress: Double
	let unlocked: Bool
}

enum AchievementMetric {
	case totalEntries(Int)
	case uniqueDays(Int)
	case streakDays(Int)
	case consistency(threshold: Double, minDays: Int)
	case goalsAchieved(Int)
	case remindersEnabled
	case reminderConsistency(Double)
}

private struct EvaluationContext {
	let totalEntries: Int
	let uniqueDayCount: Int
	let currentStreak: Int
	let consistencyScore: Double
	let goalsAchieved: Int
	let remindersEnabled: Bool
	let recentReminderRatio: Double
	
	init(dataManager: DataManager) {
		let allEntries = dataManager.fetchAllEntries()
		let entries = allEntries.filter { !$0.isHidden }
		totalEntries = entries.count
		let uniqueDays = Set(entries.map { $0.normalizedDate })
		uniqueDayCount = uniqueDays.count
		currentStreak = EvaluationContext.calculateCurrentStreak(from: uniqueDays)
		consistencyScore = dataManager.getConsistencyScore() ?? 0
		goalsAchieved = dataManager.countAchievedGoals()
		let settings = dataManager.settings
		let reminders = dataManager.deviceSettings.reminders
		remindersEnabled = (reminders.primaryTime != nil) || (reminders.secondaryTime != nil)
		recentReminderRatio = EvaluationContext.recentReminderCompletionRatio(entries: entries)
	}
	
	private static func calculateCurrentStreak(from dates: Set<Date>) -> Int {
		guard !dates.isEmpty else { return 0 }
		let calendar = Calendar.current
		var streak = 0
		var cursor = calendar.startOfDay(for: Date())
		while dates.contains(cursor) {
			streak += 1
			guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
			cursor = previous
		}
		return streak
	}
	
	private static func recentReminderCompletionRatio(entries: [WeightEntry]) -> Double {
		let calendar = Calendar.current
		let uniqueDates = Set(entries.map { $0.normalizedDate })
		guard !uniqueDates.isEmpty else { return 0 }
		let startOfToday = calendar.startOfDay(for: Date())
		let windowDays = 21
		var loggedCount = 0
		for offset in 0..<windowDays {
			guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { continue }
			let normalized = WeightEntry.normalizeDate(day)
			if uniqueDates.contains(normalized) {
				loggedCount += 1
			}
		}
		return Double(loggedCount) / Double(windowDays)
	}

	#if DEBUG
	func makeDiagnosticsSnapshot() -> AchievementDiagnostics {
		AchievementDiagnostics(
			totalEntries: totalEntries,
			uniqueDayCount: uniqueDayCount,
			currentStreak: currentStreak,
			consistencyScore: consistencyScore,
			goalsAchieved: goalsAchieved,
			remindersEnabled: remindersEnabled,
			recentReminderRatio: recentReminderRatio,
			evaluatedAt: Date()
		)
	}
	#endif
}

struct AchievementDiagnostics {
	let totalEntries: Int
	let uniqueDayCount: Int
	let currentStreak: Int
	let consistencyScore: Double
	let goalsAchieved: Int
	let remindersEnabled: Bool
	let recentReminderRatio: Double
	let evaluatedAt: Date
}
