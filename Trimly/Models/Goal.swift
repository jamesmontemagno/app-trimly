//
//  Goal.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import SwiftData

/// Represents a weight goal (single active goal with historical tracking)
@Model
final class Goal {
    /// Unique identifier
    var id: UUID = UUID()
    
    /// Target weight in kilograms
    var targetWeightKg: Double = 0
    
    /// Date when the goal was set
    var startDate: Date = Date()
    
    /// Optional target date to achieve the goal
    var targetDate: Date?
    
    /// Whether this is the currently active goal
    var isActive: Bool = true
    
    /// Date when the goal was completed or archived
    var completedDate: Date?
    
    /// Reason for completion (achieved, changed, abandoned)
    var completionReason: CompletionReason?
    
    /// Starting weight when goal was set
    var startingWeightKg: Double?
    
    /// Notes about the goal
    var notes: String?
    
    /// Creation timestamp
    var createdAt: Date = Date()
    
    /// Last update timestamp
    var updatedAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        targetWeightKg: Double,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        isActive: Bool = true,
        completedDate: Date? = nil,
        completionReason: CompletionReason? = nil,
        startingWeightKg: Double? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.targetWeightKg = targetWeightKg
        self.startDate = startDate
        self.targetDate = targetDate
        self.isActive = isActive
        self.completedDate = completedDate
        self.completionReason = completionReason
        self.startingWeightKg = startingWeightKg
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Archive this goal (mark as inactive)
    func archive(reason: CompletionReason) {
        isActive = false
        completedDate = Date()
        completionReason = reason
        updatedAt = Date()
    }
}

/// Reason for goal completion
enum CompletionReason: String, Codable {
    case achieved = "achieved"
    case changed = "changed"
    case abandoned = "abandoned"
}
