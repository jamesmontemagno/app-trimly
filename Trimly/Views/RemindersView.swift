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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TrimlyCardSection(title: "Authorization") {
                        if notificationService.isAuthorized {
                            Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text("Trimly can send you reminders on this device.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Stay on track with gentle nudges. Enable notifications so we can remind you when it counts.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Button("Grant Access") {
                                    requestAuthorization()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    if notificationService.isAuthorized {
                        TrimlyCardSection(title: "Daily Reminder", description: "Choose the best time for Trimly to nudge you to log your weight.") {
                            Toggle("Enable Daily Reminder", isOn: $primaryReminderEnabled)
                                .onChange(of: primaryReminderEnabled) { _, enabled in
                                    handlePrimaryReminderToggle(enabled: enabled)
                                }
                            if primaryReminderEnabled {
                                Divider().padding(.vertical, 8)
                                HStack {
                                    Text("Reminder Time")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    DatePicker("Time", selection: $primaryReminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: primaryReminderTime) { _, newTime in
                                            scheduleReminder(time: newTime)
                                        }
                                }
                            }
                        }

                        if primaryReminderEnabled {
                            TrimlyCardSection(title: "Adaptive Suggestions", description: "Let Trimly learn your habits and recommend smarter reminder times.") {
                                Toggle("Smart Time Suggestions", isOn: $adaptiveEnabled)
                                    .onChange(of: adaptiveEnabled) { _, enabled in
                                        dataManager.updateSettings { settings in
                                            settings.adaptiveRemindersEnabled = enabled
                                        }
                                    }
                                if notificationService.shouldSuggestTimeAdjustment(dataManager: dataManager),
                                   let suggested = notificationService.suggestReminderTime(dataManager: dataManager) {
                                    Divider().padding(.vertical, 8)
                                    Button {
                                        primaryReminderTime = suggested
                                        scheduleReminder(time: suggested)
                                        dataManager.updateSettings { settings in
                                            settings.consecutiveReminderDismissals = 0
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Suggested time")
                                                    .font(.caption)
                                                Text("\(suggested, style: .time)")
                                                    .font(.headline)
                                                Text("Based on your recent logging")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.headline)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        TrimlyCardSection(title: "Secondary Reminder", description: "Optional evening nudge for an extra check-in.") {
                            Toggle("Enable Evening Reminder", isOn: $secondaryReminderEnabled)
                                .onChange(of: secondaryReminderEnabled) { _, enabled in
                                    handleSecondaryReminderToggle(enabled: enabled)
                                }
                            if secondaryReminderEnabled {
                                Divider().padding(.vertical, 8)
                                HStack {
                                    Text("Evening Time")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    DatePicker("Time", selection: $secondaryReminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: secondaryReminderTime) { _, newTime in
                                            scheduleSecondaryReminder(time: newTime)
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
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
        }
        .onAppear {
            loadSettings()
            Task {
                await notificationService.checkAuthorizationStatus()
            }
        }
    }

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
            if let time = settings.reminderTime { primaryReminderTime = time }
            secondaryReminderEnabled = settings.secondReminderTime != nil
            if let time = settings.secondReminderTime { secondaryReminderTime = time }
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
