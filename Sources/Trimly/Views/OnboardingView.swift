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
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Welcome Page
            welcomePage
                .tag(0)
            
            // Unit Selection Page
            unitSelectionPage
                .tag(1)
            
            // Starting Weight Page
            startingWeightPage
                .tag(2)
            
            // Goal Page
            goalPage
                .tag(3)
            
            // Reminders Page
            remindersPage
                .tag(4)
            
            // EULA Page
            eulaPage
                .tag(5)
        }
        #if os(iOS)
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        #endif
    }
    
    // MARK: - Welcome Page
    
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
            
            Button {
                withAnimation {
                    currentPage = 1
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Unit Selection Page
    
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
            
            Button {
                dataManager.updateSettings { settings in
                    settings.preferredUnit = selectedUnit
                }
                withAnimation {
                    currentPage = 2
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Starting Weight Page
    
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
                Button {
                    saveStartingWeight()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(startingWeightText.isEmpty)
                
                Button("Skip for now") {
                    withAnimation {
                        currentPage = 3
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Goal Page
    
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
                Button {
                    saveGoal()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(goalWeightText.isEmpty)
                
                Button("Skip for now") {
                    withAnimation {
                        currentPage = 4
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Reminders Page
    
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
            
            Button {
                saveReminders()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - EULA Page
    
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
            
            Button {
                completeOnboarding()
            } label: {
                Text("Accept & Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func saveStartingWeight() {
        guard let weight = Double(startingWeightText),
              weight > 0 else {
            withAnimation {
                currentPage = 3
            }
            return
        }
        
        let weightKg = selectedUnit.convertToKg(weight)
        
        try? dataManager.addWeightEntry(
            weightKg: weightKg,
            unit: selectedUnit
        )
        
        withAnimation {
            currentPage = 3
        }
    }
    
    private func saveGoal() {
        guard let weight = Double(goalWeightText),
              weight > 0 else {
            withAnimation {
                currentPage = 4
            }
            return
        }
        
        let weightKg = selectedUnit.convertToKg(weight)
        let currentWeight = dataManager.getCurrentWeight()
        
        try? dataManager.setGoal(
            targetWeightKg: weightKg,
            startingWeightKg: currentWeight
        )
        
        withAnimation {
            currentPage = 4
        }
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
        
        withAnimation {
            currentPage = 5
        }
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
