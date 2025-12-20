//
//  ReviewPromptService.swift
//  TrimTally
//
//  Created by Trimly on 12/20/2025.
//

import Foundation
import StoreKit
#if os(iOS)
import UIKit
#endif

/// Manages App Store review prompts based on user engagement
@MainActor
final class ReviewPromptService {
    private let deviceSettings: DeviceSettingsStore
    /// The number of manual entries required before prompting for review
    static let defaultEntryThreshold = 10
    private let entryThreshold: Int
    
    init(deviceSettings: DeviceSettingsStore, entryThreshold: Int = defaultEntryThreshold) {
        self.deviceSettings = deviceSettings
        self.entryThreshold = entryThreshold
    }
    
    /// Increments the entry count and checks if we should prompt for review
    /// Returns true if the prompt was shown
    @discardableResult
    func incrementEntryCountAndPromptIfNeeded() -> Bool {
        var shouldPrompt = false
        
        deviceSettings.updateReview { review in
            review.entryCount += 1
            
            // Check if we've hit the threshold and haven't prompted yet
            if review.entryCount >= entryThreshold && !review.hasPrompted {
                shouldPrompt = true
                review.hasPrompted = true
            }
        }
        
        if shouldPrompt {
            requestReview()
        }
        
        return shouldPrompt
    }
    
    /// Manually request a review (e.g., from Settings)
    /// Silently handles any exceptions that may occur during the review request
    func requestReview() {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            // No valid window scene available, silently return
            return
        }
        // Request review - any exceptions will be handled by the system
        SKStoreReviewController.requestReview(in: windowScene)
        #elseif os(macOS)
        // Request review - any exceptions will be handled by the system
        SKStoreReviewController.requestReview()
        #endif
    }
    
    /// Reset the review prompt state (useful for testing or if user opts to reset)
    func resetReviewPromptState() {
        deviceSettings.updateReview { review in
            review.hasPrompted = false
        }
    }
    
    /// Get the current entry count
    var currentEntryCount: Int {
        deviceSettings.review.entryCount
    }
    
    /// Check if the review prompt has been shown
    var hasPromptedForReview: Bool {
        deviceSettings.review.hasPrompted
    }
}
