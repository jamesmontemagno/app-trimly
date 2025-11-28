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
        case tenEntries
        case goal25Percent
        case goal50Percent
        case goal75Percent
        case goal100Percent
        case consistency70
        case consistency85
        
        var message: String {
            switch self {
            case .firstWeekStreak:
                return "Nice streak forming—7 days of consistency!"
            case .tenEntries:
                return "Great progress—10 entries logged!"
            case .goal25Percent:
                return "Quarter way there—steady progress!"
            case .goal50Percent:
                return "Halfway to your goal—keep it up!"
            case .goal75Percent:
                return "Three quarters there—you're doing great!"
            case .goal100Percent:
                return "Goal achieved—congratulations!"
            case .consistency70:
                return "70% consistency—building a solid habit!"
            case .consistency85:
                return "85% consistency—excellent dedication!"
            }
        }
        
        var iconName: String {
            switch self {
            case .firstWeekStreak:
                return "flame.fill"
            case .tenEntries:
                return "checkmark.circle.fill"
            case .goal25Percent, .goal50Percent, .goal75Percent:
                return "chart.line.uptrend.xyaxis"
            case .goal100Percent:
                return "star.fill"
            case .consistency70, .consistency85:
                return "calendar.badge.checkmark"
            }
        }
    }
    
    struct Celebration: Identifiable {
        let id = UUID()
        let type: CelebrationType
        let timestamp: Date
        
        var message: String { type.message }
        var iconName: String { type.iconName }
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
        let entries = dataManager.fetchAllEntries()
        guard !entries.isEmpty else { return nil }
        
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
        
        for milestone in milestones {
            if score >= milestone.threshold && !hasShown(milestone.type) {
                return createCelebration(type: milestone.type)
            }
        }
        
        return nil
    }
    
    /// Check for streak celebrations
    private func checkStreakCelebration(entries: [WeightEntry]) -> Celebration? {
        let uniqueDays = Set(entries.map { $0.normalizedDate })
        
        // Check for 7-day streak
        if uniqueDays.count >= 7 && !hasShown(.firstWeekStreak) {
            // Verify it's actually consecutive days
            let sortedDays = uniqueDays.sorted()
            if isConsecutiveDays(sortedDays, count: 7) {
                return createCelebration(type: .firstWeekStreak)
            }
        }
        
        return nil
    }
    
    /// Check if days are consecutive
    private func isConsecutiveDays(_ dates: [Date], count: Int) -> Bool {
        guard dates.count >= count else { return false }
        
        let calendar = Calendar.current
        let recentDates = dates.suffix(count)
        
        for i in 0..<(recentDates.count - 1) {
            let date1 = Array(recentDates)[i]
            let date2 = Array(recentDates)[i + 1]
            
            let daysDiff = calendar.dateComponents([.day], from: date1, to: date2).day ?? 0
            if daysDiff != 1 {
                return false
            }
        }
        
        return true
    }
    
    /// Check for entry count milestones
    private func checkEntriesMilestone(entries: [WeightEntry]) -> Celebration? {
        if entries.count >= 10 && !hasShown(.tenEntries) {
            return createCelebration(type: .tenEntries)
        }
        
        return nil
    }
    
    // MARK: - Celebration Management
    
    /// Create and track a celebration
    private func createCelebration(type: CelebrationType) -> Celebration {
        let celebration = Celebration(type: type, timestamp: Date())
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
        String(describing: type)
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
