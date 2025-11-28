//
//  AppSettings.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import SwiftData

/// Application settings and preferences
@Model
final class AppSettings {
    /// Unique identifier (singleton)
    var id: UUID
    
    /// Preferred weight unit
    var preferredUnit: WeightUnit
    
    /// Daily aggregation mode (latest vs average)
    var dailyAggregationMode: DailyAggregationMode
    
    /// Reminder time (nil if disabled)
    var reminderTime: Date?
    
    /// Optional second reminder time
    var secondReminderTime: Date?
    
    /// Whether adaptive reminder suggestions are enabled
    var adaptiveRemindersEnabled: Bool
    
    /// Count of consecutive reminder dismissals
    var consecutiveReminderDismissals: Int
    
    /// Chart display mode
    var chartMode: ChartMode
    
    /// Whether to show moving average on charts
    var showMovingAverage: Bool
    
    /// Whether to show EMA on charts
    var showEMA: Bool
    
    /// Moving average period (days)
    var movingAveragePeriod: Int
    
    /// EMA period (days)
    var emaPeriod: Int
    
    /// HealthKit integration enabled
    var healthKitEnabled: Bool
    
    /// Auto-hide HealthKit duplicates
    var autoHideHealthKitDuplicates: Bool
    
    /// HealthKit duplicate tolerance in kg
    var healthKitDuplicateToleranceKg: Double
    
    /// Consistency score window (days)
    var consistencyScoreWindow: Int

    /// Preferred app appearance
    var appearance: AppAppearance
    
    /// Whether user has completed onboarding
    var hasCompletedOnboarding: Bool
    
    /// EULA acceptance date
    var eulaAcceptedDate: Date?
    
    /// Weight decimal precision (1 or 2 decimal places)
    var decimalPrecision: Int
    
    /// Projection method
    var projectionMethod: ProjectionMethod
    
    /// Minimum days required for projection
    var minDaysForProjection: Int
    
    /// Last time settings were updated
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        preferredUnit: WeightUnit = .pounds,
        dailyAggregationMode: DailyAggregationMode = .latest,
        reminderTime: Date? = nil,
        secondReminderTime: Date? = nil,
        adaptiveRemindersEnabled: Bool = true,
        consecutiveReminderDismissals: Int = 0,
        chartMode: ChartMode = .minimalist,
        showMovingAverage: Bool = true,
        showEMA: Bool = true,
        movingAveragePeriod: Int = 7,
        emaPeriod: Int = 7,
        healthKitEnabled: Bool = false,
        autoHideHealthKitDuplicates: Bool = true,
        healthKitDuplicateToleranceKg: Double = 0.1,
        consistencyScoreWindow: Int = 30,
        appearance: AppAppearance = .system,
        hasCompletedOnboarding: Bool = false,
        eulaAcceptedDate: Date? = nil,
        decimalPrecision: Int = 1,
        projectionMethod: ProjectionMethod = .linear,
        minDaysForProjection: Int = 10,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.preferredUnit = preferredUnit
        self.dailyAggregationMode = dailyAggregationMode
        self.reminderTime = reminderTime
        self.secondReminderTime = secondReminderTime
        self.adaptiveRemindersEnabled = adaptiveRemindersEnabled
        self.consecutiveReminderDismissals = consecutiveReminderDismissals
        self.chartMode = chartMode
        self.showMovingAverage = showMovingAverage
        self.showEMA = showEMA
        self.movingAveragePeriod = movingAveragePeriod
        self.emaPeriod = emaPeriod
        self.healthKitEnabled = healthKitEnabled
        self.autoHideHealthKitDuplicates = autoHideHealthKitDuplicates
        self.healthKitDuplicateToleranceKg = healthKitDuplicateToleranceKg
        self.consistencyScoreWindow = consistencyScoreWindow
        self.appearance = appearance
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.eulaAcceptedDate = eulaAcceptedDate
        self.decimalPrecision = decimalPrecision
        self.projectionMethod = projectionMethod
        self.minDaysForProjection = minDaysForProjection
        self.updatedAt = updatedAt
    }
}

/// App-wide appearance preference
enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// Daily aggregation mode for multiple entries per day
enum DailyAggregationMode: String, Codable {
    case latest = "latest"
    case average = "average"
}

/// Chart display mode
enum ChartMode: String, Codable {
    case minimalist = "minimalist"
    case analytical = "analytical"
}

/// Projection calculation method
enum ProjectionMethod: String, Codable {
    case linear = "linear"
    case exponential = "exponential"
    case weighted = "weighted"
}
