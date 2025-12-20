import Foundation
import XCTest
@testable import TrimTally

@MainActor
final class ReviewPromptServiceTests: XCTestCase {
    func testIncrementEntryCountTracksCorrectly() {
        let (_, deviceSettings) = makeStore()
        let service = ReviewPromptService(deviceSettings: deviceSettings)
        
        // Initial state
        XCTAssertEqual(service.currentEntryCount, 0)
        XCTAssertFalse(service.hasPromptedForReview)
        
        // Increment a few times (below threshold)
        for _ in 0..<5 {
            let prompted = service.incrementEntryCountAndPromptIfNeeded()
            XCTAssertFalse(prompted, "Should not prompt before threshold")
        }
        XCTAssertEqual(service.currentEntryCount, 5)
        XCTAssertFalse(service.hasPromptedForReview)
        
        // Increment to threshold (10 entries)
        for _ in 5..<10 {
            _ = service.incrementEntryCountAndPromptIfNeeded()
        }
        XCTAssertEqual(service.currentEntryCount, 10)
        XCTAssertTrue(service.hasPromptedForReview, "Should have prompted at 10 entries")
        
        // Increment beyond threshold - should not prompt again
        let promptedAgain = service.incrementEntryCountAndPromptIfNeeded()
        XCTAssertFalse(promptedAgain, "Should not prompt again after already prompted")
        XCTAssertEqual(service.currentEntryCount, 11)
    }
    
    func testResetReviewPromptState() {
        let (_, deviceSettings) = makeStore()
        let service = ReviewPromptService(deviceSettings: deviceSettings)
        
        // Increment to threshold
        for _ in 0..<10 {
            _ = service.incrementEntryCountAndPromptIfNeeded()
        }
        XCTAssertTrue(service.hasPromptedForReview)
        
        // Reset the prompt state
        service.resetReviewPromptState()
        XCTAssertFalse(service.hasPromptedForReview, "Should reset prompt state")
        XCTAssertEqual(service.currentEntryCount, 10, "Entry count should not change on reset")
    }
    
    func testPersistenceAcrossInstances() {
        let (defaults, deviceSettings) = makeStore()
        let service = ReviewPromptService(deviceSettings: deviceSettings)
        
        // Increment count
        for _ in 0..<7 {
            _ = service.incrementEntryCountAndPromptIfNeeded()
        }
        
        // Create new instance with same storage
        let deviceSettings2 = DeviceSettingsStore(userDefaults: defaults)
        let service2 = ReviewPromptService(deviceSettings: deviceSettings2)
        
        XCTAssertEqual(service2.currentEntryCount, 7, "Entry count should persist")
        XCTAssertFalse(service2.hasPromptedForReview, "Prompt state should persist")
    }
    
    private func makeStore() -> (UserDefaults, DeviceSettingsStore) {
        let suiteName = "com.trimly.tests.reviewprompt.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults suite \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        let store = DeviceSettingsStore(userDefaults: defaults)
        return (defaults, store)
    }
}
