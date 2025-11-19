//
//  SettingsView.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingGoalSheet = false
    @State private var showingGoalHistory = false
    @State private var showingExport = false
    @State private var showingDeleteConfirmation = false
    @State private var exportedData = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Units Section
                Section("Units") {
                    Picker("Weight Unit", selection: binding(\.preferredUnit)) {
                        Text("Pounds (lb)").tag(WeightUnit.pounds)
                        Text("Kilograms (kg)").tag(WeightUnit.kilograms)
                    }
                    
                    Picker("Decimal Precision", selection: binding(\.decimalPrecision)) {
                        Text("1 decimal place").tag(1)
                        Text("2 decimal places").tag(2)
                    }
                }
                
                // Goal Section
                Section("Goal") {
                    if let goal = dataManager.fetchActiveGoal() {
                        HStack {
                            Text("Target Weight")
                            Spacer()
                            Text(displayValue(goal.targetWeightKg))
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Change Goal") {
                            showingGoalSheet = true
                        }
                        
                        Button("Goal History") {
                            showingGoalHistory = true
                        }
                    } else {
                        Button("Set Goal") {
                            showingGoalSheet = true
                        }
                    }
                }
                
                // Daily Aggregation
                Section {
                    Picker("Daily Value", selection: binding(\.dailyAggregationMode)) {
                        Text("Latest Entry").tag(DailyAggregationMode.latest)
                        Text("Daily Average").tag(DailyAggregationMode.average)
                    }
                } header: {
                    Text("Multiple Entries Per Day")
                } footer: {
                    Text("Choose how to calculate your daily weight when you have multiple entries.")
                }
                
                // Reminders
                Section("Reminders") {
                    Toggle("Daily Reminder", isOn: Binding(
                        get: { dataManager.settings?.reminderTime != nil },
                        set: { enabled in
                            if enabled {
                                dataManager.updateSettings { settings in
                                    // Set to 9 AM
                                    let calendar = Calendar.current
                                    var components = calendar.dateComponents([.year, .month, .day], from: Date())
                                    components.hour = 9
                                    components.minute = 0
                                    settings.reminderTime = calendar.date(from: components)
                                }
                            } else {
                                dataManager.updateSettings { settings in
                                    settings.reminderTime = nil
                                }
                            }
                        }
                    ))
                    
                    if dataManager.settings?.reminderTime != nil {
                        DatePicker("Time", selection: binding(\.reminderTime, default: Date()), displayedComponents: .hourAndMinute)
                        
                        Toggle("Adaptive Reminders", isOn: binding(\.adaptiveRemindersEnabled))
                    }
                }
                
                // Consistency Score
                Section {
                    Stepper("Window: \(dataManager.settings?.consistencyScoreWindow ?? 30) days",
                            value: binding(\.consistencyScoreWindow),
                            in: 7...90)
                } header: {
                    Text("Consistency Score")
                } footer: {
                    Text("Number of days to include in the consistency calculation.")
                }
                
                // Data Management
                Section("Data") {
                    Button("Export Data (CSV)") {
                        exportData()
                    }
                    
                    Button("Delete All Data", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingGoalSheet) {
                GoalSetupView()
            }
            .sheet(isPresented: $showingGoalHistory) {
                GoalHistoryView()
            }
            .sheet(isPresented: $showingExport) {
                ExportView(csvData: exportedData)
            }
            .confirmationDialog("Delete All Data", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete All Data", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your weight entries and goals. This action cannot be undone.")
            }
        }
    }
    
    private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { dataManager.settings?[keyPath: keyPath] ?? AppSettings()[keyPath: keyPath] },
            set: { newValue in
                dataManager.updateSettings { settings in
                    settings[keyPath: keyPath] = newValue
                }
            }
        )
    }
    
    private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T?>, default defaultValue: T) -> Binding<T> {
        Binding(
            get: { dataManager.settings?[keyPath: keyPath] ?? defaultValue },
            set: { newValue in
                dataManager.updateSettings { settings in
                    settings[keyPath: keyPath] = newValue
                }
            }
        )
    }
    
    private func displayValue(_ kg: Double) -> String {
        guard let unit = dataManager.settings?.preferredUnit else {
            return String(format: "%.1f kg", kg)
        }
        
        let value = unit.convert(fromKg: kg)
        let precision = dataManager.settings?.decimalPrecision ?? 1
        return String(format: "%.\(precision)f \(unit.symbol)", value)
    }
    
    private func exportData() {
        exportedData = dataManager.exportToCSV()
        showingExport = true
    }
    
    private func deleteAllData() {
        try? dataManager.deleteAllData()
    }
}

// MARK: - Goal Setup View

struct GoalSetupView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var targetWeightText = ""
    @State private var notes = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Target Weight", text: $targetWeightText)
                            .keyboardType(.decimalPad)
                        
                        Text(dataManager.settings?.preferredUnit.symbol ?? "kg")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Set Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(targetWeightText.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveGoal() {
        guard let weight = Double(targetWeightText) else {
            errorMessage = "Please enter a valid weight"
            showingError = true
            return
        }
        
        guard weight > 0 else {
            errorMessage = "Weight must be greater than zero"
            showingError = true
            return
        }
        
        guard let unit = dataManager.settings?.preferredUnit else {
            errorMessage = "Settings not available"
            showingError = true
            return
        }
        
        let weightKg = unit.convertToKg(weight)
        let currentWeight = dataManager.getCurrentWeight()
        
        do {
            try dataManager.setGoal(
                targetWeightKg: weightKg,
                startingWeightKg: currentWeight,
                notes: notes.isEmpty ? nil : notes
            )
            dismiss()
        } catch {
            errorMessage = "Failed to save goal: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Goal History View

struct GoalHistoryView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(dataManager.fetchGoalHistory()) { goal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(displayValue(goal.targetWeightKg))
                                .font(.headline)
                            
                            Spacer()
                            
                            if let reason = goal.completionReason {
                                Text(reason.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text("Set: \(goal.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let completedDate = goal.completedDate {
                            Text("Completed: \(completedDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let notes = goal.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Goal History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if dataManager.fetchGoalHistory().isEmpty {
                    ContentUnavailableView(
                        "No Goal History",
                        systemImage: "flag",
                        description: Text("Past goals will appear here")
                    )
                }
            }
        }
    }
    
    private func displayValue(_ kg: Double) -> String {
        guard let unit = dataManager.settings?.preferredUnit else {
            return String(format: "%.1f kg", kg)
        }
        
        let value = unit.convert(fromKg: kg)
        let precision = dataManager.settings?.decimalPrecision ?? 1
        return String(format: "%.\(precision)f \(unit.symbol)", value)
    }
}

// MARK: - Export View

struct ExportView: View {
    let csvData: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(csvData)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: csvData)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager(inMemory: true))
}
