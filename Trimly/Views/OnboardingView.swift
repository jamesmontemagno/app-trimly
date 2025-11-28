//
//  OnboardingView.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct OnboardingView: View {
	@EnvironmentObject var dataManager: DataManager
	@State private var currentPage = 0
	@State private var selectedUnit: WeightUnit = .pounds
	@State private var startingWeightText = ""
	@State private var goalWeightText = ""
	@State private var enableReminders = false
	private let onboardingSteps: [(title: String, symbol: String)] = [
		("Welcome", "figure.arms.open"),
		("Units", "scalemass"),
		("Start", "figure.stand"),
		("Goal", "flag.checkered"),
		("Reminders", "bell.badge"),
		("Finish", "checkmark.seal")
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
			TabView(selection: $currentPage) {
				welcomePage.tag(0)
				unitSelectionPage.tag(1)
				startingWeightPage.tag(2)
				goalPage.tag(3)
				remindersPage.tag(4)
				eulaPage.tag(5)
			}
#endif

			pageIndicator
		}
		.padding(.bottom, bottomContentPadding)
		#if os(iOS)
		.safeAreaInset(edge: .bottom) {
			Color.clear.frame(height: 12)
		}
		#endif
	}

	private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
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

	private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Text(title)
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
	}

	private func stepIcon(_ step: (title: String, symbol: String), index: Int) -> some View {
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
		.accessibilityLabel(step.title)
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
				Text("Welcome to Trimly")
					.font(.largeTitle.bold())
                
				Text("Your supportive companion for mindful weight tracking")
					.font(.title3)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal)
			}
            
			Spacer()
            
			primaryButton(title: "Get Started") {
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
				Text("Choose Your Unit")
					.font(.largeTitle.bold())
                
				Text("Select your preferred weight unit")
					.font(.title3)
					.foregroundStyle(.secondary)
			}
            
			Picker("Unit", selection: $selectedUnit) {
				Text("Pounds (lb)").tag(WeightUnit.pounds)
				Text("Kilograms (kg)").tag(WeightUnit.kilograms)
			}
			.pickerStyle(.segmented)
			.padding(.horizontal)
            
			Spacer()
            
			primaryButton(title: "Continue") {
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
				Text("Starting Weight")
					.font(.largeTitle.bold())
                
				Text("What's your current weight?")
					.font(.title3)
					.foregroundStyle(.secondary)
			}
            
			HStack {
				TextField("Weight", text: $startingWeightText)
					#if os(iOS)
					.keyboardType(.decimalPad)
					#endif
					.font(.system(.title).bold())
					.multilineTextAlignment(.center)
					.frame(maxWidth: 200)
                
				Text(selectedUnit.symbol)
					.font(.title3)
					.foregroundStyle(.secondary)
			}
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 12))
            
			Spacer()
            
			VStack(spacing: 12) {
				primaryButton(title: "Continue") {
					saveStartingWeight()
				}
				.disabled(startingWeightText.isEmpty)
                
				secondaryButton(title: "Skip for now") {
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
				Text("Set Your Goal")
					.font(.largeTitle.bold())
                
				Text("What's your target weight?")
					.font(.title3)
					.foregroundStyle(.secondary)
			}
            
			HStack {
				TextField("Goal", text: $goalWeightText)
					#if os(iOS)
					.keyboardType(.decimalPad)
					#endif
					.font(.system(.title).bold())
					.multilineTextAlignment(.center)
					.frame(maxWidth: 200)
                
				Text(selectedUnit.symbol)
					.font(.title3)
					.foregroundStyle(.secondary)
			}
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 12))
            
			Spacer()
            
			VStack(spacing: 12) {
				primaryButton(title: "Continue") {
					saveGoal()
				}
				.disabled(goalWeightText.isEmpty)
                
				secondaryButton(title: "Skip for now") {
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
				Text("Daily Reminders")
					.font(.largeTitle.bold())
                
				Text("Stay consistent with gentle reminders")
					.font(.title3)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
            
			Toggle("Enable Daily Reminder", isOn: $enableReminders)
				.padding()
				.background(.thinMaterial)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.padding(.horizontal)
            
			if enableReminders {
				Text("We'll remind you at 9:00 AM each day")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
            
			Spacer()
            
			primaryButton(title: "Continue") {
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
				Text("Terms & Privacy")
					.font(.largeTitle.bold())
                
				Text("By continuing, you agree to our Terms of Service and Privacy Policy")
					.font(.title3)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal)
			}
            
			VStack(spacing: 12) {
				Link("Read Terms of Service", destination: URL(string: "https://example.com/terms")!)
				Link("Read Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
			}
			.font(.subheadline)
            
			Spacer()
            
			primaryButton(title: "Accept & Continue") {
				completeOnboarding()
			}
			.padding(.horizontal)
		}
		.padding()
	}
    
	private func saveStartingWeight() {
		guard let weight = Double(startingWeightText), weight > 0 else {
			withAnimation { currentPage = 3 }
			return
		}
        
		let weightKg = selectedUnit.convertToKg(weight)
		try? dataManager.addWeightEntry(weightKg: weightKg, unit: selectedUnit)
		withAnimation { currentPage = 3 }
	}
    
	private func saveGoal() {
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
