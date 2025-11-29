//
//  WeightEntry.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import SwiftData

/// Represents a single weight measurement entry
@Model
final class WeightEntry {
    /// Unique identifier
    var id: UUID = UUID()
    
    /// The exact timestamp when the weight was recorded
    var timestamp: Date = Date()
    
    /// Normalized date (day boundary in local timezone) for daily aggregation
    var normalizedDate: Date = Date()
    
    /// Weight value stored internally in kilograms
    var weightKg: Double = 0
    
    /// The unit that was displayed at entry time (for historical accuracy)
    var displayUnitAtEntry: WeightUnit = WeightUnit.kilograms
    
    /// Source of the entry (manual or HealthKit)
    var source: EntrySource = EntrySource.manual
    
    /// Optional user notes for this entry
    var notes: String?
    
    /// When the entry was created (for conflict resolution)
    var createdAt: Date = Date()
    
    /// When the entry was last updated
    var updatedAt: Date = Date()
    
    /// Whether this entry is hidden (e.g., HealthKit duplicate)
    var isHidden: Bool = false
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        normalizedDate: Date? = nil,
        weightKg: Double,
        displayUnitAtEntry: WeightUnit,
        source: EntrySource = .manual,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isHidden: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.normalizedDate = normalizedDate ?? Self.normalizeDate(timestamp)
        self.weightKg = weightKg
        self.displayUnitAtEntry = displayUnitAtEntry
        self.source = source
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isHidden = isHidden
    }
    
    /// Normalize a date to the start of the day in local timezone
    static func normalizeDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Get display value in the original unit
    @MainActor var displayValue: Double {
        displayUnitAtEntry.convert(fromKg: weightKg)
    }
}

/// Weight unit enumeration
enum WeightUnit: String, Codable {
    case kilograms = "kg"
    case pounds = "lb"
    
    /// Convert from kilograms to this unit
    func convert(fromKg kg: Double) -> Double {
        switch self {
        case .kilograms:
            return kg
        case .pounds:
            return kg * 2.20462
        }
    }
    
    /// Convert from this unit to kilograms
    func convertToKg(_ value: Double) -> Double {
        switch self {
        case .kilograms:
            return value
        case .pounds:
            return value / 2.20462
        }
    }
    
    var symbol: String {
        rawValue
    }
}

/// Entry source enumeration
enum EntrySource: String, Codable {
    case manual = "manual"
    case healthKit = "healthKit"
}
