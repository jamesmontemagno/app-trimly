//
//  WeightAnalyticsTests.swift
//  TrimlyTests
//
//  Created by Trimly on 11/19/2025.
//

import XCTest
@testable import Trimly

final class WeightAnalyticsTests: XCTestCase {
    
    // MARK: - Moving Average Tests
    
    func testMovingAverageCalculation() {
        let dailyWeights = [
            (date: date(2024, 1, 1), weight: 80.0),
            (date: date(2024, 1, 2), weight: 79.8),
            (date: date(2024, 1, 3), weight: 79.5),
            (date: date(2024, 1, 4), weight: 79.3),
            (date: date(2024, 1, 5), weight: 79.0)
        ]
        
        let ma = WeightAnalytics.calculateMovingAverage(dailyWeights: dailyWeights, period: 3)
        
        XCTAssertEqual(ma.count, 3) // Should have 3 results (days 3, 4, 5)
        
        // Check the first moving average (days 1-3)
        let firstMA = (80.0 + 79.8 + 79.5) / 3.0
        XCTAssertEqual(ma[0].value, firstMA, accuracy: 0.01)
        
        // Check the last moving average (days 3-5)
        let lastMA = (79.5 + 79.3 + 79.0) / 3.0
        XCTAssertEqual(ma[2].value, lastMA, accuracy: 0.01)
    }
    
    // MARK: - EMA Tests
    
    func testEMACalculation() {
        let dailyWeights = [
            (date: date(2024, 1, 1), weight: 80.0),
            (date: date(2024, 1, 2), weight: 79.0),
            (date: date(2024, 1, 3), weight: 78.0)
        ]
        
        let ema = WeightAnalytics.calculateEMA(dailyWeights: dailyWeights, period: 2)
        
        XCTAssertEqual(ema.count, 3)
        XCTAssertEqual(ema[0].value, 80.0) // First value is the same
        
        // EMA formula: EMA = (Value * alpha) + (Previous EMA * (1 - alpha))
        // alpha = 2 / (period + 1) = 2 / 3 = 0.6667
        let alpha = 2.0 / 3.0
        let secondEMA = (79.0 * alpha) + (80.0 * (1 - alpha))
        XCTAssertEqual(ema[1].value, secondEMA, accuracy: 0.01)
    }
    
    // MARK: - Consistency Score Tests
    
    func testConsistencyScoreCalculation() {
        // Create entries for 10 days out of 30
        var entries: [WeightEntry] = []
        
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let entry = WeightEntry(
                timestamp: date,
                normalizedDate: WeightEntry.normalizeDate(date),
                weightKg: 80.0,
                displayUnitAtEntry: .kilograms
            )
            entries.append(entry)
        }
        
        let score = WeightAnalytics.calculateConsistencyScore(entries: entries, windowDays: 30)
        
        XCTAssertNotNil(score)
        XCTAssertGreaterThan(score!, 0.0)
        XCTAssertLessThanOrEqual(score!, 1.0)
    }
    
    // MARK: - Trend Classification Tests
    
    func testTrendClassification() {
        // Downward trend
        let downwardWeights = [
            (date: date(2024, 1, 1), weight: 85.0),
            (date: date(2024, 1, 2), weight: 84.5),
            (date: date(2024, 1, 3), weight: 84.0),
            (date: date(2024, 1, 4), weight: 83.5),
            (date: date(2024, 1, 5), weight: 83.0),
            (date: date(2024, 1, 6), weight: 82.5),
            (date: date(2024, 1, 7), weight: 82.0)
        ]
        
        let trend = WeightAnalytics.classifyTrend(dailyWeights: downwardWeights)
        XCTAssertEqual(trend, .downward)
        
        // Stable trend
        let stableWeights = [
            (date: date(2024, 1, 1), weight: 80.0),
            (date: date(2024, 1, 2), weight: 80.1),
            (date: date(2024, 1, 3), weight: 79.9),
            (date: date(2024, 1, 4), weight: 80.0),
            (date: date(2024, 1, 5), weight: 80.1),
            (date: date(2024, 1, 6), weight: 79.9),
            (date: date(2024, 1, 7), weight: 80.0)
        ]
        
        let stableTrend = WeightAnalytics.classifyTrend(dailyWeights: stableWeights)
        XCTAssertEqual(stableTrend, .stable)
    }
    
    // MARK: - Linear Regression Tests
    
    func testLinearRegression() {
        // Simple decreasing line
        let weights = [
            (date: date(2024, 1, 1), weight: 85.0),
            (date: date(2024, 1, 2), weight: 84.0),
            (date: date(2024, 1, 3), weight: 83.0),
            (date: date(2024, 1, 4), weight: 82.0),
            (date: date(2024, 1, 5), weight: 81.0)
        ]
        
        let regression = WeightAnalytics.calculateLinearRegression(dailyWeights: weights)
        
        XCTAssertNotNil(regression.slope)
        XCTAssertNotNil(regression.intercept)
        
        // Slope should be negative (approximately -1.0)
        XCTAssertLessThan(regression.slope!, 0)
        XCTAssertEqual(regression.slope!, -1.0, accuracy: 0.01)
    }
    
    // MARK: - Goal Projection Tests
    
    func testGoalProjection() {
        // Create a consistent downward trend
        var weights: [(date: Date, weight: Double)] = []
        for i in 0..<15 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            // Fix: weight should decrease as we go back in time (i increases)
            // So older entries (larger i) should have higher weights
            let weight = 85.0 + (Double(i) * 0.2) // Started at higher weight, losing 0.2 kg per day
            weights.insert((date: date, weight: weight), at: 0)
        }
        
        let targetWeight = 80.0
        let projection = WeightAnalytics.calculateGoalProjection(
            dailyWeights: weights,
            targetWeightKg: targetWeight,
            minDays: 10
        )
        
        XCTAssertNotNil(projection)
    }
    
    // MARK: - Helper Methods
    
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
