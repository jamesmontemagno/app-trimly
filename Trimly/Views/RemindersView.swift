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
                    TrimlyCardSection(title: String(localized: L10n.Reminders.authorizationTitle)) {
                        if notificationService.isAuthorized {
                            Label(String(localized: L10n.Reminders.notificationsEnabled), systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text(L10n.Reminders.authorizedDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.Reminders.enablePrompt)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Button(String(localized: L10n.Reminders.grantAccess)) {
                                    requestAuthorization()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    if notificationService.isAuthorized {
                        TrimlyCardSection(title: String(localized: L10n.Reminders.dailyTitle), description: String(localized: L10n.Reminders.dailyDescription)) {
                            Toggle(L10n.Reminders.dailyToggle, isOn: $primaryReminderEnabled)
                                .onChange(of: primaryReminderEnabled) { _, enabled in
                                    handlePrimaryReminderToggle(enabled: enabled)
                                }
                            if primaryReminderEnabled {
                                Divider().padding(.vertical, 8)
                                HStack {
                                    Text(L10n.Reminders.reminderTimeLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    DatePicker(String(localized: L10n.Reminders.reminderTimeLabel), selection: $primaryReminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: primaryReminderTime) { _, newTime in
                                            scheduleReminder(time: newTime)
                                        }
                                }
                            }
                        }

                        if primaryReminderEnabled {
                            TrimlyCardSection(title: String(localized: L10n.Reminders.adaptiveTitle), description: String(localized: L10n.Reminders.adaptiveDescription)) {
                                Toggle(L10n.Reminders.smartToggle, isOn: $adaptiveEnabled)
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
                                                Text(L10n.Reminders.suggestionTitle)
                                                    .font(.caption)
                                                Text("\(suggested, style: .time)")
                                                    .font(.headline)
                                                Text(L10n.Reminders.suggestionHint)
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

                        TrimlyCardSection(title: String(localized: L10n.Reminders.secondaryTitle), description: String(localized: L10n.Reminders.secondaryDescription)) {
                            Toggle(L10n.Reminders.secondaryToggle, isOn: $secondaryReminderEnabled)
                                .onChange(of: secondaryReminderEnabled) { _, enabled in
                                    handleSecondaryReminderToggle(enabled: enabled)
                                }
                            if secondaryReminderEnabled {
                                Divider().padding(.vertical, 8)
                                HStack {
                                    Text(L10n.Reminders.eveningLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    DatePicker(String(localized: L10n.Reminders.eveningLabel), selection: $secondaryReminderTime, displayedComponents: .hourAndMinute)
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
            .navigationTitle(Text(L10n.Reminders.navigationTitle))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.doneButton)) {
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
