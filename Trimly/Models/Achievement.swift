//
//  Achievement.swift
//  TrimTally
//
//  Created by Trimly on 11/29/25.
//

import Foundation
import SwiftData

/// Persisted progress/unlock state for a defined achievement key
@Model
final class Achievement {
	/// Stable identifier for the achievement definition (e.g., "streak.7")
	var key: String
	/// Timestamp when the achievement was first unlocked
	var unlockedAt: Date?
	/// Latest normalized progress value in range 0...1
	var progressValue: Double
	/// Last time the achievement was evaluated
	var evaluatedAt: Date
	/// Whether the unlock animation/celebration has been presented
	var didCelebrateUnlock: Bool
	/// Whether this achievement is reserved for TrimTally Pro subscribers
	var isPremium: Bool
	/// Optional custom data payload (e.g., last threshold hit) for future expansion
	var metadata: Data?
	/// Creation timestamp
	var createdAt: Date
	/// Last mutation timestamp
	var updatedAt: Date

	init(
		key: String,
		unlockedAt: Date? = nil,
		progressValue: Double = 0,
		evaluatedAt: Date = Date(),
		didCelebrateUnlock: Bool = false,
		isPremium: Bool = false,
		metadata: Data? = nil,
		createdAt: Date = Date(),
		updatedAt: Date = Date()
	) {
		self.key = key
		self.unlockedAt = unlockedAt
		self.progressValue = progressValue
		self.evaluatedAt = evaluatedAt
		self.didCelebrateUnlock = didCelebrateUnlock
		self.isPremium = isPremium
		self.metadata = metadata
		self.createdAt = createdAt
		self.updatedAt = updatedAt
	}
}
