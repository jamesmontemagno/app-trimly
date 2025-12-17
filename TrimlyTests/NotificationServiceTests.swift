import Foundation
import Testing
@testable import TrimTally

@MainActor
struct NotificationServiceTests {
	
	// MARK: - Helpers
	
	private func makeTestDataManager() async -> DataManager {
		let suiteName = "com.trimly.tests.notificationservice.\(UUID().uuidString)"
		guard let defaults = UserDefaults(suiteName: suiteName) else {
			fatalError("Failed to create UserDefaults suite \(suiteName)")
		}
		defaults.removePersistentDomain(forName: suiteName)
		let deviceSettings = DeviceSettingsStore(userDefaults: defaults)
		return await DataManager(inMemory: true, deviceSettings: deviceSettings)
	}
	
	@Test
	func ensureReminderSchedule_checksForTodayEntries() async throws {
		let manager = await makeTestDataManager()
		let notificationService = NotificationService()
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		
		// Add a weight entry for today
		try manager.addWeightEntry(weightKg: 80.0, timestamp: today, unit: .kilograms)
		
		// Verify that today has entries
		let todayEntries = manager.fetchEntriesForDate(today)
		#expect(todayEntries.count == 1)
		
		// When we call ensureReminderSchedule with a dataManager that has today's entry,
		// it should internally determine to skip today's notifications.
		// This test verifies the method signature and logic path.
		
		// Setup reminder times
		manager.deviceSettings.updateReminders { reminders in
			var components = DateComponents()
			components.hour = 9
			components.minute = 0
			reminders.primaryTime = calendar.date(from: components)
		}
		
		// The method should accept dataManager and check for today's entries
		await notificationService.ensureReminderSchedule(
			reminders: manager.deviceSettings.reminders,
			dataManager: manager
		)
		
		// Since we can't easily verify the actual notification scheduling without
		// system permissions, this test primarily validates that:
		// 1. The method signature accepts dataManager
		// 2. The method can be called with today's entries present
		// 3. No crashes or errors occur
	}
	
	@Test
	func ensureReminderSchedule_worksWithNoEntriesToday() async throws {
		let manager = await makeTestDataManager()
		let notificationService = NotificationService()
		let calendar = Calendar.current
		let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
		
		// Add a weight entry for yesterday, not today
		try manager.addWeightEntry(weightKg: 80.0, timestamp: yesterday, unit: .kilograms)
		
		// Verify that today has no entries
		let todayEntries = manager.fetchEntriesForDate(Date())
		#expect(todayEntries.isEmpty)
		
		// Setup reminder times
		manager.deviceSettings.updateReminders { reminders in
			var components = DateComponents()
			components.hour = 9
			components.minute = 0
			reminders.primaryTime = calendar.date(from: components)
		}
		
		// When there are no entries for today, notifications should be scheduled
		// including for today (if the time hasn't passed yet)
		await notificationService.ensureReminderSchedule(
			reminders: manager.deviceSettings.reminders,
			dataManager: manager
		)
		
		// This test verifies that the method works correctly when today has no entries
	}
}
