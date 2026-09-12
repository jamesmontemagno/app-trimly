//
//  WeightAnalytics.swift
//  My Weight
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
        let visibleEntries = entries.filter {
            !$0.isHidden && $0.weightKg.isFinite && $0.weightKg > 0 && $0.timestamp.timeIntervalSinceReferenceDate.isFinite
        }
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
                let average = sortedEntries.reduce(0.0) { $0 + $1.weightKg / Double(sortedEntries.count) }
                if average.isFinite { result[date] = average }
            }
        }
        
        return result
    }
    
    // MARK: - Moving Average
    
    /// Calculate simple moving average over logged samples, not elapsed calendar days.
    static func calculateMovingAverage(
        dailyWeights: [(date: Date, weight: Double)],
        period: Int
    ) -> [(date: Date, value: Double)] {
        let sorted = validSamples(dailyWeights)
        guard period > 0, sorted.count >= period else { return [] }
        var result: [(date: Date, value: Double)] = []
        
        for i in (period - 1)..<sorted.count {
            let window = sorted[(i - period + 1)...i]
            let average = window.reduce(0.0) { $0 + $1.weight / Double(period) }
            if average.isFinite { result.append((date: sorted[i].date, value: average)) }
        }
        
        return result
    }
    
    // MARK: - Exponential Moving Average (EMA)
    
    /// Calculate exponential moving average over logged samples; gaps are not filled.
    static func calculateEMA(
        dailyWeights: [(date: Date, weight: Double)],
        period: Int
    ) -> [(date: Date, value: Double)] {
        let sorted = validSamples(dailyWeights)
        guard period > 0, !sorted.isEmpty else { return [] }
        var result: [(date: Date, value: Double)] = []
        
        // Smoothing factor: 2 / (period + 1)
        let alpha = 2.0 / (Double(period) + 1)
        
        // Start with first value
        var ema = sorted[0].weight
        result.append((date: sorted[0].date, value: ema))
        
        // Calculate EMA for subsequent values
        for i in 1..<sorted.count {
            ema = (sorted[i].weight * alpha) + (ema * (1.0 - alpha))
            if ema.isFinite { result.append((date: sorted[i].date, value: ema)) }
        }
        
        return result
    }
    
    // MARK: - Consistency Score
    
    /// Calculate consistency score (percentage of days with entries)
    /// - Parameters:
    ///   - entries: Weight entries to analyze
    ///   - goalStartDate: Optional goal start date. When provided, calculates consistency from this date to today. If nil, uses all available history.
    /// - Returns: Consistency score as a percentage (0.0 to 1.0), or nil if no entries
    static func calculateConsistencyScore(
        entries: [WeightEntry],
        goalStartDate: Date? = nil
    ) -> Double? {
        let visibleEntries = entries.filter {
            !$0.isHidden && $0.weightKg.isFinite && $0.weightKg > 0 && $0.timestamp.timeIntervalSinceReferenceDate.isFinite
        }
        guard !visibleEntries.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let effectiveStart: Date
        if let goalStartDate = goalStartDate {
            guard goalStartDate.timeIntervalSinceReferenceDate.isFinite else { return nil }
            // Use goal start date (normalized to start of day)
            effectiveStart = calendar.startOfDay(for: goalStartDate)
        } else {
            // No goal - use first entry date (all available history)
            guard let firstDate = visibleEntries.map({ WeightEntry.normalizeDate($0.timestamp) }).min() else { return nil }
            effectiveStart = firstDate
        }
        
        // Count days from effective start to today
        // Note: totalDays is 0 when effectiveStart == today (first day of logging)
        let totalDays = calendar.dateComponents([.day], from: effectiveStart, to: today).day ?? 0
        guard totalDays >= 0 else { return nil }
        
        // Count unique days with entries in window
        let daysWithEntries = Set(visibleEntries.lazy
            .map { WeightEntry.normalizeDate($0.timestamp) }
            .filter { $0 >= effectiveStart && $0 <= today }
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
        stabilityThreshold: Double = 0.02, // kg per calendar day
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> TrendDirection {
        guard now.timeIntervalSinceReferenceDate.isFinite,
              stabilityThreshold.isFinite, stabilityThreshold >= 0 else { return .stable }
        let data = normalizedDailyWeights(dailyWeights, calendar: calendar).filter { $0.date <= calendar.startOfDay(for: now) }
        guard WeightInsights.support(for: data, now: now, calendar: calendar).state == .supported else { return .stable }
        
        let regression = calculateLinearRegression(dailyWeights: data, calendar: calendar)
        guard let slope = regression.slope else { return .stable }
        
        if slope == 0 || abs(slope) < stabilityThreshold {
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
    
    /// Regress on elapsed local calendar days from the first observation, including gaps.
    /// Correlation retains the existing nonnegative magnitude contract.
    static func calculateLinearRegression(
        dailyWeights: [(date: Date, weight: Double)],
        calendar: Calendar = .current
    ) -> LinearRegressionResult {
        let sorted = normalizedDailyWeights(dailyWeights, calendar: calendar)
        guard sorted.count >= 2, let first = sorted.first else {
            return LinearRegressionResult(slope: nil, intercept: nil, correlation: nil)
        }
        
        let n = Double(sorted.count)
        
        // Convert dates to day indices
        let dayIndices = sorted.map { Double(calendar.dateComponents([.day], from: first.date, to: $0.date).day ?? 0) }
        let weights = sorted.map { $0.weight }
        
        // Calculate means
        let meanX = dayIndices.reduce(0.0, +) / n
        let meanY = weights.reduce(0.0) { $0 + $1 / n }
        
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
        
        guard denominator > 0, denominator.isFinite, numerator.isFinite, ssTotal.isFinite else {
            return LinearRegressionResult(slope: nil, intercept: nil, correlation: nil)
        }
        
        let slope = numerator / denominator
        let intercept = meanY - slope * meanX
        guard slope.isFinite, intercept.isFinite else {
            return LinearRegressionResult(slope: nil, intercept: nil, correlation: nil)
        }
        
        // Calculate correlation coefficient
        for i in 0..<sorted.count {
            let predicted = slope * dayIndices[i] + intercept
            let residual = weights[i] - predicted
            ssResidual += residual * residual
        }
        
        let correlation = ssTotal > 0 && ssResidual.isFinite ? sqrt(max(0, min(1, 1 - (ssResidual / ssTotal)))) : nil
        
        return LinearRegressionResult(slope: slope, intercept: intercept, correlation: correlation)
    }
    
    // MARK: - Goal Projection
    
    /// Calculate projected date to reach goal
    static func calculateGoalProjection(
        dailyWeights: [(date: Date, weight: Double)],
        targetWeightKg: Double,
        minDays: Int = 10,
        stabilityThreshold: Double = 0.02,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        guard now.timeIntervalSinceReferenceDate.isFinite, targetWeightKg.isFinite, targetWeightKg > 0,
              stabilityThreshold.isFinite, stabilityThreshold > 0, minDays >= 2 else { return nil }
        let sorted = normalizedDailyWeights(dailyWeights, calendar: calendar).filter { $0.date <= now }
        guard WeightInsights.support(for: sorted, now: now, minimumSamples: minDays, calendar: calendar).state == .supported else { return nil }
        
        // Exclude the last two calendar days, not the last two samples, after a large jump.
        var workingData = sorted
        if let latest = sorted.last,
           let cutoff = calendar.date(byAdding: .day, value: -2, to: latest.date),
           let baseline = sorted.last(where: { $0.date <= cutoff }) {
            let volatility = abs(latest.weight - baseline.weight) / baseline.weight
            if volatility > 0.05 { // 5% threshold
                workingData = sorted.filter { $0.date <= cutoff }
            }
        }
        
        guard WeightInsights.support(for: workingData, now: now, minimumSamples: minDays, calendar: calendar).state == .supported else { return nil }
        
        // Calculate regression
        let regression = calculateLinearRegression(dailyWeights: workingData, calendar: calendar)
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
            return now // Already at goal
        }
        
        // Calculate days to goal
        let daysToGoal = weightDifference / slope
        
        guard daysToGoal.isFinite, daysToGoal > 0, daysToGoal < 3650 else { // Max 10 years
            return nil
        }
        
        // Project date
        guard let lastDate = workingData.last?.date,
              let projectedDate = calendar.date(byAdding: .day, value: Int(ceil(daysToGoal)), to: lastDate),
              projectedDate >= calendar.startOfDay(for: now) else {
            return nil
        }
        
        return projectedDate
    }

    static func validSamples(_ data: [(date: Date, weight: Double)]) -> [(date: Date, weight: Double)] {
        data.filter { $0.weight.isFinite && $0.weight > 0 && $0.date.timeIntervalSinceReferenceDate.isFinite }
            .sorted { $0.date < $1.date }
    }

    /// Defensively normalize callers' daily data so duplicate days do not overweight analytics.
    static func normalizedDailyWeights(
        _ data: [(date: Date, weight: Double)],
        calendar: Calendar = .current
    ) -> [(date: Date, weight: Double)] {
        let grouped = Dictionary(grouping: validSamples(data)) { calendar.startOfDay(for: $0.date) }
        return grouped.compactMap { date, values in
            let mean = values.reduce(0.0) { $0 + $1.weight / Double(values.count) }
            return mean.isFinite ? (date: date, weight: mean) : nil
        }.sorted { $0.date < $1.date }
    }
}
