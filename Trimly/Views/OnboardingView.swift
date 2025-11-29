import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OnboardingView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var currentPage = 0
    @State private var selectedUnit: WeightUnit = .pounds
    @State private var startingWeightText = ""
    @State private var goalWeightText = ""
    @State private var enableReminders = false

    private let onboardingSteps: [(title: LocalizedStringResource, symbol: String)] = [
        (L10n.Onboarding.stepWelcome, "figure.arms.open"),
        (L10n.Onboarding.stepUnits, "scalemass"),
        (L10n.Onboarding.stepStart, "figure.stand"),
        (L10n.Onboarding.stepGoal, "flag.checkered"),
        (L10n.Onboarding.stepReminders, "bell.badge"),
        (L10n.Onboarding.stepFinish, "checkmark.seal")
    ]

    private var bottomContentPadding: CGFloat {
        #if os(iOS)
        return 44
        #else
        return 0
        #endif
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
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
                eulaPage.tag(5)
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
                case 5: eulaPage
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
            Color.clear.frame(height: 12)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.Common.doneButton) {
                    hideKeyboard()
                }
            }
        }
        #endif
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
        VStack(spacing: 6) {
            Image(systemName: step.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(currentPage == index ? Color.white : .primary)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(currentPage == index ? Color.accentColor : Color.accentColor.opacity(0.12))
                )
            Circle()
                .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(step.title))
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(onboardingSteps.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.accentColor : Color.accentColor.opacity(0.2))
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
            }
        }
        .padding(.bottom, 8)
    }

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.mixed.cardio")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 16) {
                Text(L10n.Onboarding.welcomeTitle)
                    .font(.largeTitle.bold())

                Text(L10n.Onboarding.welcomeSubtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            primaryButton(title: L10n.Common.getStartedButton) {
                withAnimation { currentPage = 1 }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var unitSelectionPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "scalemass")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 16) {
                Text(L10n.Onboarding.unitTitle)
                    .font(.largeTitle.bold())

                Text(L10n.Onboarding.unitSubtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Picker(selection: $selectedUnit) {
                Text(L10n.Onboarding.unitOptionPounds).tag(WeightUnit.pounds)
                Text(L10n.Onboarding.unitOptionKilograms).tag(WeightUnit.kilograms)
            } label: {
                Text(L10n.Onboarding.unitPickerLabel)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Spacer()

            primaryButton(title: L10n.Common.continueButton) {
                dataManager.updateSettings { settings in
                    settings.preferredUnit = selectedUnit
                }
                withAnimation { currentPage = 2 }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var startingWeightPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.stand")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 16) {
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

            Spacer()

            VStack(spacing: 12) {
                primaryButton(title: L10n.Common.continueButton) {
                    saveStartingWeight()
                }
                .disabled(startingWeightText.isEmpty)

                secondaryButton(title: L10n.Common.skipButton) {
                    withAnimation { currentPage = 3 }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var goalPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "flag.checkered")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)

            VStack(spacing: 16) {
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

            Spacer()

            VStack(spacing: 12) {
                primaryButton(title: L10n.Common.continueButton) {
                    saveGoal()
                }
                .disabled(goalWeightText.isEmpty)

                secondaryButton(title: L10n.Common.skipButton) {
                    withAnimation { currentPage = 4 }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var remindersPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bell.badge")
                .font(.system(size: 80))
                .foregroundStyle(.orange.gradient)

            VStack(spacing: 16) {
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

            if enableReminders {
                Text(L10n.Onboarding.reminderHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            primaryButton(title: L10n.Common.continueButton) {
                saveReminders()
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var eulaPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.seal")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 16) {
                Text(L10n.Onboarding.eulaTitle)
                    .font(.largeTitle.bold())

                Text(L10n.Onboarding.eulaSubtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Link(destination: URL(string: "https://www.refractored.com/terms")!) {
                    Text(L10n.Onboarding.eulaTerms)
                }
                Link(destination: URL(string: "https://www.refractored.com/about#privacy-policy")!) {
                    Text(L10n.Onboarding.eulaPrivacy)
                }
            }
            .font(.subheadline)

            Spacer()

            primaryButton(title: L10n.Common.acceptButton) {
                completeOnboarding()
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func saveStartingWeight() {
        #if canImport(UIKit)
        hideKeyboard()
        #endif
        guard let weight = Double(startingWeightText), weight > 0 else {
            withAnimation { currentPage = 3 }
            return
        }

        let weightKg = selectedUnit.convertToKg(weight)
        try? dataManager.addWeightEntry(weightKg: weightKg, unit: selectedUnit)
        withAnimation { currentPage = 3 }
    }

    private func saveGoal() {
        #if canImport(UIKit)
        hideKeyboard()
        #endif
        guard let weight = Double(goalWeightText), weight > 0 else {
            withAnimation { currentPage = 4 }
            return
        }

        let weightKg = selectedUnit.convertToKg(weight)
        let currentWeight = dataManager.getCurrentWeight()
        try? dataManager.setGoal(targetWeightKg: weightKg, startingWeightKg: currentWeight)
        withAnimation { currentPage = 4 }
    }

    private func saveReminders() {
        if enableReminders {
            dataManager.updateSettings { settings in
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = 9
                components.minute = 0
                settings.reminderTime = calendar.date(from: components)
            }
        }
        withAnimation { currentPage = 5 }
    }

    private func completeOnboarding() {
        dataManager.updateSettings { settings in
            settings.hasCompletedOnboarding = true
            settings.eulaAcceptedDate = Date()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager(inMemory: true))
}

#if canImport(UIKit)
private extension OnboardingView {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
