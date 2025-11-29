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
    
    // Notification identifiers
    private let primaryReminderID = "trimly.reminder.primary"
    private let secondaryReminderID = "trimly.reminder.secondary"
    
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
    
    /// Schedule daily reminder
    func scheduleDailyReminder(at time: Date) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        // Cancel existing reminder
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [primaryReminderID])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = String(localized: L10n.Notifications.primaryTitle)
        content.body = String(localized: L10n.Notifications.primaryBody)
        content.sound = .default
        content.categoryIdentifier = "WEIGHT_REMINDER"
        
        // Create trigger for daily reminder
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: primaryReminderID,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    /// Schedule secondary reminder (optional)
    func scheduleSecondaryReminder(at time: Date) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        // Cancel existing reminder
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [secondaryReminderID])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = String(localized: L10n.Notifications.secondaryTitle)
        content.body = String(localized: L10n.Notifications.secondaryBody)
        content.sound = .default
        content.categoryIdentifier = "WEIGHT_REMINDER"
        
        // Create trigger for daily reminder
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: secondaryReminderID,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    /// Cancel all reminders
    func cancelAllReminders() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [primaryReminderID, secondaryReminderID]
        )
    }
    
    /// Cancel primary reminder
    func cancelPrimaryReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [primaryReminderID])
    }
    
    /// Cancel secondary reminder
    func cancelSecondaryReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [secondaryReminderID])
    }
    
    // MARK: - Adaptive Reminders
    
    /// Suggest a new reminder time based on logging patterns
    func suggestReminderTime(dataManager: DataManager) -> Date? {
        let entries = dataManager.fetchAllEntries()
        
        // Get entries from last 10 days
        let recentEntries = entries.filter {
            let daysSince = Calendar.current.dateComponents([.day], from: $0.timestamp, to: Date()).day ?? 0
            return daysSince <= 10
        }
        
        guard !recentEntries.isEmpty else { return nil }
        
        // Calculate median logging time
        let hours = recentEntries.map { entry -> Int in
            Calendar.current.component(.hour, from: entry.timestamp)
        }.sorted()
        
        let medianHour = hours[hours.count / 2]
        
        // Create suggested time
        var components = DateComponents()
        components.hour = medianHour
        components.minute = 0
        
        return Calendar.current.date(from: components)
    }
    
    /// Check if user should be prompted for reminder time adjustment
    func shouldSuggestTimeAdjustment(dataManager: DataManager) -> Bool {
        guard let settings = dataManager.settings else { return false }
        
        // Suggest after 3 consecutive dismissals
        return settings.adaptiveRemindersEnabled &&
               settings.consecutiveReminderDismissals >= 3
    }
    
    /// Handle reminder dismissal
    func handleReminderDismissal(dataManager: DataManager, didLogWithinWindow: Bool) {
        guard dataManager.settings != nil else { return }
        
        if didLogWithinWindow {
            // User logged weight within 2 hours of reminder - reset counter
            dataManager.updateSettings { settings in
                settings.consecutiveReminderDismissals = 0
            }
        } else {
            // User dismissed without logging - increment counter
            dataManager.updateSettings { settings in
                settings.consecutiveReminderDismissals += 1
            }
        }
    }
    
    /// Cancel reminder if user logged before fire time
    func cancelTodayReminderIfLogged(dataManager: DataManager) {
        let todayEntries = dataManager.fetchEntriesForDate(Date())
        
        if !todayEntries.isEmpty {
            // User already logged today - cancel today's notification
            notificationCenter.removeDeliveredNotifications(
                withIdentifiers: [primaryReminderID, secondaryReminderID]
            )
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
