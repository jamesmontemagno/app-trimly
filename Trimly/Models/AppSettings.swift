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
    var preferredUnit: WeightUnit = WeightUnit.pounds
    
    /// Daily aggregation mode (latest vs average)
    var dailyAggregationMode: DailyAggregationMode = DailyAggregationMode.latest
    
    /// Chart display mode
    var chartMode: ChartMode = ChartMode.minimalist
    
    /// Whether to show moving average on charts
    var showMovingAverage: Bool = true
    
    /// Whether to show EMA on charts
    var showEMA: Bool = true
    
    /// Moving average period (days)
    var movingAveragePeriod: Int = 7
    
    /// EMA period (days)
    var emaPeriod: Int = 7

    /// Preferred app appearance
    var appearance: AppAppearance = AppAppearance.system
    
    /// Whether user has completed onboarding
    var hasCompletedOnboarding: Bool = false
    
    /// EULA acceptance date
    var eulaAcceptedDate: Date?
    
    /// Weight decimal precision (1 or 2 decimal places)
    var decimalPrecision: Int = 1
    
    /// Projection method
    var projectionMethod: ProjectionMethod = ProjectionMethod.linear
    
    /// Minimum days required for projection
    var minDaysForProjection: Int = 10
    
    /// Last time settings were updated
    var updatedAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        preferredUnit: WeightUnit = .pounds,
        dailyAggregationMode: DailyAggregationMode = .latest,
        chartMode: ChartMode = .minimalist,
        showMovingAverage: Bool = true,
        showEMA: Bool = true,
        movingAveragePeriod: Int = 7,
        emaPeriod: Int = 7,
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
        self.chartMode = chartMode
        self.showMovingAverage = showMovingAverage
        self.showEMA = showEMA
        self.movingAveragePeriod = movingAveragePeriod
        self.emaPeriod = emaPeriod
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
