//
//  PlateauDetectionService.swift
//  My Weight
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import Combine

/// Service for detecting weight loss/gain plateaus
@MainActor
final class PlateauDetectionService: ObservableObject {
    
    @Published var currentPlateau: PlateauDetection?
    
    // MARK: - Plateau Detection
    
    struct PlateauDetection {
        let startDate: Date
        let duration: Int // days
        let averageWeight: Double
        let changePercentage: Double
        
        var message: String {
            String(localized: L10n.Insights.plateauMessage(duration))
        }
        
        var hint: String {
            String(localized: L10n.Insights.plateauExplanation)
        }
    }
    
    // Configuration
    private let minimumDays = 14
    private let changeThreshold = 0.005
    
    // Track dismissed plateaus
    private var dismissedPlateaus: Set<String> = []
    private let userDefaultsKey = "trimly.plateaus.dismissed"
    
    init() {
        loadDismissedPlateaus()
    }
    
    // MARK: - Detection
    
    /// Check if a plateau exists in recent data
    func detectPlateau(dataManager: DataManager) -> PlateauDetection? {
        guard let plateau = detectPlateau(dailyWeights: dataManager.getDailyWeights()),
              !isDismissed(plateau) else { return nil }
        return plateau
    }

    /// Require recent, well-supported history and low variation, not just matching endpoints.
    func detectPlateau(
        dailyWeights: [WeightInsights.DailyWeight], now: Date = Date(), calendar: Calendar = .current
    ) -> PlateauDetection? {
        guard now.timeIntervalSinceReferenceDate.isFinite else { return nil }
        let today = calendar.startOfDay(for: now)
        guard let cutoff = calendar.date(byAdding: .day, value: -20, to: today) else { return nil }
        let recent = WeightAnalytics.normalizedDailyWeights(dailyWeights, calendar: calendar)
            .filter { $0.date >= cutoff && $0.date <= today }
        let evidence = WeightInsights.support(for: recent, now: now, minimumSamples: minimumDays,
                                              minimumSpan: minimumDays, maximumAge: 3, calendar: calendar)
        guard evidence.state == .supported, let first = recent.first,
              let slope = WeightAnalytics.calculateLinearRegression(dailyWeights: recent, calendar: calendar).slope else { return nil }
        let average = recent.reduce(0.0) { $0 + $1.weight / Double(recent.count) }
        let weights = recent.map { $0.weight }
        guard average.isFinite, average > 0, let minimum = weights.min(), let maximum = weights.max() else { return nil }
        let relativeTrend = abs(slope) * Double(evidence.calendarDays - 1) / average
        let relativeRange = (maximum - minimum) / average
        guard relativeTrend.isFinite, relativeRange.isFinite,
              relativeTrend <= changeThreshold, relativeRange <= 0.02 else { return nil }
        return PlateauDetection(startDate: first.date, duration: evidence.calendarDays,
                                averageWeight: average, changePercentage: relativeTrend * 100)
    }
    
    /// Show plateau detection
    func showPlateau(_ plateau: PlateauDetection) {
        currentPlateau = plateau
    }
    
    /// Dismiss current plateau
    func dismissPlateau() {
        if let plateau = currentPlateau {
            markAsDismissed(plateau)
        }
        currentPlateau = nil
    }
    
    /// Check and update plateau status
    func checkForPlateau(dataManager: DataManager) {
        currentPlateau = detectPlateau(dataManager: dataManager)
    }
    
    // MARK: - Persistence
    
    /// Check if plateau has been dismissed
    private func isDismissed(_ plateau: PlateauDetection) -> Bool {
        return dismissedPlateaus.contains(key(for: plateau))
    }
    
    /// Mark plateau as dismissed
    private func markAsDismissed(_ plateau: PlateauDetection) {
        dismissedPlateaus.insert(key(for: plateau))
        saveDismissedPlateaus()
    }
    
    /// Reset dismissed plateaus (for testing)
    func resetDismissedPlateaus() {
        dismissedPlateaus.removeAll()
        saveDismissedPlateaus()
    }
    
    private func key(for plateau: PlateauDetection) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: plateau.startDate)
    }
    
    private func loadDismissedPlateaus() {
        if let data = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            dismissedPlateaus = Set(data)
        }
    }
    
    private func saveDismissedPlateaus() {
        UserDefaults.standard.set(Array(dismissedPlateaus), forKey: userDefaultsKey)
    }
}
