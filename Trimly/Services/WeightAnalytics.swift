//
//  WeightAnalytics.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import Foundation

/// Service for calculating weight analytics, trends, and projections
final class WeightAnalytics {
    
    // MARK: - Daily Aggregation
    
    /// Aggregate entries by day using specified mode
    static func aggregateByDay(
        entries: [WeightEntry],
        mode: DailyAggregationMode
    ) -> [Date: Double] {
        let visibleEntries = entries.filter { !$0.isHidden }
        // Use dynamic normalization to handle timezone changes correctly
        let groupedByDay = Dictionary(grouping: visibleEntries) { WeightEntry.normalizeDate($0.timestamp) }
        
        var result: [Date: Double] = [:]
        
        for (date, dayEntries) in groupedByDay {
            let sortedEntries = dayEntries.sorted { $0.timestamp < $1.timestamp }
            
            switch mode {
            case .latest:
                if let latest = sortedEntries.last {
                    result[date] = latest.weightKg
                }
            case .average:
                let sum = sortedEntries.reduce(0.0) { $0 + $1.weightKg }
                result[date] = sum / Double(sortedEntries.count)
            }
        }
        
        return result
    }
    
    // MARK: - Moving Average
    
    /// Calculate simple moving average
    static func calculateMovingAverage(
        dailyWeights: [(date: Date, weight: Double)],
        period: Int
    ) -> [(date: Date, value: Double)] {
        guard period > 0, dailyWeights.count >= period else { return [] }
        
        let sorted = dailyWeights.sorted { $0.date < $1.date }
        var result: [(date: Date, value: Double)] = []
        
        for i in (period - 1)..<sorted.count {
            let window = sorted[(i - period + 1)...i]
            let average = window.reduce(0.0) { $0 + $1.weight } / Double(period)
            result.append((date: sorted[i].date, value: average))
        }
        
        return result
    }
    
    // MARK: - Exponential Moving Average (EMA)
    
    /// Calculate exponential moving average
    static func calculateEMA(
        dailyWeights: [(date: Date, weight: Double)],
        period: Int
    ) -> [(date: Date, value: Double)] {
        guard period > 0, dailyWeights.count > 0 else { return [] }
        
        let sorted = dailyWeights.sorted { $0.date < $1.date }
        var result: [(date: Date, value: Double)] = []
        
        // Smoothing factor: 2 / (period + 1)
        let alpha = 2.0 / Double(period + 1)
        
        // Start with first value
        var ema = sorted[0].weight
        result.append((date: sorted[0].date, value: ema))
        
        // Calculate EMA for subsequent values
        for i in 1..<sorted.count {
            ema = (sorted[i].weight * alpha) + (ema * (1.0 - alpha))
            result.append((date: sorted[i].date, value: ema))
        }
        
        return result
    }
    
    // MARK: - Consistency Score
    
    /// Calculate consistency score (percentage of days with entries)
    /// - Parameters:
    ///   - entries: Weight entries to analyze
    ///   - windowDays: Rolling window in days (ignored if goalStartDate is provided)
    ///   - goalStartDate: Optional goal start date. When provided, calculates consistency from this date to today
    /// - Returns: Consistency score as a percentage (0.0 to 1.0), or nil if no entries
    static func calculateConsistencyScore(
        entries: [WeightEntry],
        windowDays: Int,
        goalStartDate: Date? = nil
    ) -> Double? {
        let visibleEntries = entries.filter { !$0.isHidden }
        guard !visibleEntries.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let effectiveStart: Date
        if let goalStartDate = goalStartDate {
            // Use goal start date (normalized to start of day)
            effectiveStart = calendar.startOfDay(for: goalStartDate)
        } else {
            // Find first entry date
            let sortedEntries = visibleEntries.sorted { $0.normalizedDate < $1.normalizedDate }
            guard let firstDate = sortedEntries.first?.normalizedDate else { return nil }
            
            // Calculate window start (most recent N days)
            guard let windowStart = calendar.date(byAdding: .day, value: -windowDays + 1, to: today) else {
                return nil
            }
            
            // Use the later of first entry date or window start
            effectiveStart = max(firstDate, windowStart)
        }
        
        // Count days from effective start to today
        // Note: totalDays is 0 when effectiveStart == today (first day of logging)
        let totalDays = calendar.dateComponents([.day], from: effectiveStart, to: today).day ?? 0
        guard totalDays >= 0 else { return nil }
        
        // Count unique days with entries in window
        let daysWithEntries = Set(visibleEntries.lazy
            .filter { $0.normalizedDate >= effectiveStart && $0.normalizedDate <= today }
            .map { $0.normalizedDate }
        ).count
        
        // Denominator is number of calendar days between effectiveStart and today, inclusive
        // This means a brand-new user who has logged every available day still sees 100%.
        return Double(daysWithEntries) / Double(totalDays + 1) // +1 to include today
    }
    
    // MARK: - Trend Analysis
    
    /// Trend direction classification
    enum TrendDirection {
        case downward
        case upward
        case stable
        
        var description: String {
            switch self {
            case .downward: return String(localized: L10n.Analytics.trendDecrease)
            case .upward: return String(localized: L10n.Analytics.trendIncrease)
            case .stable: return String(localized: L10n.Analytics.trendStable)
            }
        }
    }
    
    /// Classify trend based on slope
    static func classifyTrend(
        dailyWeights: [(date: Date, weight: Double)],
        stabilityThreshold: Double = 0.02 // kg per day
    ) -> TrendDirection {
        guard dailyWeights.count >= 7 else { return .stable }
        
        let regression = calculateLinearRegression(dailyWeights: dailyWeights)
        guard let slope = regression.slope else { return .stable }
        
        if abs(slope) < stabilityThreshold {
            return .stable
        } else if slope < 0 {
            return .downward
        } else {
            return .upward
        }
    }
    
    // MARK: - Linear Regression
    
    /// Linear regression result
    struct LinearRegressionResult {
        let slope: Double?
        let intercept: Double?
        let correlation: Double?
    }
    
    /// Calculate linear regression on daily weights
    static func calculateLinearRegression(
        dailyWeights: [(date: Date, weight: Double)]
    ) -> LinearRegressionResult {
        guard dailyWeights.count >= 2 else {
            return LinearRegressionResult(slope: nil, intercept: nil, correlation: nil)
        }
        
        let sorted = dailyWeights.sorted { $0.date < $1.date }
        let n = Double(sorted.count)
        
        // Convert dates to day indices
        let dayIndices = (0..<sorted.count).map { Double($0) }
        let weights = sorted.map { $0.weight }
        
        // Calculate means
        let meanX = dayIndices.reduce(0.0, +) / n
        let meanY = weights.reduce(0.0, +) / n
        
        // Calculate slope and intercept
        var numerator = 0.0
        var denominator = 0.0
        var ssTotal = 0.0
        var ssResidual = 0.0
        
        for i in 0..<sorted.count {
            let dx = dayIndices[i] - meanX
            let dy = weights[i] - meanY
            numerator += dx * dy
            denominator += dx * dx
            ssTotal += dy * dy
        }
        
        guard denominator != 0 else {
            return LinearRegressionResult(slope: nil, intercept: nil, correlation: nil)
        }
        
        let slope = numerator / denominator
        let intercept = meanY - slope * meanX
        
        // Calculate correlation coefficient
        for i in 0..<sorted.count {
            let predicted = slope * dayIndices[i] + intercept
            let residual = weights[i] - predicted
            ssResidual += residual * residual
        }
        
        let correlation = ssTotal > 0 ? sqrt(1 - (ssResidual / ssTotal)) : nil
        
        return LinearRegressionResult(slope: slope, intercept: intercept, correlation: correlation)
    }
    
    // MARK: - Goal Projection
    
    /// Calculate projected date to reach goal
    static func calculateGoalProjection(
        dailyWeights: [(date: Date, weight: Double)],
        targetWeightKg: Double,
        minDays: Int = 10,
        stabilityThreshold: Double = 0.02
    ) -> Date? {
        guard dailyWeights.count >= minDays else { return nil }
        
        let sorted = dailyWeights.sorted { $0.date < $1.date }
        
        // Check if we need to exclude last 2 days due to volatility
        var workingData = sorted
        if sorted.count >= 3 {
            let lastWeight = sorted[sorted.count - 1].weight
            let thirdLastWeight = sorted[sorted.count - 3].weight
            let volatility = abs(lastWeight - thirdLastWeight) / thirdLastWeight
            
            if volatility > 0.05 { // 5% threshold
                workingData = Array(sorted.dropLast(2))
            }
        }
        
        guard workingData.count >= minDays else { return nil }
        
        // Calculate regression
        let regression = calculateLinearRegression(dailyWeights: workingData)
        guard let slope = regression.slope,
              let _ = regression.intercept,
              abs(slope) >= stabilityThreshold else {
            return nil
        }
        
        // Current weight (most recent)
        guard let currentWeight = workingData.last?.weight else { return nil }
        
        // Check if slope direction matches goal direction
        let weightDifference = targetWeightKg - currentWeight
        if (weightDifference > 0 && slope < 0) || (weightDifference < 0 && slope > 0) {
            // Moving away from goal
            return nil
        }
        
        // Check if we're close enough to goal
        if abs(weightDifference) < 0.5 { // Within 0.5 kg
            return Date() // Already at goal
        }
        
        // Calculate days to goal
        let daysToGoal = weightDifference / slope
        
        guard daysToGoal > 0, daysToGoal < 3650 else { // Max 10 years
            return nil
        }
        
        // Project date
        let calendar = Calendar.current
        guard let lastDate = workingData.last?.date,
              let projectedDate = calendar.date(byAdding: .day, value: Int(daysToGoal), to: lastDate) else {
            return nil
        }
        
        return projectedDate
    }
}
