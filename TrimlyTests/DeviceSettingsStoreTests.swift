import Foundation
import XCTest
@testable import TrimTally

@MainActor
final class DeviceSettingsStoreTests: XCTestCase {
    func testUpdateRemindersPersistsAcrossInstances() {
        let (defaults, store) = makeStore()
        let morning = Date(timeIntervalSince1970: 1_701_000_000)
        store.updateReminders { reminders in
            reminders.primaryTime = morning
            reminders.adaptiveEnabled = false
            reminders.consecutiveDismissals = 3
        }
        let reloaded = DeviceSettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.reminders.primaryTime, morning)
        XCTAssertNil(reloaded.reminders.secondaryTime)
        XCTAssertFalse(reloaded.reminders.adaptiveEnabled)
        XCTAssertEqual(reloaded.reminders.consecutiveDismissals, 3)
    }
    
    func testUpdateHealthKitPersistsAcrossInstances() {
        let (defaults, store) = makeStore()
        let lastImport = Date(timeIntervalSince1970: 1_701_111_111)
        let lastBackground = Date(timeIntervalSince1970: 1_701_222_222)
        store.updateHealthKit { health in
            health.backgroundSyncEnabled = true
            health.writeEnabled = true
            health.autoHideDuplicates = false
            health.duplicateToleranceKg = 0.35
            health.lastImportAt = lastImport
            health.lastBackgroundSyncAt = lastBackground
        }
        let reloaded = DeviceSettingsStore(userDefaults: defaults)
        let reloadedHealth = reloaded.healthKit
        XCTAssertTrue(reloadedHealth.backgroundSyncEnabled)
        XCTAssertTrue(reloadedHealth.writeEnabled)
        XCTAssertFalse(reloadedHealth.autoHideDuplicates)
        XCTAssertEqual(reloadedHealth.duplicateToleranceKg, 0.35, accuracy: 0.0001)
        XCTAssertEqual(reloadedHealth.lastImportAt, lastImport)
        XCTAssertEqual(reloadedHealth.lastBackgroundSyncAt, lastBackground)
    }
    
    func testCloudSyncDefaultsToEnabled() {
        let (_, store) = makeStore()
        XCTAssertTrue(store.cloudSync.iCloudSyncEnabled, "iCloud sync should be enabled by default for backward compatibility")
    }
    
    func testUpdateCloudSyncPersistsAcrossInstances() {
        let (defaults, store) = makeStore()
        store.updateCloudSync { settings in
            settings.iCloudSyncEnabled = false
        }
        let reloaded = DeviceSettingsStore(userDefaults: defaults)
        XCTAssertFalse(reloaded.cloudSync.iCloudSyncEnabled)
    }
    
    func testProDefaultsToFalse() {
        let (_, store) = makeStore()
        XCTAssertFalse(store.pro.isPro, "Pro status should be false by default")
    }
    
    func testUpdateProPersistsAcrossInstances() {
        let (defaults, store) = makeStore()
        // Initially false
        XCTAssertFalse(store.pro.isPro)
        
        // Update to true
        store.updatePro { pro in
            pro.isPro = true
        }
        XCTAssertTrue(store.pro.isPro)
        
        // Verify persistence across instances
        let reloaded = DeviceSettingsStore(userDefaults: defaults)
        XCTAssertTrue(reloaded.pro.isPro, "Pro status should persist across instances")
        
        // Update back to false
        reloaded.updatePro { pro in
            pro.isPro = false
        }
        
        // Verify it persists again
        let reloaded2 = DeviceSettingsStore(userDefaults: defaults)
        XCTAssertFalse(reloaded2.pro.isPro, "Pro status should persist when set to false")
    }
    
    func testReviewSettingsDefaultToZero() {
        let (_, store) = makeStore()
        XCTAssertEqual(store.review.entryCount, 0, "Entry count should default to 0")
        XCTAssertFalse(store.review.hasPrompted, "hasPrompted should default to false")
    }
    
    func testUpdateReviewPersistsAcrossInstances() {
        let (defaults, store) = makeStore()
        // Initially default values
        XCTAssertEqual(store.review.entryCount, 0)
        XCTAssertFalse(store.review.hasPrompted)
        
        // Update entry count
        store.updateReview { review in
            review.entryCount = 5
        }
        XCTAssertEqual(store.review.entryCount, 5)
        
        // Verify persistence across instances
        let reloaded = DeviceSettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.review.entryCount, 5, "Entry count should persist")
        XCTAssertFalse(reloaded.review.hasPrompted, "hasPrompted should still be false")
        
        // Update to prompted
        reloaded.updateReview { review in
            review.entryCount = 10
            review.hasPrompted = true
        }
        
        // Verify both values persist
        let reloaded2 = DeviceSettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded2.review.entryCount, 10, "Entry count should persist at 10")
        XCTAssertTrue(reloaded2.review.hasPrompted, "hasPrompted should persist as true")
    }
    
    private func makeStore() -> (UserDefaults, DeviceSettingsStore) {
        let suiteName = "com.trimly.tests.devicesettings.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults suite \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = DeviceSettingsStore(userDefaults: defaults)
        return (defaults, store)
    }
}
