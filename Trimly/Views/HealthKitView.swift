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
	@State private var importedCount: Int?
	@State private var errorMessage: String?
	@State private var showingError = false
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					TrimlyCardSection(title: "Authorization", description: "Allow Trimly to securely read your Health app weight data.") {
						if healthKitService.isAuthorized {
							Label("HealthKit Enabled", systemImage: "checkmark.circle.fill")
								.font(.headline)
								.foregroundStyle(.green)
							Text("You can now import history and sync future entries.")
								.font(.caption)
								.foregroundStyle(.secondary)
						} else {
							VStack(alignment: .leading, spacing: 12) {
								Text("Connect to Health so Trimly can keep everything in one place.")
									.font(.callout)
									.foregroundStyle(.secondary)
								Button("Request Access") {
									requestAuthorization()
								}
								.buttonStyle(.borderedProminent)
							}
						}
					}
					
					if healthKitService.isAuthorized {
						TrimlyCardSection(title: "Historical Import", description: "Choose a range and pull past weights into Trimly. Duplicates are automatically skipped.") {
							datePickerRow(title: "Start", date: $startDate)
								.onChange(of: startDate) { _, _ in
									loadSampleCount()
								}
							Divider()
							datePickerRow(title: "End", date: $endDate)
								.onChange(of: endDate) { _, _ in
									loadSampleCount()
								}
							Divider()
							if isLoadingSampleCount {
								HStack {
									Text("Counting samples")
										.font(.subheadline)
									Spacer()
									ProgressView()
								}
							} else if let count = sampleCount {
								metricRow(label: "Samples Found", value: "\(count)")
							} else {
								Text("Select a range to preview available entries.")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							Button {
								importData()
							} label: {
								Label("Import data", systemImage: "square.and.arrow.down")
									.font(.headline)
							}
							.disabled(sampleCount == nil || sampleCount == 0 || healthKitService.isImporting)
							.buttonStyle(.borderedProminent)
						}
						
						if healthKitService.isImporting {
							TrimlyCardSection(title: "Import Progress") {
								VStack(alignment: .leading, spacing: 8) {
									ProgressView(value: healthKitService.importProgress)
									Text("Importing... \(Int(healthKitService.importProgress * 100))%")
										.font(.caption)
										.foregroundStyle(.secondary)
								}
							}
						}
						
						if let count = importedCount {
							TrimlyCardSection(title: "Recent Import") {
								Label("\(count) samples imported", systemImage: "checkmark.circle.fill")
									.foregroundStyle(.green)
								Text("You can rerun imports at any time—duplicates stay hidden.")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
						
						TrimlyCardSection(title: "Background Sync", description: "Let Trimly watch for new Health weight samples and keep things tidy.") {
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
							Divider().padding(.vertical, 8)
							Toggle("Auto-hide Duplicates", isOn: Binding(
								get: { dataManager.settings?.autoHideHealthKitDuplicates ?? true },
								set: { enabled in
									dataManager.updateSettings { settings in
										settings.autoHideHealthKitDuplicates = enabled
									}
								}
							))
						}
					}
				}
				.padding(24)
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

// MARK: - UI Helpers


extension HealthKitView {
	private func metricRow(label: String, value: String) -> some View {
		HStack {
			Text(label)
				.font(.subheadline)
			Spacer()
			Text(value)
				.font(.headline)
		}
	}

	private func datePickerRow(title: String, date: Binding<Date>) -> some View {
		HStack {
			Text(title)
				.font(.subheadline.weight(.semibold))
			Spacer()
			DatePicker(title, selection: date, displayedComponents: .date)
				.labelsHidden()
		}
	}

}

#Preview {
	HealthKitView()
		.environmentObject(DataManager(inMemory: true))
}
