//
//  AppSettings.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import SwiftData
import SwiftUI

/// Application settings and preferences
@Model
final class AppSettings {
    /// Unique identifier (singleton)
    var id: UUID = UUID()
    
    /// Preferred weight unit
    var preferredUnit: WeightUnit = .pounds
    
    /// Daily aggregation mode (latest vs average)
    var dailyAggregationMode: DailyAggregationMode = .latest
    
    /// Reminder time (nil if disabled)
    var reminderTime: Date?
    
    /// Optional second reminder time
    var secondReminderTime: Date?
    
    /// Whether adaptive reminder suggestions are enabled
    var adaptiveRemindersEnabled: Bool = true
    
    /// Count of consecutive reminder dismissals
    var consecutiveReminderDismissals: Int = 0
    
    /// Chart display mode
    var chartMode: ChartMode = .minimalist
    
    /// Whether to show moving average on charts
    var showMovingAverage: Bool = true
    
    /// Whether to show EMA on charts
    var showEMA: Bool = true
    
    /// Moving average period (days)
    var movingAveragePeriod: Int = 7
    
    /// EMA period (days)
    var emaPeriod: Int = 7
    
    /// HealthKit integration enabled
    var healthKitEnabled: Bool = false
    
    /// Auto-hide HealthKit duplicates
    var autoHideHealthKitDuplicates: Bool = true
    
    /// HealthKit duplicate tolerance in kg
    var healthKitDuplicateToleranceKg: Double = 0.1
    
    /// Consistency score window (days)
    var consistencyScoreWindow: Int = 30

    /// Preferred app appearance
    var appearance: AppAppearance = .system
    
    /// Whether user has completed onboarding
    var hasCompletedOnboarding: Bool = false
    
    /// EULA acceptance date
    var eulaAcceptedDate: Date?
    
    /// Weight decimal precision (1 or 2 decimal places)
    var decimalPrecision: Int = 1
    
    /// Projection method
    var projectionMethod: ProjectionMethod = .linear
    
    /// Minimum days required for projection
    var minDaysForProjection: Int = 10
    
    /// Last time settings were updated
    var updatedAt: Date = Date()
    
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
        case .system: return String(localized: L10n.Settings.themeSystem)
        case .light: return String(localized: L10n.Settings.themeLight)
        case .dark: return String(localized: L10n.Settings.themeDark)
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
