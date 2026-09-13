import SwiftUI
import Combine
import UserNotifications
#if os(iOS)
import UIKit
#endif

struct RemindersView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var deviceSettings: DeviceSettingsStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var primaryReminderEnabled = false
    @State private var primaryReminderTime = Date()
    @State private var secondaryReminderEnabled = false
    @State private var secondaryReminderTime = Date()
    @State private var adaptiveEnabled = true
    @State private var hasChanges = false
    @State private var isAuthorized = false
    @State private var authorizationStatus = UNAuthorizationStatus.notDetermined
    @State private var nextReminderDate: Date?
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ReminderAuthorizationSection(
                        status: authorizationStatus, isAuthorized: isAuthorized,
                        nextDate: nextReminderDate, requestAccess: requestAuthorization,
                        openSettings: openNotificationSettings
                    )

                    if isAuthorized {
                        WeighCardSection(title: String(localized: L10n.Reminders.dailyTitle), description: String(localized: L10n.Reminders.dailyDescription)) {
                            Toggle(String(localized: L10n.Reminders.dailyToggle), isOn: $primaryReminderEnabled)
                                .accessibilityLabel(Text(L10n.Reminders.dailyToggle))
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
                                        .accessibilityLabel(Text(L10n.Reminders.reminderTimeLabel))
                                        .onChange(of: primaryReminderTime) { _, _ in
                                            hasChanges = true
                                        }
                                }
                            }
                        }

                        if primaryReminderEnabled {
                            WeighCardSection(title: String(localized: L10n.Reminders.adaptiveTitle), description: String(localized: L10n.Reminders.adaptiveDescription)) {
                                Toggle(String(localized: L10n.Reminders.smartToggle), isOn: $adaptiveEnabled)
                                    .accessibilityLabel(Text(L10n.Reminders.smartToggle))
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
                                    .accessibilityLabel(Text(L10n.Reminders.suggestionTitle))
                                    .accessibilityHint(Text(L10n.Reminders.suggestionHint))
                                }
                            }
                        }

                        WeighCardSection(title: String(localized: L10n.Reminders.secondaryTitle), description: String(localized: L10n.Reminders.secondaryDescription)) {
                            Toggle(String(localized: L10n.Reminders.secondaryToggle), isOn: $secondaryReminderEnabled)
                                .accessibilityLabel(Text(L10n.Reminders.secondaryToggle))
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
                                        .accessibilityLabel(Text(L10n.Reminders.eveningLabel))
                                        .onChange(of: secondaryReminderTime) { _, _ in
                                            hasChanges = true
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .disabled(isSaving)
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
                    .interactiveDismissDisabled(isSaving)
                    .accessibilityLabel(Text(L10n.Common.cancelButton))
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.saveButton)) {
                        saveChanges()
                    }
				.buttonStyle(.borderedProminent)
				.tint(.accentColor)
                    .accessibilityLabel(Text(L10n.Common.saveButton))
                    .disabled(!hasChanges || isSaving)
                }
            }
        }
        .task {
            loadSettings()
            await refreshStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshStatus() } }
        }
        .portabilityError($errorMessage)
    }

    private func saveChanges() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                if primaryReminderEnabled {
                    try await dataManager.scheduleDailyReminder(at: primaryReminderTime)
                } else {
                    dataManager.cancelPrimaryReminder()
                }
                if secondaryReminderEnabled {
                    try await dataManager.scheduleSecondaryReminder(at: secondaryReminderTime)
                } else {
                    dataManager.cancelSecondaryReminder()
                }
                deviceSettings.updateReminders { $0.adaptiveEnabled = adaptiveEnabled }
                if let suggested = dataManager.suggestReminderTime(),
                   primaryReminderEnabled && abs(primaryReminderTime.timeIntervalSince(suggested)) < 60 {
                    deviceSettings.updateReminders { $0.consecutiveDismissals = 0 }
                }
                await dataManager.refreshReminderSchedule()
                await refreshStatus()
                let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
                if (primaryReminderEnabled && !pending.contains { $0.identifier.hasPrefix("trimly.reminder.primary") })
                    || (secondaryReminderEnabled && !pending.contains { $0.identifier.hasPrefix("trimly.reminder.secondary") }) {
                    errorMessage = String(localized: L10n.Portability.reminderScheduleFailed)
                    return
                }
                hasChanges = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                await refreshStatus()
            }
        }
    }

    private func requestAuthorization() {
        Task {
            do {
                try await dataManager.requestNotificationAuthorization()
                await refreshStatus()
                if isAuthorized {
                    await dataManager.refreshReminderSchedule()
                    await refreshStatus()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshStatus() async {
        await dataManager.checkNotificationAuthorizationStatus()
        isAuthorized = dataManager.isNotificationAuthorized
        let center = UNUserNotificationCenter.current()
        authorizationStatus = await center.notificationSettings().authorizationStatus
        let pending = await center.pendingNotificationRequests()
        nextReminderDate = pending
            .filter { $0.identifier.hasPrefix("trimly.reminder.") }
            .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
            .filter { $0 > Date() }
            .min()
    }

    private func openNotificationSettings() {
        #if os(iOS)
        let address = UIApplication.openNotificationSettingsURLString
        #else
        let address = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        #endif
        if let url = URL(string: address) { openURL(url) }
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

private struct ReminderAuthorizationSection: View {
    let status: UNAuthorizationStatus
    let isAuthorized: Bool
    let nextDate: Date?
    let requestAccess: () -> Void
    let openSettings: () -> Void

    var body: some View {
        WeighCardSection(title: String(localized: L10n.Reminders.authorizationTitle)) {
            Text(authorizationLabel).font(.headline)
            if let nextDate {
                LabeledContent {
                    Text(nextDate, format: .dateTime.weekday().month().day().hour().minute())
                } label: {
                    Text(L10n.Portability.nextReminder)
                }
                .accessibilityElement(children: .combine)
            } else {
                Text(L10n.Portability.noNextReminder).font(.subheadline)
            }
            Text(L10n.Portability.deviceLocal).font(.caption).foregroundStyle(.secondary)
            if isAuthorized {
                Label(String(localized: L10n.Reminders.notificationsEnabled), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                Text(L10n.Reminders.authorizedDescription).font(.caption).foregroundStyle(.secondary)
            } else {
                Text(L10n.Reminders.enablePrompt).font(.callout).foregroundStyle(.secondary)
                if status == .denied {
                    Button(String(localized: L10n.Portability.openNotificationSettings), action: openSettings)
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel(Text(L10n.Portability.openNotificationSettings))
                } else {
                    Button(String(localized: L10n.Reminders.grantAccess), action: requestAccess)
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel(Text(L10n.Reminders.grantAccess))
                }
            }
        }
    }

    private var authorizationLabel: LocalizedStringResource {
        switch status {
        case .authorized: return L10n.Portability.notificationAuthorized
        case .denied: return L10n.Portability.notificationDenied
        case .notDetermined: return L10n.Portability.notificationNotRequested
        case .provisional: return L10n.Portability.notificationLimited
        #if os(iOS)
        case .ephemeral: return L10n.Portability.notificationLimited
        #endif
        @unknown default: return L10n.Portability.notificationUnknown
        }
    }
}

#Preview {
    RemindersView()
        .environmentObject(DataManager(inMemory: true))
    .environmentObject(DeviceSettingsStore())
}
