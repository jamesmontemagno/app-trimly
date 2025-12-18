//
//  DeviceSettingsStore.swift
//  TrimTally
//
//  Created by Trimly on 11/30/2025.
//

import Foundation
import Combine

/// Persists device-scoped preferences that should not sync via CloudKit
@MainActor
final class DeviceSettingsStore: ObservableObject {
    // MARK: - Nested Types
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
    }
    
    // MARK: - Published State
    @Published private(set) var reminders: RemindersSettings
    @Published private(set) var healthKit: HealthKitSettings
    @Published private(set) var cloudSync: CloudSyncSettings
    @Published private(set) var pro: ProSettings
    
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
    
    private let defaults: UserDefaults
    
    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        defaults = userDefaults
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
    }
    
    // MARK: - Mutation
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
}
