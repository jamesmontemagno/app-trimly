//
//  RemindersView.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var notificationService = NotificationService()
    @Environment(\.dismiss) var dismiss
    
    @State private var primaryReminderEnabled = false
    @State private var primaryReminderTime = Date()
    @State private var secondaryReminderEnabled = false
    @State private var secondaryReminderTime = Date()
    @State private var adaptiveEnabled = true
    @State private var showingSuggestion = false
    @State private var suggestedTime: Date?
    
    var body: some View {
        NavigationStack {
            Form {
                // Authorization Section
                Section {
                    if notificationService.isAuthorized {
                        Label("Notifications Authorized", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Request Notification Access") {
                            requestAuthorization()
                        }
                    }
                } header: {
                    Text("Authorization")
                }
                
                // Primary Reminder
                if notificationService.isAuthorized {
                    Section {
                        Toggle("Daily Reminder", isOn: $primaryReminderEnabled)
                            .onChange(of: primaryReminderEnabled) { _, enabled in
                                handlePrimaryReminderToggle(enabled: enabled)
                            }
                        
                        if primaryReminderEnabled {
                            DatePicker("Time", selection: $primaryReminderTime, displayedComponents: .hourAndMinute)
                                .onChange(of: primaryReminderTime) { _, newTime in
                                    scheduleReminder(time: newTime)
                                }
                        }
                    } header: {
                        Text("Primary Reminder")
                    } footer: {
                        Text("Get a daily reminder to log your weight.")
                    }
                    
                    // Adaptive Reminders
                    if primaryReminderEnabled {
                        Section {
                            Toggle("Smart Time Suggestions", isOn: $adaptiveEnabled)
                                .onChange(of: adaptiveEnabled) { _, enabled in
                                    dataManager.updateSettings { settings in
                                        settings.adaptiveRemindersEnabled = enabled
                                    }
                                }
                            
                            if notificationService.shouldSuggestTimeAdjustment(dataManager: dataManager),
                               let suggested = notificationService.suggestReminderTime(dataManager: dataManager) {
                                Button {
                                    primaryReminderTime = suggested
                                    scheduleReminder(time: suggested)
                                    dataManager.updateSettings { settings in
                                        settings.consecutiveReminderDismissals = 0
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Suggested Time: \(suggested, style: .time)")
                                            .font(.subheadline)
                                        Text("Based on your logging patterns")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("Adaptive Behavior")
                        } footer: {
                            Text("The app will suggest better reminder times based on when you typically log your weight.")
                        }
                    }
                    
                    // Secondary Reminder
                    Section {
                        Toggle("Evening Reminder", isOn: $secondaryReminderEnabled)
                            .onChange(of: secondaryReminderEnabled) { _, enabled in
                                handleSecondaryReminderToggle(enabled: enabled)
                            }
                        
                        if secondaryReminderEnabled {
                            DatePicker("Time", selection: $secondaryReminderTime, displayedComponents: .hourAndMinute)
                                .onChange(of: secondaryReminderTime) { _, newTime in
                                    scheduleSecondaryReminder(time: newTime)
                                }
                        }
                    } header: {
                        Text("Secondary Reminder (Optional)")
                    } footer: {
                        Text("Add a second daily reminder for evening check-ins.")
                    }
                }
            }
            .navigationTitle("Reminders")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSettings()
                Task {
                    await notificationService.checkAuthorizationStatus()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func requestAuthorization() {
        Task {
            do {
                try await notificationService.requestAuthorization()
                if notificationService.isAuthorized {
                    await notificationService.checkAuthorizationStatus()
                }
            } catch {
                print("Failed to authorize notifications: \(error)")
            }
        }
    }
    
    private func loadSettings() {
        if let settings = dataManager.settings {
            primaryReminderEnabled = settings.reminderTime != nil
            if let time = settings.reminderTime {
                primaryReminderTime = time
            }
            
            secondaryReminderEnabled = settings.secondReminderTime != nil
            if let time = settings.secondReminderTime {
                secondaryReminderTime = time
            }
            
            adaptiveEnabled = settings.adaptiveRemindersEnabled
        }
    }
    
    private func handlePrimaryReminderToggle(enabled: Bool) {
        if enabled {
            scheduleReminder(time: primaryReminderTime)
            dataManager.updateSettings { settings in
                settings.reminderTime = primaryReminderTime
            }
        } else {
            notificationService.cancelPrimaryReminder()
            dataManager.updateSettings { settings in
                settings.reminderTime = nil
            }
        }
    }
    
    private func handleSecondaryReminderToggle(enabled: Bool) {
        if enabled {
            scheduleSecondaryReminder(time: secondaryReminderTime)
            dataManager.updateSettings { settings in
                settings.secondReminderTime = secondaryReminderTime
            }
        } else {
            notificationService.cancelSecondaryReminder()
            dataManager.updateSettings { settings in
                settings.secondReminderTime = nil
            }
        }
    }
    
    private func scheduleReminder(time: Date) {
        Task {
            do {
                try await notificationService.scheduleDailyReminder(at: time)
                dataManager.updateSettings { settings in
                    settings.reminderTime = time
                }
            } catch {
                print("Failed to schedule reminder: \(error)")
            }
        }
    }
    
    private func scheduleSecondaryReminder(time: Date) {
        Task {
            do {
                try await notificationService.scheduleSecondaryReminder(at: time)
                dataManager.updateSettings { settings in
                    settings.secondReminderTime = time
                }
            } catch {
                print("Failed to schedule secondary reminder: \(error)")
            }
        }
    }
}

#Preview {
    RemindersView()
        .environmentObject(DataManager(inMemory: true))
}
