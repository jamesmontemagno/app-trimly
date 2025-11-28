//
//  PlateauDetectionService.swift
//  TrimTally
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
            String(localized: L10n.Plateau.message(duration))
        }
        
        var hint: String {
            if changePercentage < 0.5 {
                return String(localized: L10n.Plateau.hintStable)
            } else {
                return String(localized: L10n.Plateau.hintFluctuation)
            }
        }
    }
    
    // Configuration
    private let minimumDays = 14 // Minimum days to consider a plateau
    private let changeThreshold = 0.005 // 0.5% change threshold
    
    // Track dismissed plateaus
    private var dismissedPlateaus: Set<String> = []
    private let userDefaultsKey = "trimly.plateaus.dismissed"
    
    init() {
        loadDismissedPlateaus()
    }
    
    // MARK: - Detection
    
    /// Check if a plateau exists in recent data
    func detectPlateau(dataManager: DataManager) -> PlateauDetection? {
        let dailyWeights = dataManager.getDailyWeights()
        guard dailyWeights.count >= minimumDays else { return nil }
        
        // Check last N days for stability
        let recentWeights = dailyWeights.suffix(minimumDays)
        
        guard let firstWeight = recentWeights.first?.weight,
              let lastWeight = recentWeights.last?.weight else {
            return nil
        }
        
        // Calculate average weight
        let averageWeight = recentWeights.reduce(0.0) { $0 + $1.weight } / Double(recentWeights.count)
        
        // Calculate total change percentage
        let changePercentage = abs((lastWeight - firstWeight) / firstWeight) * 100
        
        // Check if within threshold
        if changePercentage <= changeThreshold * 100 {
            let plateau = PlateauDetection(
                startDate: recentWeights.first!.date,
                duration: minimumDays,
                averageWeight: averageWeight,
                changePercentage: changePercentage
            )
            
            // Check if this plateau has been dismissed
            if !isDismissed(plateau) {
                return plateau
            }
        }
        
        return nil
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
        if currentPlateau == nil {
            if let plateau = detectPlateau(dataManager: dataManager) {
                showPlateau(plateau)
            }
        }
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
