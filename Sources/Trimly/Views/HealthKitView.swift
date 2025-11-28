//
//  HealthKitView.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct HealthKitView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var healthKitService = HealthKitService()
    @Environment(\.dismiss) var dismiss
    
    @State private var startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var sampleCount: Int?
    @State private var isLoadingSampleCount = false
    @State private var showingImport = false
    @State private var importedCount: Int?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Authorization Section
                Section {
                    if healthKitService.isAuthorized {
                        Label("HealthKit Authorized", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Request HealthKit Access") {
                            requestAuthorization()
                        }
                    }
                } header: {
                    Text("Authorization")
                }
                
                // Import Section
                if healthKitService.isAuthorized {
                    Section {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            .onChange(of: startDate) { _, _ in
                                loadSampleCount()
                            }
                        
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .onChange(of: endDate) { _, _ in
                                loadSampleCount()
                            }
                        
                        if isLoadingSampleCount {
                            HStack {
                                Text("Loading sample count...")
                                Spacer()
                                ProgressView()
                            }
                        } else if let count = sampleCount {
                            HStack {
                                Text("Samples Found")
                                Spacer()
                                Text("\(count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button("Import Historical Data") {
                            importData()
                        }
                        .disabled(sampleCount == nil || sampleCount == 0 || healthKitService.isImporting)
                    } header: {
                        Text("Import Historical Data")
                    } footer: {
                        Text("Import weight data from HealthKit for the selected date range. Duplicates will be automatically detected.")
                    }
                    
                    // Import Progress
                    if healthKitService.isImporting {
                        Section {
                            VStack(spacing: 8) {
                                ProgressView(value: healthKitService.importProgress)
                                Text("Importing... \(Int(healthKitService.importProgress * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Import Result
                    if let count = importedCount {
                        Section {
                            Label("\(count) samples imported successfully", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    // Background Sync
                    Section {
                        Toggle("Enable Background Sync", isOn: Binding(
                            get: { dataManager.settings?.healthKitEnabled ?? false },
                            set: { enabled in
                                dataManager.updateSettings { settings in
                                    settings.healthKitEnabled = enabled
                                }
                                if enabled {
                                    enableBackgroundSync()
                                }
                            }
                        ))
                        
                        Toggle("Auto-hide Duplicates", isOn: Binding(
                            get: { dataManager.settings?.autoHideHealthKitDuplicates ?? true },
                            set: { enabled in
                                dataManager.updateSettings { settings in
                                    settings.autoHideHealthKitDuplicates = enabled
                                }
                            }
                        ))
                    } header: {
                        Text("Background Sync")
                    } footer: {
                        Text("Automatically sync new weight data from HealthKit in the background.")
                    }
                }
            }
            .navigationTitle("HealthKit Integration")
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .onAppear {
                healthKitService.checkAuthorizationStatus()
                if healthKitService.isAuthorized {
                    loadSampleCount()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func requestAuthorization() {
        Task {
            do {
                try await healthKitService.requestAuthorization()
                if healthKitService.isAuthorized {
                    loadSampleCount()
                }
            } catch {
                errorMessage = "Failed to authorize HealthKit: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func loadSampleCount() {
        guard healthKitService.isAuthorized else { return }
        
        isLoadingSampleCount = true
        sampleCount = nil
        
        Task {
            do {
                let count = try await healthKitService.getSampleCount(from: startDate, to: endDate)
                sampleCount = count
            } catch {
                errorMessage = "Failed to load sample count: \(error.localizedDescription)"
                showingError = true
            }
            isLoadingSampleCount = false
        }
    }
    
    private func importData() {
        guard let unit = dataManager.settings?.preferredUnit else { return }
        
        Task {
            do {
                let count = try await healthKitService.importHistoricalData(
                    from: startDate,
                    to: endDate,
                    dataManager: dataManager,
                    unit: unit
                )
                importedCount = count
            } catch {
                errorMessage = "Failed to import data: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func enableBackgroundSync() {
        guard let unit = dataManager.settings?.preferredUnit else { return }
        healthKitService.enableBackgroundDelivery(dataManager: dataManager, unit: unit)
    }
}

#Preview {
    HealthKitView()
        .environmentObject(DataManager(inMemory: true))
}
