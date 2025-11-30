//
//  HealthKitView.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct HealthKitView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var deviceSettings: DeviceSettingsStore
	@StateObject private var healthKitService = HealthKitService()
	@Environment(\.dismiss) var dismiss
    
	@State private var startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
	@State private var endDate = Date()
	@State private var sampleCount: Int?
	@State private var isLoadingSampleCount = false
	@State private var importedCount: Int?
	@State private var errorMessage: LocalizedStringResource?
	@State private var showingError = false
	@State private var healthKitEntryCount: Int = 0
	@State private var firstHealthKitDate: Date?
	@State private var lastHealthKitDate: Date?
	@State private var isImportingRecent = false

	private var healthSettings: DeviceSettingsStore.HealthKitSettings {
		deviceSettings.healthKit
	}
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					TrimlyCardSection(
						title: String(localized: L10n.Health.authorizationTitle),
						description: String(localized: L10n.Health.authorizationDescription)
					) {
						if healthKitService.isAuthorized {
							Label(String(localized: L10n.Health.statusEnabled), systemImage: "checkmark.circle.fill")
								.font(.headline)
								.foregroundStyle(.green)
							Text(L10n.Health.statusEnabledDescription)
								.font(.caption)
								.foregroundStyle(.secondary)
							if healthKitEntryCount > 0 {
								Divider().padding(.vertical, 8)
								VStack(alignment: .leading, spacing: 6) {
									HStack {
										Text(L10n.Health.syncedEntriesLabel)
											.font(.subheadline)
										Spacer()
										Text("\(healthKitEntryCount)")
											.font(.headline)
									}
									if let first = firstHealthKitDate, let last = lastHealthKitDate {
										Text(L10n.Health.syncedRangeDescription(first.formatted(date: .abbreviated, time: .omitted), last.formatted(date: .abbreviated, time: .omitted)))
											.font(.caption)
											.foregroundStyle(.secondary)
									}
								}
							}
						} else {
							VStack(alignment: .leading, spacing: 12) {
								Text(L10n.Health.connectPrompt)
									.font(.callout)
									.foregroundStyle(.secondary)
								Button(String(localized: L10n.Health.requestAccessButton)) {
									requestAuthorization()
								}
								.buttonStyle(.borderedProminent)
							}
						}
					}

					TrimlyCardSection(
						title: String(localized: L10n.Health.syncDirectionTitle),
						description: String(localized: L10n.Health.syncDirectionDescription)
					) {
						VStack(alignment: .leading, spacing: 8) {
							Label(String(localized: L10n.Health.syncDirectionRead), systemImage: "arrow.down.circle")
								.font(.subheadline)
								.foregroundStyle(.primary)
							Label(String(localized: L10n.Health.syncDirectionWrite), systemImage: "arrow.up.circle")
								.font(.subheadline)
								.foregroundStyle(.primary)
						}
					}
					
					if healthKitService.isAuthorized {
						TrimlyCardSection(
							title: String(localized: L10n.Health.historicalImportTitle),
							description: String(localized: L10n.Health.historicalImportDescription)
						) {
							datePickerRow(title: L10n.Health.startDateLabel, date: $startDate)
								.onChange(of: startDate) { _, _ in
									loadSampleCount()
								}
							Divider()
							datePickerRow(title: L10n.Health.endDateLabel, date: $endDate)
								.onChange(of: endDate) { _, _ in
									loadSampleCount()
								}
							Divider()
							if isLoadingSampleCount {
								HStack {
									Text(L10n.Health.countingSamples)
										.font(.subheadline)
									Spacer()
									ProgressView()
								}
							} else if let count = sampleCount {
								metricRow(label: L10n.Health.samplesFoundLabel, value: "\(count)")
							} else {
								Text(L10n.Health.selectRangeHint)
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							Button {
								importRecent()
							} label: {
								Label(String(localized: L10n.Health.importRecentButton), systemImage: "clock.arrow.circlepath")
									.font(.subheadline)
							}
							.disabled(healthKitService.isImporting || isImportingRecent)
							.buttonStyle(.bordered)
							Button {
								importData()
							} label: {
								Label(String(localized: L10n.Health.importButton), systemImage: "square.and.arrow.down")
									.font(.headline)
							}
							.disabled(sampleCount == nil || sampleCount == 0 || healthKitService.isImporting)
							.buttonStyle(.borderedProminent)
							if let lastImport = healthSettings.lastImportAt {
								Divider().padding(.vertical, 8)
								Text(L10n.Health.lastManualImport(lastImport.formatted(date: .abbreviated, time: .shortened)))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
						
						if healthKitService.isImporting {
							TrimlyCardSection(title: String(localized: L10n.Health.importProgressTitle)) {
								VStack(alignment: .leading, spacing: 8) {
									ProgressView(value: healthKitService.importProgress)
									Text(L10n.Health.importProgressStatus(Int(healthKitService.importProgress * 100)))
										.font(.caption)
										.foregroundStyle(.secondary)
								}
							}
						}
						
						if let count = importedCount {
							TrimlyCardSection(title: String(localized: L10n.Health.recentImportTitle)) {
								Label(String(localized: L10n.Health.recentImportStatus(count)), systemImage: "checkmark.circle.fill")
									.foregroundStyle(.green)
								Text(L10n.Health.recentImportHint)
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
						
						TrimlyCardSection(
							title: String(localized: L10n.Health.backgroundSyncTitle),
							description: String(localized: L10n.Health.backgroundSyncDescription)
						) {
							Divider().padding(.vertical, 8)
							Toggle(String(localized: L10n.Health.backgroundSyncToggle), isOn: Binding(
								get: { healthSettings.backgroundSyncEnabled },
								set: { enabled in
									deviceSettings.updateHealthKit { settings in
										settings.backgroundSyncEnabled = enabled
									}
									if enabled {
										enableBackgroundSync()
									}
								}
							))
							Divider().padding(.vertical, 8)
							Toggle(String(localized: L10n.Health.autoHideToggle), isOn: Binding(
								get: { healthSettings.autoHideDuplicates },
								set: { enabled in
									deviceSettings.updateHealthKit { settings in
										settings.autoHideDuplicates = enabled
									}
								}
							))
							Divider().padding(.vertical, 8)
							Toggle(String(localized: L10n.Health.writeToHealthToggle), isOn: Binding(
								get: { healthSettings.writeEnabled },
								set: { enabled in
									deviceSettings.updateHealthKit { settings in
										settings.writeEnabled = enabled
									}
								}
							))
							if let lastBackground = healthSettings.lastBackgroundSyncAt {
								Divider().padding(.vertical, 8)
								Text(L10n.Health.lastBackgroundSync(lastBackground.formatted(date: .abbreviated, time: .shortened)))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
					}
				}
				.padding(24)
			}
			.navigationTitle(String(localized: L10n.Health.navigationTitle))
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
			.alert(String(localized: L10n.Common.errorTitle), isPresented: $showingError) {
				Button(String(localized: L10n.Common.okButton), role: .cancel) { }
			} message: {
				Text(errorMessage ?? L10n.Health.genericErrorMessage)
			}
			.onAppear {
				healthKitService.checkAuthorizationStatus()
				if healthKitService.isAuthorized {
					loadSampleCount()
					loadHealthKitSummary()
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
				errorMessage = L10n.Health.authorizationFailed(error.localizedDescription)
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
				errorMessage = L10n.Health.sampleCountFailed(error.localizedDescription)
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
				deviceSettings.updateHealthKit { settings in
					settings.lastImportAt = Date()
				}
				loadHealthKitSummary()
			} catch {
				errorMessage = L10n.Health.importFailed(error.localizedDescription)
				showingError = true
			}
		}
	}

	private func importRecent() {
		guard let unit = dataManager.settings?.preferredUnit else { return }
		let now = Date()
		let calendar = Calendar.current
		let start: Date
		if let lastImport = healthSettings.lastImportAt {
			start = lastImport
		} else if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) {
			start = thirtyDaysAgo
		} else {
			start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
		}
		isImportingRecent = true
		Task {
			do {
				let count = try await healthKitService.importHistoricalData(
					from: start,
					to: now,
					dataManager: dataManager,
					unit: unit
				)
				importedCount = count
				deviceSettings.updateHealthKit { settings in
					settings.lastImportAt = Date()
				}
				loadHealthKitSummary()
			} catch {
				errorMessage = L10n.Health.importFailed(error.localizedDescription)
				showingError = true
			}
			isImportingRecent = false
		}
	}
    
	private func enableBackgroundSync() {
		guard let unit = dataManager.settings?.preferredUnit else { return }
		healthKitService.enableBackgroundDelivery(dataManager: dataManager, unit: unit)
	}

	private func loadHealthKitSummary() {
		let entries = dataManager.fetchAllEntries().filter { $0.source == .healthKit && !$0.isHidden }
		healthKitEntryCount = entries.count
		firstHealthKitDate = entries.last?.timestamp
		lastHealthKitDate = entries.first?.timestamp
	}
}

// MARK: - UI Helpers



extension HealthKitView {
	private func metricRow(label: LocalizedStringResource, value: String) -> some View {
		HStack {
			Text(label)
				.font(.subheadline)
			Spacer()
			Text(value)
				.font(.headline)
		}
	}

	private func datePickerRow(title: LocalizedStringResource, date: Binding<Date>) -> some View {
		HStack {
			Text(title)
				.font(.subheadline.weight(.semibold))
			Spacer()
			DatePicker(String(localized: title), selection: date, displayedComponents: .date)
				.labelsHidden()
		}
	}

}

#Preview {
	HealthKitView()
		.environmentObject(DataManager(inMemory: true))
		.environmentObject(DeviceSettingsStore())
}
