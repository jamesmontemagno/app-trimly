//
//  CelebrationService.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import Combine

/// Service for detecting and managing micro celebrations
@MainActor
final class CelebrationService: ObservableObject {
    
    @Published var currentCelebration: Celebration?
    
    // MARK: - Celebration Types
    
    enum CelebrationType {
        case firstWeekStreak
        case thirtyDayStreak
        case tenEntries
        case twentyFiveEntries
        case fiftyEntries
        case hundredEntries
        case goal25Percent
        case goal50Percent
        case goal75Percent
        case goal100Percent
        case consistency70
        case consistency85
        case achievement
        
        var persistenceKey: String {
            switch self {
            case .firstWeekStreak: return "firstWeekStreak"
            case .thirtyDayStreak: return "thirtyDayStreak"
            case .tenEntries: return "tenEntries"
            case .twentyFiveEntries: return "twentyFiveEntries"
            case .fiftyEntries: return "fiftyEntries"
            case .hundredEntries: return "hundredEntries"
            case .goal25Percent: return "goal25Percent"
            case .goal50Percent: return "goal50Percent"
            case .goal75Percent: return "goal75Percent"
            case .goal100Percent: return "goal100Percent"
            case .consistency70: return "consistency70"
            case .consistency85: return "consistency85"
            case .achievement: return "achievement"
            }
        }
        
        var message: String {
            switch self {
            case .firstWeekStreak:
                return String(localized: L10n.Celebrations.streak7)
            case .thirtyDayStreak:
                return String(localized: L10n.Celebrations.streak30)
            case .tenEntries:
                return String(localized: L10n.Celebrations.entries10)
            case .twentyFiveEntries:
                return String(localized: L10n.Celebrations.entries25)
            case .fiftyEntries:
                return String(localized: L10n.Celebrations.entries50)
            case .hundredEntries:
                return String(localized: L10n.Celebrations.entries100)
            case .goal25Percent:
                return String(localized: L10n.Celebrations.goal25)
            case .goal50Percent:
                return String(localized: L10n.Celebrations.goal50)
            case .goal75Percent:
                return String(localized: L10n.Celebrations.goal75)
            case .goal100Percent:
                return String(localized: L10n.Celebrations.goal100)
            case .consistency70:
                return String(localized: L10n.Celebrations.consistency70)
            case .consistency85:
                return String(localized: L10n.Celebrations.consistency85)
            case .achievement:
                return String(localized: L10n.Achievements.navigationTitle)
            }
        }
        
        var iconName: String {
            switch self {
            case .firstWeekStreak:
                return "flame.fill"
            case .thirtyDayStreak:
                return "calendar.circle.fill"
            case .tenEntries, .twentyFiveEntries, .fiftyEntries, .hundredEntries:
                return "checkmark.circle.fill"
            case .goal25Percent, .goal50Percent, .goal75Percent:
                return "chart.line.uptrend.xyaxis"
            case .goal100Percent:
                return "star.fill"
            case .consistency70, .consistency85:
                return "calendar.badge.checkmark"
            case .achievement:
                return "rosette"
            }
        }
    }
    
    struct Celebration: Identifiable {
        let id = UUID()
        let type: CelebrationType
        let timestamp: Date
        let customMessage: String?
        let customIconName: String?
		
        var message: String { customMessage ?? type.message }
        var iconName: String { customIconName ?? type.iconName }
    }
    
    // Track which celebrations have been shown
    private var shownCelebrations: Set<String> = []
    private let userDefaultsKey = "trimly.celebrations.shown"
    
    init() {
        loadShownCelebrations()
    }
    
    // MARK: - Check for Celebrations
    
    /// Check if any celebrations should be triggered
    func checkForCelebrations(dataManager: DataManager) -> Celebration? {
        // Don't interrupt current celebration
        if currentCelebration != nil { return nil }
        
        if let celebration = checkAchievementCelebration(dataManager: dataManager) {
            return celebration
        }

        let entries = dataManager.fetchAllEntries()
        guard entries.count >= 2 else { return nil }
        
        // Check in order of importance
        if let celebration = checkGoalCelebration(dataManager: dataManager) {
            return celebration
        }
        
        if let celebration = checkConsistencyCelebration(dataManager: dataManager) {
            return celebration
        }
        
        if let celebration = checkStreakCelebration(entries: entries) {
            return celebration
        }
        
        if let celebration = checkEntriesMilestone(entries: entries) {
            return celebration
        }
        
        return nil
    }
    
    // MARK: - Specific Celebration Checks
    
    /// Check for newly unlocked achievements persisted in SwiftData
    private func checkAchievementCelebration(dataManager: DataManager) -> Celebration? {
        let pending = dataManager.fetchUncelebratedAchievements()
        guard let achievement = pending.first else { return nil }
        guard let descriptor = AchievementDescriptor.descriptor(for: achievement.key) else {
            dataManager.markAchievementCelebrated(achievement.key)
            return nil
        }
        let title = String(localized: descriptor.title)
        let message = String(localized: L10n.Achievements.celebrationUnlocked(title))
        let celebration = createCelebration(
            type: .achievement,
            customMessage: message,
            iconOverride: descriptor.iconName
        )
        dataManager.markAchievementCelebrated(achievement.key)
        return celebration
    }

    /// Check for goal progress celebrations
    private func checkGoalCelebration(dataManager: DataManager) -> Celebration? {
        guard let goal = dataManager.fetchActiveGoal(),
              let currentWeight = dataManager.getCurrentWeight(),
              let startWeight = goal.startingWeightKg ?? dataManager.getStartWeight() else {
            return nil
        }
        
        let totalChange = goal.targetWeightKg - startWeight
        let currentChange = currentWeight - startWeight
        
        guard totalChange != 0 else { return nil }
        
        let progress = abs(currentChange / totalChange)
        
        // Check milestones
        let milestones: [(threshold: Double, type: CelebrationType)] = [
            (0.25, .goal25Percent),
            (0.50, .goal50Percent),
            (0.75, .goal75Percent),
            (1.00, .goal100Percent)
        ]
        
        for milestone in milestones {
            if progress >= milestone.threshold && !hasShown(milestone.type) {
                return createCelebration(type: milestone.type)
            }
        }
        
        return nil
    }
    
    /// Check for consistency score celebrations
    private func checkConsistencyCelebration(dataManager: DataManager) -> Celebration? {
        guard let score = dataManager.getConsistencyScore() else {
            return nil
        }
        
        let milestones: [(threshold: Double, type: CelebrationType)] = [
            (0.85, .consistency85),
            (0.70, .consistency70)
        ]
        
        let sortedMilestones = milestones.sorted { $0.threshold > $1.threshold }
        for milestone in sortedMilestones {
            if score >= milestone.threshold && !hasShown(milestone.type) {
                let percentage = Int(score * 100)
                let customMessage = formattedConsistencyMessage(percentage: percentage)
                let celebration = createCelebration(type: milestone.type, customMessage: customMessage)
                sortedMilestones
                    .filter { $0.threshold < milestone.threshold }
                    .forEach { markAsShown($0.type) }
                return celebration
            }
        }
        
        return nil
    }

    private func formattedConsistencyMessage(percentage: Int) -> String {
        let template = String(localized: L10n.Celebrations.consistencyPercentTemplate)
        return String(format: template, locale: Locale.current, percentage)
    }
    
    /// Check for streak celebrations
    private func checkStreakCelebration(entries: [WeightEntry]) -> Celebration? {
        let sortedDays = Array(Set(entries.map { $0.normalizedDate })).sorted()
        guard !sortedDays.isEmpty else { return nil }
		
        let milestones: [(length: Int, type: CelebrationType)] = [
            (30, .thirtyDayStreak),
            (7, .firstWeekStreak)
        ]
		
        for milestone in milestones {
            if hasConsecutiveDays(sortedDays, count: milestone.length) && !hasShown(milestone.type) {
                if milestone.type == .thirtyDayStreak && !hasShown(.firstWeekStreak) {
                    markAsShown(.firstWeekStreak)
                }
                return createCelebration(type: milestone.type)
            }
        }
		
        return nil
    }
	
    /// Determine whether the dataset contains the requested number of consecutive days
    private func hasConsecutiveDays(_ dates: [Date], count: Int) -> Bool {
        guard dates.count >= count else { return false }
		
        let calendar = Calendar.current
        var streak = 1
		
        for index in 1..<dates.count {
            let previous = dates[index - 1]
            let current = dates[index]
            let dayDifference = calendar.dateComponents([.day], from: previous, to: current).day ?? 0
			
            if dayDifference == 1 {
                streak += 1
                if streak >= count {
                    return true
                }
            } else if dayDifference > 1 {
                streak = 1
            }
        }
		
        return false
    }
    
    /// Check for entry count milestones
    private func checkEntriesMilestone(entries: [WeightEntry]) -> Celebration? {
        let totalEntries = entries.count
        let milestones: [(count: Int, type: CelebrationType)] = [
            (100, .hundredEntries),
            (50, .fiftyEntries),
            (25, .twentyFiveEntries),
            (10, .tenEntries)
        ]
		
        for milestone in milestones {
            if totalEntries >= milestone.count && !hasShown(milestone.type) {
                let celebration = createCelebration(type: milestone.type)
                milestones
                    .filter { $0.count < milestone.count }
                    .forEach { markAsShown($0.type) }
                return celebration
            }
        }
		
        return nil
    }
    
    // MARK: - Celebration Management
    
    /// Create and track a celebration
    private func createCelebration(type: CelebrationType, customMessage: String? = nil, iconOverride: String? = nil) -> Celebration {
        let celebration = Celebration(type: type, timestamp: Date(), customMessage: customMessage, customIconName: iconOverride)
        markAsShown(type)
        return celebration
    }
    
    /// Show a celebration
    func showCelebration(_ celebration: Celebration) {
        currentCelebration = celebration
        
        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if currentCelebration?.id == celebration.id {
                currentCelebration = nil
            }
        }
    }
    
    /// Dismiss current celebration
    func dismissCelebration() {
        currentCelebration = nil
    }
    
    // MARK: - Persistence
    
    /// Check if a celebration has been shown
    private func hasShown(_ type: CelebrationType) -> Bool {
        return shownCelebrations.contains(key(for: type))
    }
    
    /// Mark celebration as shown
    private func markAsShown(_ type: CelebrationType) {
        shownCelebrations.insert(key(for: type))
        saveShownCelebrations()
    }
    
    /// Reset all shown celebrations (for testing)
    func resetCelebrations() {
        shownCelebrations.removeAll()
        saveShownCelebrations()
    }
    
    private func key(for type: CelebrationType) -> String {
        type.persistenceKey
    }
    
    private func loadShownCelebrations() {
        if let data = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            shownCelebrations = Set(data)
        }
    }
    
    private func saveShownCelebrations() {
        UserDefaults.standard.set(Array(shownCelebrations), forKey: userDefaultsKey)
    }
}
