import SwiftUI
import Combine

struct RemindersView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var deviceSettings: DeviceSettingsStore
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
                                        deviceSettings.updateReminders { reminders in
                                            reminders.adaptiveEnabled = enabled
                                        }
                                    }
                                if notificationService.shouldSuggestTimeAdjustment(reminders: deviceSettings.reminders),
                                   let suggested = notificationService.suggestReminderTime(dataManager: dataManager) {
                                    Divider().padding(.vertical, 8)
                                    Button {
                                        primaryReminderTime = suggested
                                        scheduleReminder(time: suggested)
                                        deviceSettings.updateReminders { reminders in
                                            reminders.consecutiveDismissals = 0
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
        .onReceive(deviceSettings.remindersPublisher) { reminders in
            syncState(with: reminders)
        }
    }

    private func requestAuthorization() {
        Task {
            do {
                try await notificationService.requestAuthorization()
                if notificationService.isAuthorized {
                    await notificationService.checkAuthorizationStatus()
                    await notificationService.ensureReminderSchedule(reminders: deviceSettings.reminders)
                }
            } catch {
                print("Failed to authorize notifications: \(error)")
            }
        }
    }

    private func loadSettings() {
        syncState(with: deviceSettings.reminders)
    }

    private func syncState(with reminders: DeviceSettingsStore.RemindersSettings) {
        primaryReminderEnabled = reminders.primaryTime != nil
        if let time = reminders.primaryTime { primaryReminderTime = time }
        secondaryReminderEnabled = reminders.secondaryTime != nil
        if let time = reminders.secondaryTime { secondaryReminderTime = time }
        adaptiveEnabled = reminders.adaptiveEnabled
    }

    private func handlePrimaryReminderToggle(enabled: Bool) {
        if enabled {
            scheduleReminder(time: primaryReminderTime)
        } else {
            notificationService.cancelPrimaryReminder()
            deviceSettings.updateReminders { reminders in
                reminders.primaryTime = nil
            }
        }
    }

    private func handleSecondaryReminderToggle(enabled: Bool) {
        if enabled {
            scheduleSecondaryReminder(time: secondaryReminderTime)
        } else {
            notificationService.cancelSecondaryReminder()
            deviceSettings.updateReminders { reminders in
                reminders.secondaryTime = nil
            }
        }
    }

    private func scheduleReminder(time: Date) {
        Task {
            do {
                try await notificationService.scheduleDailyReminder(at: time)
                deviceSettings.updateReminders { reminders in
                    reminders.primaryTime = time
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
                deviceSettings.updateReminders { reminders in
                    reminders.secondaryTime = time
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
    .environmentObject(DeviceSettingsStore())
}
