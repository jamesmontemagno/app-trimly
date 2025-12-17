//
//  NotificationService.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import Foundation
import Combine
import UserNotifications

/// Service for managing local notifications and reminders
@MainActor
final class NotificationService: ObservableObject {
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var isAuthorized = false
    
    // Notification identifiers (base prefixes; individual occurrences append date)
    private let primaryReminderID = "trimly.reminder.primary"
    private let secondaryReminderID = "trimly.reminder.secondary"
    private let reminderLookaheadDays = 14
    private static let dailyIdentifierFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Authorization
    
    /// Request notification authorization
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await notificationCenter.requestAuthorization(options: options)
        isAuthorized = granted
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = (settings.authorizationStatus == .authorized)
    }
    
    // MARK: - Schedule Reminders
    
    /// Schedule a rolling set of single-occurrence primary reminders (non-repeating)
    func scheduleDailyReminder(at time: Date) async throws {
        try await scheduleSeries(baseID: primaryReminderID, time: time, title: L10n.Notifications.primaryTitle, body: L10n.Notifications.primaryBody, sound: .default)
    }
    
    /// Schedule a rolling set of single-occurrence secondary reminders (non-repeating)
    func scheduleSecondaryReminder(at time: Date) async throws {
        try await scheduleSeries(baseID: secondaryReminderID, time: time, title: L10n.Notifications.secondaryTitle, body: L10n.Notifications.secondaryBody, sound: .default)
    }
    
    /// Cancel all reminders
    func cancelAllReminders() {
        Task {
            await removePending(withBaseIDs: [primaryReminderID, secondaryReminderID])
        }
    }
    
    /// Cancel primary reminder
    func cancelPrimaryReminder() {
        Task {
            await removePending(withBaseIDs: [primaryReminderID])
        }
    }
    
    /// Cancel secondary reminder
    func cancelSecondaryReminder() {
        Task {
            await removePending(withBaseIDs: [secondaryReminderID])
        }
    }
    
    // MARK: - Adaptive Reminders
    
    /// Suggest a new reminder time based on logging patterns
    func suggestReminderTime(dataManager: DataManager) -> Date? {
        let entries = dataManager.fetchAllEntries()
        let recentEntries = entries.filter {
            let daysSince = Calendar.current.dateComponents([.day], from: $0.timestamp, to: Date()).day ?? 0
            return daysSince <= 10
        }
        guard !recentEntries.isEmpty else { return nil }
        let hours = recentEntries.map { entry -> Int in
            Calendar.current.component(.hour, from: entry.timestamp)
        }.sorted()
        let medianHour = hours[hours.count / 2]
        var components = DateComponents()
        components.hour = medianHour
        components.minute = 0
        return Calendar.current.date(from: components)
    }
    
    /// Check if user should be prompted for reminder time adjustment
    func shouldSuggestTimeAdjustment(reminders: DeviceSettingsStore.RemindersSettings) -> Bool {
        reminders.adaptiveEnabled && reminders.consecutiveDismissals >= 3
    }
    
    /// Handle reminder dismissal
    func handleReminderDismissal(deviceSettings: DeviceSettingsStore, didLogWithinWindow: Bool) {
        if didLogWithinWindow {
            deviceSettings.updateReminders { reminders in
                reminders.consecutiveDismissals = 0
            }
        } else {
            deviceSettings.updateReminders { reminders in
                reminders.consecutiveDismissals += 1
            }
        }
    }
    
    /// Cancel reminder occurrences for today if the user already logged, then top-up future occurrences
    func cancelTodayReminderIfLogged(dataManager: DataManager, reminders: DeviceSettingsStore.RemindersSettings) async {
        let todayEntries = dataManager.fetchEntriesForDate(Date())
        guard !todayEntries.isEmpty else { return }
        
        let idsForToday = todayReminderIdentifiers()
        notificationCenter.removeDeliveredNotifications(withIdentifiers: idsForToday)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: idsForToday)
        
        if let primaryTime = reminders.primaryTime {
            try? await scheduleSeries(baseID: primaryReminderID, time: primaryTime, title: L10n.Notifications.primaryTitle, body: L10n.Notifications.primaryBody, sound: .default, skipToday: true)
        }
        if let secondaryTime = reminders.secondaryTime {
            try? await scheduleSeries(baseID: secondaryReminderID, time: secondaryTime, title: L10n.Notifications.secondaryTitle, body: L10n.Notifications.secondaryBody, sound: .default, skipToday: true)
        }
    }
    
    /// Ensure reminders are scheduled for the configured window (used on app launch)
    func ensureReminderSchedule(reminders: DeviceSettingsStore.RemindersSettings, dataManager: DataManager) async {
        if isAuthorized == false {
            await checkAuthorizationStatus()
        }
        guard isAuthorized else { return }
        
        // Check if user has already logged weight for today
        let todayEntries = dataManager.fetchEntriesForDate(Date())
        let skipToday = !todayEntries.isEmpty
        
        if let primaryTime = reminders.primaryTime {
            try? await scheduleSeries(baseID: primaryReminderID, time: primaryTime, title: L10n.Notifications.primaryTitle, body: L10n.Notifications.primaryBody, sound: .default, skipToday: skipToday)
        }
        if let secondaryTime = reminders.secondaryTime {
            try? await scheduleSeries(baseID: secondaryReminderID, time: secondaryTime, title: L10n.Notifications.secondaryTitle, body: L10n.Notifications.secondaryBody, sound: .default, skipToday: skipToday)
        }
    }
    
    // MARK: - Scheduling Helpers
    
    private func scheduleSeries(
        baseID: String,
        time: Date,
        title: LocalizedStringResource,
        body: LocalizedStringResource,
        sound: UNNotificationSound?,
        skipToday: Bool = false
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        await removePending(withBaseIDs: [baseID])
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let content = UNMutableNotificationContent()
        content.title = String(localized: title)
        content.body = String(localized: body)
        content.sound = sound
        content.categoryIdentifier = "WEIGHT_REMINDER"
        
        for offset in 0..<reminderLookaheadDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            guard let fireDate = calendar.date(bySettingHour: components.hour ?? 8, minute: components.minute ?? 0, second: 0, of: day) else { continue }
            if skipToday && calendar.isDate(fireDate, inSameDayAs: now) {
                continue
            }
            if fireDate <= now { continue }
            let id = makeIdentifier(baseID: baseID, date: fireDate)
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            do {
                try await notificationCenter.add(request)
            } catch {
                print("[Notifications] Failed to schedule \(id): \(error)")
            }
        }
    }
    
    private func todayReminderIdentifiers() -> [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [primaryReminderID, secondaryReminderID].map { makeIdentifier(baseID: $0, date: today) }
    }
    
    private func makeIdentifier(baseID: String, date: Date) -> String {
        let formatter = NotificationService.dailyIdentifierFormatter
        return "\(baseID).\(formatter.string(from: date))"
    }
    
    private func removePending(withBaseIDs baseIDs: [String]) async {
        let identifiers = await pendingRequestIdentifiers()
        let idsToRemove = identifiers
            .filter { id in baseIDs.contains { id.hasPrefix($0) } }
        guard !idsToRemove.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }
    
    private func pendingRequestIdentifiers() async -> [String] {
        await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                let identifiers = requests.map { $0.identifier }
                continuation.resume(returning: identifiers)
            }
        }
    }
    
    /// Get detailed info about pending notifications for debugging
    func getPendingNotificationsDebugInfo() async -> [String] {
        await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                
                let info = requests.sorted { r1, r2 in
                    guard let t1 = r1.trigger as? UNCalendarNotificationTrigger,
                          let t2 = r2.trigger as? UNCalendarNotificationTrigger,
                          let d1 = t1.nextTriggerDate(),
                          let d2 = t2.nextTriggerDate() else { return false }
                    return d1 < d2
                }.map { request -> String in
                    var result = request.identifier
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let nextDate = trigger.nextTriggerDate() {
                        result += " → \(formatter.string(from: nextDate))"
                    }
                    return result
                }
                continuation.resume(returning: info)
            }
        }
    }
}

// MARK: - Notification Categories

extension NotificationService {
    
    /// Setup notification categories and actions
    func setupNotificationCategories() {
        let quickLogAction = UNNotificationAction(
            identifier: "QUICK_LOG",
            title: String(localized: L10n.Notifications.actionQuickLog),
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: String(localized: L10n.Notifications.actionDismiss),
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "WEIGHT_REMINDER",
            actions: [quickLogAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed(Error)
    
    var errorDescription: String? {
        switch self {
            case .notAuthorized:
                return String(localized: "notifications.error.notAuthorized", defaultValue: "Notification permission not granted")
            case .schedulingFailed(let error):
                return String(localized: "notifications.error.schedulingFailed", defaultValue: "Failed to schedule notification: \(error.localizedDescription)")
        }
    }
}
