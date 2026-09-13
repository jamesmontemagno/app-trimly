//
//  DeviceSettingsStore.swift
//  My Weight
//
//  Created by Trimly on 11/30/2025.
//

import Foundation
import Combine

enum DashboardCard: String, CaseIterable, Identifiable {
    case today, progress, sparkline, consistency, trend, calendar, plateau, projection, recap

    var id: String { rawValue }
}

/// Persists device-scoped preferences that should not sync via CloudKit
@MainActor
final class DeviceSettingsStore: ObservableObject {
    // MARK: - Nested Types
    struct PresentationSettings: Equatable {
        var dashboardCards: [DashboardCard]
        var hideWeights: Bool
    }

    struct RemindersSettings: Equatable {
        var primaryTime: Date?
        var secondaryTime: Date?
        var adaptiveEnabled: Bool
        var consecutiveDismissals: Int
    }
    
    struct HealthKitSettings: Equatable {
        var backgroundSyncEnabled: Bool
        var writeEnabled: Bool
        var autoHideDuplicates: Bool
        var duplicateToleranceKg: Double
        var lastImportAt: Date?
        var lastBackgroundSyncAt: Date?
    }
    
    struct CloudSyncSettings: Equatable {
        var iCloudSyncEnabled: Bool
    }
    
    struct ProSettings: Equatable {
        var isPro: Bool
    }
    
    struct ReviewSettings: Equatable {
        var entryCount: Int
        var hasPrompted: Bool
    }

    struct ShareCardSettings: Equatable {
        var privacy: String
        var accent: String
        var portrait: Bool
        var darkAppearance: Bool
        var showFooter: Bool
        var includeGraph: Bool
        var includeCurrent: Bool
        var includeChange: Bool
        var includeGoal: Bool
    }
    
    private enum Keys {
        static let primaryReminderTime = "device.reminders.primaryTime"
        static let secondaryReminderTime = "device.reminders.secondaryTime"
        static let adaptiveRemindersEnabled = "device.reminders.adaptiveEnabled"
        static let consecutiveDismissals = "device.reminders.consecutiveDismissals"
        static let backgroundSyncEnabled = "device.health.backgroundSyncEnabled"
        static let writeEnabled = "device.health.writeEnabled"
        static let autoHideDuplicates = "device.health.autoHideDuplicates"
        static let duplicateToleranceKg = "device.health.duplicateToleranceKg"
        static let lastImportAt = "device.health.lastImportAt"
        static let lastBackgroundSyncAt = "device.health.lastBackgroundSyncAt"
        static let iCloudSyncEnabled = "device.cloudSync.enabled"
        static let isPro = "device.pro.isPro"
        static let reviewEntryCount = "device.review.entryCount"
        static let reviewHasPrompted = "device.review.hasPrompted"
        static let dashboardCards = "device.presentation.dashboardCards"
        static let hideWeights = "device.presentation.hideWeights"
        static let sharePrivacy = "device.shareCard.privacy"
        static let shareAccent = "device.shareCard.accent"
        static let sharePortrait = "device.shareCard.portrait"
        static let shareDarkAppearance = "device.shareCard.darkAppearance"
        static let shareShowFooter = "device.shareCard.showFooter"
        static let shareIncludeGraph = "device.shareCard.includeGraph"
        static let shareIncludeCurrent = "device.shareCard.includeCurrent"
        static let shareIncludeChange = "device.shareCard.includeChange"
        static let shareIncludeGoal = "device.shareCard.includeGoal"
    }
    
    // MARK: - Published State
    @Published private(set) var reminders: RemindersSettings
    @Published private(set) var healthKit: HealthKitSettings
    @Published private(set) var cloudSync: CloudSyncSettings
    @Published private(set) var pro: ProSettings
    @Published private(set) var review: ReviewSettings
    @Published private(set) var presentation: PresentationSettings
    @Published private(set) var shareCard: ShareCardSettings
    
    var remindersPublisher: AnyPublisher<RemindersSettings, Never> {
        $reminders.eraseToAnyPublisher()
    }
    
    var healthKitPublisher: AnyPublisher<HealthKitSettings, Never> {
        $healthKit.eraseToAnyPublisher()
    }
    
    var cloudSyncPublisher: AnyPublisher<CloudSyncSettings, Never> {
        $cloudSync.eraseToAnyPublisher()
    }
    
    var proPublisher: AnyPublisher<ProSettings, Never> {
        $pro.eraseToAnyPublisher()
    }
    
    var reviewPublisher: AnyPublisher<ReviewSettings, Never> {
        $review.eraseToAnyPublisher()
    }
    
    private let defaults: UserDefaults
    
    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        defaults = userDefaults
        let storedCards = defaults.stringArray(forKey: Keys.dashboardCards)
        var seenCards = Set<DashboardCard>()
        let cards = storedCards?.compactMap(DashboardCard.init(rawValue:))
            .filter { seenCards.insert($0).inserted } ?? DashboardCard.allCases
        presentation = PresentationSettings(
            dashboardCards: cards,
            hideWeights: defaults.bool(forKey: Keys.hideWeights)
        )
        reminders = RemindersSettings(
            primaryTime: defaults.object(forKey: Keys.primaryReminderTime) as? Date,
            secondaryTime: defaults.object(forKey: Keys.secondaryReminderTime) as? Date,
            adaptiveEnabled: defaults.object(forKey: Keys.adaptiveRemindersEnabled) as? Bool ?? true,
            consecutiveDismissals: defaults.object(forKey: Keys.consecutiveDismissals) as? Int ?? 0
        )
        healthKit = HealthKitSettings(
            backgroundSyncEnabled: defaults.object(forKey: Keys.backgroundSyncEnabled) as? Bool ?? false,
            writeEnabled: defaults.object(forKey: Keys.writeEnabled) as? Bool ?? false,
            autoHideDuplicates: defaults.object(forKey: Keys.autoHideDuplicates) as? Bool ?? true,
            duplicateToleranceKg: defaults.object(forKey: Keys.duplicateToleranceKg) as? Double ?? 0.1,
            lastImportAt: defaults.object(forKey: Keys.lastImportAt) as? Date,
            lastBackgroundSyncAt: defaults.object(forKey: Keys.lastBackgroundSyncAt) as? Date
        )
        // Default to true to maintain backward compatibility with existing users
        cloudSync = CloudSyncSettings(
            iCloudSyncEnabled: defaults.object(forKey: Keys.iCloudSyncEnabled) as? Bool ?? true
        )
        // Default to false - user must purchase to become pro
        pro = ProSettings(
            isPro: defaults.object(forKey: Keys.isPro) as? Bool ?? false
        )
        review = ReviewSettings(
            entryCount: defaults.object(forKey: Keys.reviewEntryCount) as? Int ?? 0,
            hasPrompted: defaults.object(forKey: Keys.reviewHasPrompted) as? Bool ?? false
        )
        shareCard = ShareCardSettings(
            privacy: defaults.string(forKey: Keys.sharePrivacy) ?? "detailed",
            accent: defaults.string(forKey: Keys.shareAccent) ?? "blue",
            portrait: defaults.object(forKey: Keys.sharePortrait) as? Bool ?? true,
            darkAppearance: defaults.object(forKey: Keys.shareDarkAppearance) as? Bool ?? false,
            showFooter: defaults.object(forKey: Keys.shareShowFooter) as? Bool ?? true,
            includeGraph: defaults.object(forKey: Keys.shareIncludeGraph) as? Bool ?? true,
            includeCurrent: defaults.object(forKey: Keys.shareIncludeCurrent) as? Bool ?? true,
            includeChange: defaults.object(forKey: Keys.shareIncludeChange) as? Bool ?? true,
            includeGoal: defaults.object(forKey: Keys.shareIncludeGoal) as? Bool ?? true
        )
    }
    
    // MARK: - Mutation
    func updatePresentation(_ mutate: (inout PresentationSettings) -> Void) {
        var copy = presentation
        mutate(&copy)
        var seen = Set<DashboardCard>()
        copy.dashboardCards = copy.dashboardCards.filter { seen.insert($0).inserted }
        defaults.set(copy.dashboardCards.map(\.rawValue), forKey: Keys.dashboardCards)
        defaults.set(copy.hideWeights, forKey: Keys.hideWeights)
        presentation = copy
    }

    func updateReminders(_ mutate: (inout RemindersSettings) -> Void) {
        var copy = reminders
        mutate(&copy)
        reminders = copy
        persistReminders(copy)
    }
    
    func updateHealthKit(_ mutate: (inout HealthKitSettings) -> Void) {
        var copy = healthKit
        mutate(&copy)
        healthKit = copy
        persistHealthKit(copy)
    }
    
    func updateCloudSync(_ mutate: (inout CloudSyncSettings) -> Void) {
        var copy = cloudSync
        mutate(&copy)
        cloudSync = copy
        persistCloudSync(copy)
    }
    
    func updatePro(_ mutate: (inout ProSettings) -> Void) {
        var copy = pro
        mutate(&copy)
        pro = copy
        persistPro(copy)
    }
    
    func updateReview(_ mutate: (inout ReviewSettings) -> Void) {
        var copy = review
        mutate(&copy)
        review = copy
        persistReview(copy)
    }

    func updateShareCard(_ mutate: (inout ShareCardSettings) -> Void) {
        var copy = shareCard
        mutate(&copy)
        shareCard = copy
        persistShareCard(copy)
    }
    
    // MARK: - Persistence Helpers
    private func persistReminders(_ value: RemindersSettings) {
        if let primary = value.primaryTime {
            defaults.set(primary, forKey: Keys.primaryReminderTime)
        } else {
            defaults.removeObject(forKey: Keys.primaryReminderTime)
        }
        if let secondary = value.secondaryTime {
            defaults.set(secondary, forKey: Keys.secondaryReminderTime)
        } else {
            defaults.removeObject(forKey: Keys.secondaryReminderTime)
        }
        defaults.set(value.adaptiveEnabled, forKey: Keys.adaptiveRemindersEnabled)
        defaults.set(value.consecutiveDismissals, forKey: Keys.consecutiveDismissals)
    }
    
    private func persistHealthKit(_ value: HealthKitSettings) {
        defaults.set(value.backgroundSyncEnabled, forKey: Keys.backgroundSyncEnabled)
        defaults.set(value.writeEnabled, forKey: Keys.writeEnabled)
        defaults.set(value.autoHideDuplicates, forKey: Keys.autoHideDuplicates)
        defaults.set(value.duplicateToleranceKg, forKey: Keys.duplicateToleranceKg)
        if let lastImport = value.lastImportAt {
            defaults.set(lastImport, forKey: Keys.lastImportAt)
        } else {
            defaults.removeObject(forKey: Keys.lastImportAt)
        }
        if let lastBackground = value.lastBackgroundSyncAt {
            defaults.set(lastBackground, forKey: Keys.lastBackgroundSyncAt)
        } else {
            defaults.removeObject(forKey: Keys.lastBackgroundSyncAt)
        }
    }
    
    private func persistCloudSync(_ value: CloudSyncSettings) {
        defaults.set(value.iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled)
    }
    
    private func persistPro(_ value: ProSettings) {
        defaults.set(value.isPro, forKey: Keys.isPro)
    }
    
    private func persistReview(_ value: ReviewSettings) {
        defaults.set(value.entryCount, forKey: Keys.reviewEntryCount)
        defaults.set(value.hasPrompted, forKey: Keys.reviewHasPrompted)
    }

    private func persistShareCard(_ value: ShareCardSettings) {
        defaults.set(value.privacy, forKey: Keys.sharePrivacy)
        defaults.set(value.accent, forKey: Keys.shareAccent)
        defaults.set(value.portrait, forKey: Keys.sharePortrait)
        defaults.set(value.darkAppearance, forKey: Keys.shareDarkAppearance)
        defaults.set(value.showFooter, forKey: Keys.shareShowFooter)
        defaults.set(value.includeGraph, forKey: Keys.shareIncludeGraph)
        defaults.set(value.includeCurrent, forKey: Keys.shareIncludeCurrent)
        defaults.set(value.includeChange, forKey: Keys.shareIncludeChange)
        defaults.set(value.includeGoal, forKey: Keys.shareIncludeGoal)
    }
}
