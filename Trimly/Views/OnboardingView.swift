import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var deviceSettings: DeviceSettingsStore
    @State private var currentPage = 0
    @State private var selectedUnit: WeightUnit = .pounds
    @State private var startingWeightText = ""
    @State private var goalWeightText = ""
    @State private var enableReminders = false
    @State private var enableiCloudSync = true
    @State private var startingWeightError: LocalizedStringResource?
    @State private var goalWeightError: LocalizedStringResource?
    @State private var showIncompleteAlert = false
    @State private var showInitialCloudSyncSuccess = false
    @State private var hasWaitedForInitialCloudSync = false
    @State private var didScheduleInitialCloudSyncWait = false

    private let onboardingSteps: [(title: LocalizedStringResource, symbol: String)] = [
        (L10n.Onboarding.stepWelcome, "figure.arms.open"),
        (L10n.Onboarding.stepUnits, "scalemass"),
        (L10n.Onboarding.stepStart, "figure.stand"),
        (L10n.Onboarding.stepGoal, "flag.checkered"),
        (L10n.Onboarding.stepReminders, "bell.badge"),
        (L10n.Onboarding.stepCloudSync, "icloud"),
        (L10n.Onboarding.stepFinish, "checkmark.seal")
    ]

    private var bottomContentPadding: CGFloat {
        #if os(iOS)
        return 24
        #else
        return 0
        #endif
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(Array(onboardingSteps.enumerated()), id: \.offset) { index, step in
                    stepIcon(step, index: index)
                }
            }
            .padding(.horizontal)

            #if os(iOS)
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                unitSelectionPage.tag(1)
                startingWeightPage.tag(2)
                goalPage.tag(3)
                remindersPage.tag(4)
                iCloudSyncPage.tag(5)
                eulaPage.tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            
            ZStack {
                switch currentPage {
                case 0: welcomePage
                case 1: unitSelectionPage
                case 2: startingWeightPage
                case 3: goalPage
                case 4: remindersPage
                case 5: iCloudSyncPage
                case 6: eulaPage
                default: EmptyView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut, value: currentPage)
            #endif

            pageIndicator
        }
        .padding(.bottom, bottomContentPadding)
        #if os(iOS)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.Common.doneButton) {
                    hideKeyboard()
                }
			.buttonStyle(.borderedProminent)
			.tint(.accentColor)
            }
        }
        #endif
        .alert(L10n.Common.errorTitle, isPresented: $showIncompleteAlert) {
            Button(L10n.Common.okButton, role: .cancel) { }
        } message: {
            Text(L10n.Onboarding.incompleteError)
        }
        .onAppear {
            dataManager.refreshInitialCloudSyncState()
            if didScheduleInitialCloudSyncWait == false {
                didScheduleInitialCloudSyncWait = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    hasWaitedForInitialCloudSync = true
                }
            }
        }
        .onChange(of: dataManager.hasFinishedInitialCloudSync) { _, finished in
            guard finished, dataManager.hasAnyEntries() else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showInitialCloudSyncSuccess = true
            }
            dataManager.markInitialCloudSyncSuccessShown()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showInitialCloudSyncSuccess = false
                }
            }
        }
    }

    private func primaryButton(title: LocalizedStringResource, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func secondaryButton(title: LocalizedStringResource, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func stepIcon(_ step: (title: LocalizedStringResource, symbol: String), index: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: step.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(currentPage == index ? Color.white : .primary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(currentPage == index ? Color.accentColor : Color.accentColor.opacity(0.12))
                )
            Circle()
                .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.title))
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(onboardingSteps.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.accentColor : Color.accentColor.opacity(0.2))
                    .frame(width: index == currentPage ? 16 : 6, height: 6)
            }
        }
        .padding(.bottom, 4)
    }

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                if shouldShowInitialCloudSyncBanner {
                    initialCloudSyncStatus
                }

                Image(systemName: "figure.mixed.cardio")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.welcomeTitle)
                        .font(.largeTitle.bold())

                    Text(L10n.Onboarding.welcomeSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer(minLength: 16)

                primaryButton(title: L10n.Common.getStartedButton) {
                    withAnimation { currentPage = 1 }
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }

    private var shouldShowInitialCloudSyncBanner: Bool {
        showInitialCloudSyncSuccess || !dataManager.hasFinishedInitialCloudSync || showNoCloudDataBanner
    }

    private var showNoCloudDataBanner: Bool {
        dataManager.hasFinishedInitialCloudSync && !dataManager.hasAnyEntries() && hasWaitedForInitialCloudSync
    }

    @ViewBuilder
    private var initialCloudSyncStatus: some View {
        if showInitialCloudSyncSuccess {
            Label {
                Text(L10n.Onboarding.cloudSyncFound)
                    .font(.footnote)
                    .foregroundStyle(.green)
            } icon: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.scale.combined(with: .opacity))
        } else if showNoCloudDataBanner {
            Label {
                Text(L10n.Onboarding.cloudSyncNoData)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.opacity)
        } else {
            VStack(spacing: 8) {
                ProgressView()
                    .tint(.accentColor)
                Text(hasWaitedForInitialCloudSync ? L10n.Onboarding.cloudSyncStillChecking : L10n.Onboarding.cloudSyncChecking)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.opacity)
        }
    }

    private var unitSelectionPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                Image(systemName: "scalemass")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.unitTitle)
                        .font(.largeTitle.bold())

                    Text(L10n.Onboarding.unitSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Picker(selection: $selectedUnit) {
                    Text(L10n.Onboarding.unitOptionPounds).tag(WeightUnit.pounds)
                    Text(L10n.Onboarding.unitOptionKilograms).tag(WeightUnit.kilograms)
                    Text(L10n.Onboarding.unitOptionStones).tag(WeightUnit.stones)
                } label: {
                    Text(L10n.Onboarding.unitPickerLabel)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Spacer(minLength: 16)

                primaryButton(title: L10n.Common.continueButton) {
                    dataManager.updateSettings { settings in
                        settings.preferredUnit = selectedUnit
                    }
                    withAnimation { currentPage = 2 }
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }

    private var startingWeightPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                Image(systemName: "figure.stand")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.startTitle)
                        .font(.largeTitle.bold())

                    Text(L10n.Onboarding.startSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    TextField("", text: $startingWeightText, prompt: Text(L10n.Onboarding.startPlaceholder))
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .font(.system(.title).bold())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                        .accessibilityLabel(Text(L10n.Onboarding.startFieldLabel))
                        .onChange(of: startingWeightText) { _, _ in
                            startingWeightError = nil
                        }

                    Text(selectedUnit.symbol)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    if !startingWeightText.isEmpty {
                        Button(action: saveStartingWeight) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let error = startingWeightError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 16)

                primaryButton(title: L10n.Common.continueButton) {
                    saveStartingWeight()
                }
                .disabled(startingWeightText.isEmpty)
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }

    private var goalPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                Image(systemName: "flag.checkered")
                    .font(.system(size: 64))
                    .foregroundStyle(.green.gradient)

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.goalTitle)
                        .font(.largeTitle.bold())

                    Text(L10n.Onboarding.goalSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    TextField("", text: $goalWeightText, prompt: Text(L10n.Onboarding.goalPlaceholder))
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .font(.system(.title).bold())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                        .accessibilityLabel(Text(L10n.Onboarding.goalFieldLabel))
                        .onChange(of: goalWeightText) { _, _ in
                            goalWeightError = nil
                        }

                    Text(selectedUnit.symbol)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    if !goalWeightText.isEmpty {
                        Button(action: saveGoal) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let error = goalWeightError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 16)

                primaryButton(title: L10n.Common.continueButton) {
                    saveGoal()
                }
                .disabled(goalWeightText.isEmpty)
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }

    private var remindersPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                Image(systemName: "bell.badge")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange.gradient)

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.remindersTitle)
                        .font(.largeTitle.bold())

                    Text(L10n.Onboarding.remindersSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Toggle(L10n.Onboarding.reminderToggle, isOn: $enableReminders)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .onChange(of: enableReminders) { _, enabled in
                        if enabled {
                            requestNotificationAuthorization()
                        }
                    }

                if enableReminders {
                    Text(L10n.Onboarding.reminderHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                primaryButton(title: L10n.Common.continueButton) {
                    saveReminders()
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }
    
    private var iCloudSyncPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                Image(systemName: "icloud")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.iCloudSyncTitle)
                        .font(.largeTitle.bold())

                    Text(L10n.Onboarding.iCloudSyncSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Toggle(L10n.Onboarding.iCloudSyncToggle, isOn: $enableiCloudSync)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Onboarding.iCloudSyncDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label(L10n.Onboarding.iCloudSyncBenefit1, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                        Label(L10n.Onboarding.iCloudSyncBenefit2, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                        Label(L10n.Onboarding.iCloudSyncBenefit3, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer(minLength: 16)

                primaryButton(title: L10n.Common.continueButton) {
                    saveiCloudSync()
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }

    private var eulaPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                Image(systemName: "checkmark.seal")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 12) {
                    Text(L10n.Onboarding.eulaTitle)
                        .font(.largeTitle.bold())

                    Text(L10n.Onboarding.eulaSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Link(destination: LegalLinks.termsOfService) {
                        Text(L10n.Onboarding.eulaTerms)
                    }
                    Link(destination: LegalLinks.privacyPolicy) {
                        Text(L10n.Onboarding.eulaPrivacy)
                    }
                }
                .font(.subheadline)

                Spacer(minLength: 16)

                primaryButton(title: L10n.Common.acceptButton) {
                    completeOnboarding()
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 0)
        }
    }

    private func saveStartingWeight() {
        #if canImport(UIKit)
        hideKeyboard()
        #endif
        guard let weight = Double(startingWeightText), weight > 0 else {
            startingWeightError = L10n.Onboarding.startValidation
            return
        }

        startingWeightError = nil
        goalWeightError = nil
        let weightKg = selectedUnit.convertToKg(weight)
        try? dataManager.addWeightEntry(weightKg: weightKg, unit: selectedUnit)
        withAnimation { currentPage = 3 }
    }

    private func saveGoal() {
        #if canImport(UIKit)
        hideKeyboard()
        #endif
        guard let weight = Double(goalWeightText), weight > 0 else {
            goalWeightError = L10n.Onboarding.goalValidation
            return
        }

        guard let currentWeight = dataManager.getCurrentWeight() else {
            goalWeightError = L10n.Onboarding.goalNeedsStart
            withAnimation { currentPage = 2 }
            return
        }

        goalWeightError = nil
        let weightKg = selectedUnit.convertToKg(weight)
        do {
            try dataManager.setGoal(targetWeightKg: weightKg, startingWeightKg: currentWeight)
            withAnimation { currentPage = 4 }
        } catch _ as DataManagerError {
            goalWeightError = L10n.Onboarding.goalNeedsStart
            withAnimation { currentPage = 2 }
        } catch {
            goalWeightError = L10n.Onboarding.goalValidation
        }
    }

    private func saveReminders() {
        if enableReminders {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            if let reminderTime = calendar.date(from: components) {
                // Schedule notifications and save settings
                // This is done in a Task to properly await authorization completion
                Task {
                    // First, ensure we have the latest authorization status
                    await dataManager.checkNotificationAuthorizationStatus()
                    
                    if dataManager.isNotificationAuthorized {
                        do {
                            try await dataManager.scheduleDailyReminder(at: reminderTime)
                        } catch {
                            // If scheduling fails, still save the preference
                            // TrimlyApp will retry on next launch via refreshReminderSchedule
                            deviceSettings.updateReminders { reminders in
                                reminders.primaryTime = reminderTime
                            }
                            print("Failed to schedule reminder during onboarding: \(error)")
                        }
                    } else {
                        // User enabled reminders but auth is pending or denied
                        // Save the preference anyway - TrimlyApp will schedule when auth is granted
                        deviceSettings.updateReminders { reminders in
                            reminders.primaryTime = reminderTime
                        }
                    }
                }
            }
        }
        withAnimation { currentPage = 5 }
    }
    
    private func saveiCloudSync() {
        deviceSettings.updateCloudSync { settings in
            settings.iCloudSyncEnabled = enableiCloudSync
        }
        withAnimation { currentPage = 6 }
    }

    private func completeOnboarding() {
        // Validate that starting weight and goal have been set
        guard dataManager.getCurrentWeight() != nil, dataManager.fetchActiveGoal() != nil else {
            showIncompleteAlert = true
            return
        }
        
        dataManager.updateSettings { settings in
            settings.hasCompletedOnboarding = true
            settings.eulaAcceptedDate = Date()
        }
    }

    private func requestNotificationAuthorization() {
        Task {
            do {
                try await dataManager.requestNotificationAuthorization()
            } catch {
                // If authorization fails or is denied, we continue silently.
                // The user can enable notifications later in Settings.
                print("Failed to authorize notifications during onboarding: \(error)")
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager(inMemory: true))
    .environmentObject(DeviceSettingsStore())
}

#if canImport(UIKit)
private extension OnboardingView {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
