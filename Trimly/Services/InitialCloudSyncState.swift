//  InitialCloudSyncState.swift
//  TrimTally
//
//  Created by Trimly on 11/30/2025.
//

import Foundation

/// Tracks initial CloudKit-backed SwiftData sync state locally via UserDefaults.
struct InitialCloudSyncState {
    private enum Key: String {
        case hasFinishedInitialCloudSync
        case hasShownInitialCloudSyncSuccess
        case hasAutoCompletedOnboardingFromCloudData
    }
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    var hasFinishedInitialCloudSync: Bool {
        defaults.bool(forKey: Key.hasFinishedInitialCloudSync.rawValue)
    }
    
    var hasShownInitialCloudSyncSuccess: Bool {
        defaults.bool(forKey: Key.hasShownInitialCloudSyncSuccess.rawValue)
    }
    
    var hasAutoCompletedOnboardingFromCloudData: Bool {
        defaults.bool(forKey: Key.hasAutoCompletedOnboardingFromCloudData.rawValue)
    }
    
    mutating func markInitialCloudSyncCompleted() {
        defaults.set(true, forKey: Key.hasFinishedInitialCloudSync.rawValue)
    }
    
    mutating func markInitialCloudSyncSuccessShown() {
        defaults.set(true, forKey: Key.hasShownInitialCloudSyncSuccess.rawValue)
    }
    
    mutating func markAutoCompletedOnboardingFromCloudData() {
        defaults.set(true, forKey: Key.hasAutoCompletedOnboardingFromCloudData.rawValue)
    }
}
