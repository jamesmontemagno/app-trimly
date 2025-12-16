import SwiftUI
import Combine

struct RemindersView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var deviceSettings: DeviceSettingsStore
    @Environment(\.dismiss) var dismiss

    @State private var primaryReminderEnabled = false
    @State private var primaryReminderTime = Date()
    @State private var secondaryReminderEnabled = false
    @State private var secondaryReminderTime = Date()
    @State private var adaptiveEnabled = true
    @State private var hasChanges = false
    @State private var isAuthorized = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TrimlyCardSection(title: String(localized: L10n.Reminders.authorizationTitle)) {
                        if isAuthorized {
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

                    if isAuthorized {
                        TrimlyCardSection(title: String(localized: L10n.Reminders.dailyTitle), description: String(localized: L10n.Reminders.dailyDescription)) {
                            Toggle(L10n.Reminders.dailyToggle, isOn: $primaryReminderEnabled)
                                .onChange(of: primaryReminderEnabled) { _, _ in
                                    hasChanges = true
                                }
                            if primaryReminderEnabled {
                                Divider().padding(.vertical, 8)
                                HStack {
                                    Text(L10n.Reminders.reminderTimeLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    DatePicker(String(localized: L10n.Reminders.reminderTimeLabel), selection: $primaryReminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: primaryReminderTime) { _, _ in
                                            hasChanges = true
                                        }
                                }
                            }
                        }

                        if primaryReminderEnabled {
                            TrimlyCardSection(title: String(localized: L10n.Reminders.adaptiveTitle), description: String(localized: L10n.Reminders.adaptiveDescription)) {
                                Toggle(L10n.Reminders.smartToggle, isOn: $adaptiveEnabled)
                                    .onChange(of: adaptiveEnabled) { _, _ in
                                        hasChanges = true
                                    }
                                if dataManager.shouldSuggestTimeAdjustment(),
                                   let suggested = dataManager.suggestReminderTime() {
                                    Divider().padding(.vertical, 8)
                                    Button {
                                        primaryReminderTime = suggested
                                        hasChanges = true
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
                                .onChange(of: secondaryReminderEnabled) { _, _ in
                                    hasChanges = true
                                }
                            if secondaryReminderEnabled {
                                Divider().padding(.vertical, 8)
                                HStack {
                                    Text(L10n.Reminders.eveningLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    DatePicker(String(localized: L10n.Reminders.eveningLabel), selection: $secondaryReminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: secondaryReminderTime) { _, _ in
                                            hasChanges = true
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
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: L10n.Common.cancelButton)) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.saveButton)) {
                        saveChanges()
                    }
				.buttonStyle(.borderedProminent)
				.tint(.accentColor)
                    .disabled(!hasChanges)
                }
            }
        }
        .onAppear {
            loadSettings()
            Task {
                await dataManager.checkNotificationAuthorizationStatus()
                isAuthorized = dataManager.isNotificationAuthorized
            }
        }
    }

    private func saveChanges() {
        Task {
            // Save primary reminder
            if primaryReminderEnabled {
                do {
                    try await dataManager.scheduleDailyReminder(at: primaryReminderTime)
                } catch {
                    print("Failed to schedule primary reminder: \(error)")
                }
            } else {
                dataManager.cancelPrimaryReminder()
            }
            
            // Save secondary reminder
            if secondaryReminderEnabled {
                do {
                    try await dataManager.scheduleSecondaryReminder(at: secondaryReminderTime)
                } catch {
                    print("Failed to schedule secondary reminder: \(error)")
                }
            } else {
                dataManager.cancelSecondaryReminder()
            }
            
            // Save adaptive setting
            deviceSettings.updateReminders { reminders in
                reminders.adaptiveEnabled = adaptiveEnabled
            }
            
            // Reset consecutive dismissals if user accepted a suggestion
            if let suggested = dataManager.suggestReminderTime(),
               primaryReminderEnabled && abs(primaryReminderTime.timeIntervalSince(suggested)) < 60 {
                deviceSettings.updateReminders { reminders in
                    reminders.consecutiveDismissals = 0
                }
            }
            
            hasChanges = false
            dismiss()
        }
    }

    private func requestAuthorization() {
        Task {
            do {
                try await dataManager.requestNotificationAuthorization()
                await dataManager.checkNotificationAuthorizationStatus()
                isAuthorized = dataManager.isNotificationAuthorized
                if isAuthorized {
                    await dataManager.refreshReminderSchedule()
                }
            } catch {
                print("Failed to authorize notifications: \(error)")
            }
        }
    }

    private func loadSettings() {
        syncState(with: deviceSettings.reminders)
        isAuthorized = dataManager.isNotificationAuthorized
    }

    private func syncState(with reminders: DeviceSettingsStore.RemindersSettings) {
        primaryReminderEnabled = reminders.primaryTime != nil
        if let time = reminders.primaryTime { primaryReminderTime = time }
        secondaryReminderEnabled = reminders.secondaryTime != nil
        if let time = reminders.secondaryTime { secondaryReminderTime = time }
        adaptiveEnabled = reminders.adaptiveEnabled
        hasChanges = false
    }
}

#Preview {
    RemindersView()
        .environmentObject(DataManager(inMemory: true))
    .environmentObject(DeviceSettingsStore())
}
