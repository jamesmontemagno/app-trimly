//
//  SettingsView.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var deviceSettings: DeviceSettingsStore
	@EnvironmentObject var storeManager: StoreManager
	@StateObject private var notificationService = NotificationService()
	@State private var showingGoalSheet = false
	@State private var showingGoalHistory = false
	@State private var showingGoalActions = false
	@State private var goalMode: GoalMode = .new
	@State private var showingExport = false
	@State private var showingPaywall = false
	@State private var navigateToHealthKit = false
	@State private var showingDeleteConfirmation = false
	@State private var exportedData = ""
	@State private var showingRestoreSuccessAlert = false
	@State private var showingRestoreNotFoundAlert = false
	@State private var showingRestartRequiredAlert = false
#if DEBUG
	@State private var showingSampleDataAlert = false
	@State private var sampleDataAlertMessage = ""
#endif
	
	private var appVersion: String {
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
		let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
		if !version.isEmpty && !build.isEmpty {
			return "\(version) (\(build))"
		} else if !version.isEmpty {
			return version
		} else if !build.isEmpty {
			return build
		} else {
			return "-"
		}
	}
	
	var body: some View {
		settingsNavigation
	}
	
	private var settingsNavigation: some View {
		NavigationStack {
			settingsContent
				.scrollIndicators(.hidden)
				.background(Color.clear)
				.navigationTitle(Text(L10n.Settings.navigationTitle))
				.navigationDestination(isPresented: $navigateToHealthKit) { HealthKitView() }
				.sheet(isPresented: $showingGoalSheet) { GoalSetupView(mode: goalMode) }
				.sheet(isPresented: $showingGoalHistory) { GoalHistoryView() }
				.sheet(isPresented: $showingExport) { ExportView(initialCSV: exportedData) }
				.sheet(isPresented: $showingPaywall) { PaywallView() }
				.confirmationDialog(String(localized: L10n.Common.deleteAllDataTitle), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
					Button(String(localized: L10n.Settings.deleteAllTitle), role: .destructive) { deleteAllData() }
					Button(String(localized: L10n.Common.cancelButton), role: .cancel) { }
				} message: {
					Text(L10n.Settings.deleteWarning)
				}
				.alert(String(localized: L10n.Settings.restoreSuccessTitle), isPresented: $showingRestoreSuccessAlert) {
					Button(String(localized: L10n.Common.okButton), role: .cancel) { }
				} message: {
					Text(L10n.Settings.restoreSuccessMessage)
				}
				.alert(String(localized: L10n.Settings.restoreNotFoundTitle), isPresented: $showingRestoreNotFoundAlert) {
					Button(String(localized: L10n.Common.okButton), role: .cancel) { }
				} message: {
					Text(L10n.Settings.restoreNotFoundMessage)
				}
				.alert(String(localized: L10n.Settings.iCloudSyncRestartTitle), isPresented: $showingRestartRequiredAlert) {
					Button(String(localized: L10n.Common.okButton), role: .cancel) { }
				} message: {
					Text(L10n.Settings.iCloudSyncRestartMessage)
				}
#if DEBUG
				.alert(String(localized: L10n.Debug.sampleDataTitle), isPresented: $showingSampleDataAlert) {
					Button(String(localized: L10n.Common.okButton), role: .cancel) { }
				} message: {
					Text(sampleDataAlertMessage)
				}
#endif
		}
	}
	
	private var settingsContent: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 32) {
					if !storeManager.isPro {
						Button {
							showingPaywall = true
						} label: {
							TrimlyCardContainer(style: .elevated) {
								HStack {
									VStack(alignment: .leading, spacing: 4) {
										Text("Upgrade to Pro")
											.font(.headline)
										Text("Unlock HealthKit sync, data export, and more.")
											.font(.subheadline)
											.foregroundStyle(.secondary)
									}
									Spacer()
									Image(systemName: "chevron.right")
										.foregroundStyle(.secondary)
								}
								.padding(.vertical, 4)
							}
						}
						.buttonStyle(.plain)
					} else {
						TrimlyCardContainer(style: .elevated) {
							HStack {
								RoundedRectangle(cornerRadius: 14, style: .continuous)
									.fill(Color.yellow.opacity(0.15))
									.frame(width: 52, height: 52)
									.overlay(
										Image(systemName: "crown.fill")
											.font(.title3)
											.foregroundStyle(.yellow)
									)
								VStack(alignment: .leading, spacing: 4) {
									Text(L10n.Settings.proStatus)
										.font(.headline)
									Text(L10n.Settings.proDescription)
										.font(.subheadline)
										.foregroundStyle(.secondary)
								}
								Spacer()
							}
							.padding(.vertical, 4)
						}
					}

					settingsSection(
						title: String(localized: L10n.Settings.personalizationTitle),
						description: String(localized: L10n.Settings.personalizationDescription)
					) {
						settingsRow(
							icon: "scalemass",
							title: String(localized: L10n.Settings.weightUnitTitle),
							subtitle: String(localized: L10n.Settings.weightUnitSubtitle),
							accessoryPlacement: .below
						) {
							Picker(String(localized: L10n.Settings.weightUnitTitle), selection: binding(\.preferredUnit)) {
								Text(L10n.Onboarding.unitOptionPounds).tag(WeightUnit.pounds)
								Text(L10n.Onboarding.unitOptionKilograms).tag(WeightUnit.kilograms)
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
						
						sectionDivider()
						
						settingsRow(
							icon: "number",
							title: String(localized: L10n.Settings.decimalPrecisionTitle),
							subtitle: String(localized: L10n.Settings.decimalPrecisionSubtitle),
							accessoryPlacement: .below
						) {
							Picker(String(localized: L10n.Settings.decimalPrecisionTitle), selection: binding(\.decimalPrecision)) {
								Text(L10n.Settings.decimalPrecisionOne).tag(1)
								Text(L10n.Settings.decimalPrecisionTwo).tag(2)
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
						
						sectionDivider()
						
						settingsRow(
							icon: "circle.lefthalf.filled",
							title: String(localized: L10n.Settings.themeTitle),
							subtitle: String(localized: L10n.Settings.themeSubtitle),
							accessoryPlacement: .below
						) {
							Picker(String(localized: L10n.Settings.themeTitle), selection: binding(\.appearance)) {
								ForEach(AppAppearance.allCases) { option in
									Text(option.displayName).tag(option)
								}
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
					}
					
					settingsSection(title: String(localized: L10n.Settings.goalsTitle)) {
						if let goal = dataManager.fetchActiveGoal() {
						let preferredUnit = dataManager.settings?.preferredUnit ?? .pounds
						let targetWeight = preferredUnit.convert(fromKg: goal.targetWeightKg)
						let subtitle = String(format: "%.1f %@", targetWeight, preferredUnit.symbol)
						
						Button {
						showingGoalActions = true
					} label: {
						settingsRow(
							icon: "flag.checkered",
							title: String(localized: L10n.Settings.currentGoalTitle),
							subtitle: subtitle,
									showChevron: true
								)
							}
							.buttonStyle(.plain)
							.confirmationDialog(String(localized: L10n.Goals.actionsTitle), isPresented: $showingGoalActions) {
								Button(String(localized: L10n.Goals.actionEditCurrent)) {
									goalMode = .edit
									showingGoalSheet = true
								}
								Button(String(localized: L10n.Goals.actionStartNew)) {
									goalMode = .new
									showingGoalSheet = true
								}
								Button(String(localized: L10n.Common.cancelButton), role: .cancel) {}
							}
							
							sectionDivider()
							
							Button {
								showingGoalHistory = true
							} label: {
								settingsRow(
									icon: "clock.arrow.circlepath",
									title: String(localized: L10n.Settings.goalHistoryTitle),
									subtitle: String(localized: L10n.Settings.goalHistorySubtitle),
									showChevron: true
								)
							}
							.buttonStyle(.plain)
						} else {
							Button {
								showingGoalSheet = true
							} label: {
								settingsRow(
									icon: "flag",
									title: String(localized: L10n.Settings.setGoalTitle),
									subtitle: String(localized: L10n.Settings.setGoalSubtitle),
									showChevron: true
								)
							}
							.buttonStyle(.plain)
						}
					}
					
					settingsSection(
						title: String(localized: L10n.Settings.dailyValueTitle),
						description: String(localized: L10n.Settings.dailyValueDescription)
					) {
						settingsRow(
							icon: "calendar.day.timeline.left",
							title: String(localized: L10n.Settings.dailyCalculationTitle),
							subtitle: String(localized: L10n.Settings.dailyCalculationSubtitle),
							accessoryPlacement: .below
						) {
							Picker(String(localized: L10n.Settings.dailyCalculationTitle), selection: binding(\.dailyAggregationMode)) {
								Text(L10n.Settings.dailyLatest).tag(DailyAggregationMode.latest)
								Text(L10n.Settings.dailyAverage).tag(DailyAggregationMode.average)
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
					}
					
					settingsSection(title: String(localized: L10n.Settings.habitsTitle)) {
						NavigationLink {
							RemindersView()
						} label: {
							settingsRow(
								icon: "bell.badge.fill",
								title: String(localized: L10n.Reminders.navigationTitle),
								subtitle: deviceSettings.reminders.primaryTime != nil ? String(localized: L10n.Settings.remindersSubtitleOn) : String(localized: L10n.Settings.remindersSubtitleOff),
								showChevron: true
							) {
								if deviceSettings.reminders.primaryTime != nil {
									statusPill(text: String(localized: L10n.Settings.remindersStatusOn), color: .green)
								} else {
									statusPill(text: String(localized: L10n.Settings.remindersStatusOff), color: .secondary)
								}
							}
						}
						.buttonStyle(.plain)
					}
					
					settingsSection(title: String(localized: L10n.Settings.integrationsTitle)) {
						Button {
							if storeManager.isPro {
								navigateToHealthKit = true
							} else {
								showingPaywall = true
							}
						} label: {
							settingsRow(
								icon: "heart.fill",
								title: String(localized: L10n.Settings.healthTitle),
								subtitle: String(localized: L10n.Settings.healthSubtitle),
								showChevron: true,
								iconTint: .pink
							) {
								if !storeManager.isPro {
									Image(systemName: "lock.fill")
										.foregroundStyle(.secondary)
								} else if deviceSettings.healthKit.backgroundSyncEnabled {
									statusPill(text: String(localized: L10n.Settings.healthConnected), color: .green)
								}
							}
						}
						.buttonStyle(.plain)
					}
					
					
					settingsSection(title: String(localized: L10n.Settings.dataPrivacyTitle)) {
						settingsRow(
							icon: "icloud",
							title: String(localized: L10n.Settings.iCloudSyncTitle),
							subtitle: String(localized: L10n.Settings.iCloudSyncSubtitle)
						) {
							Toggle("", isOn: Binding(
								get: { deviceSettings.cloudSync.iCloudSyncEnabled },
								set: { newValue in
									deviceSettings.updateCloudSync { settings in
										settings.iCloudSyncEnabled = newValue
									}
									showingRestartRequiredAlert = true
								}
							))
							.labelsHidden()
						}
						
						sectionDivider()
						
						Button {
							if storeManager.isPro {
								exportData()
							} else {
								showingPaywall = true
							}
						} label: {
							settingsRow(
								icon: "square.and.arrow.up",
								title: String(localized: L10n.Settings.exportTitle),
								subtitle: String(localized: L10n.Settings.exportSubtitle),
								showChevron: true
							) {
								if !storeManager.isPro {
									Image(systemName: "lock.fill")
										.foregroundStyle(.secondary)
								}
							}
						}
						.buttonStyle(.plain)
						
						sectionDivider()
						
						Button(role: .destructive) {
							showingDeleteConfirmation = true
						} label: {
							settingsRow(
								icon: "trash",
								title: String(localized: L10n.Settings.deleteAllTitle),
								subtitle: String(localized: L10n.Settings.deleteAllSubtitle),
								showChevron: true,
								iconTint: .red
							)
						}
						.buttonStyle(.plain)
					}
			
	#if DEBUG
					settingsSection(
						title: String(localized: L10n.Debug.toolsTitle),
						description: String(localized: L10n.Debug.toolsDescription)
					) {
						Button {
							generateSampleData()
						} label: {
							settingsRow(
								icon: "wand.and.stars",
								title: String(localized: L10n.Debug.sampleDataTitle),
								subtitle: String(localized: L10n.Debug.sampleDataSubtitle),
								iconTint: .indigo
							) {
								statusPill(text: String(localized: L10n.Debug.sampleDataAction), color: .indigo)
							}
						}
						.buttonStyle(.plain)
					}
	#endif
					
					settingsSection(title: String(localized: L10n.Settings.aboutTitle)) {
						Button(String(localized: L10n.Settings.restorePurchases)) {
							Task {
								let found = await storeManager.restore()
								if found {
									showingRestoreSuccessAlert = true
								} else {
									showingRestoreNotFoundAlert = true
								}
							}
						}
						.buttonStyle(.plain)
						.foregroundStyle(.primary)
						
						sectionDivider()

						HStack {
							Text(L10n.Settings.versionLabel)
							Spacer()
							Text(appVersion)
								.foregroundStyle(.secondary)
						}
						
						sectionDivider()
						
						Link(String(localized: L10n.Settings.privacyPolicy), destination: URL(string: "https://www.refractored.com/about#privacy-policy")!)
							.font(.body.weight(.semibold))
						Link(String(localized: L10n.Settings.termsOfService), destination: URL(string: "https://www.refractored.com/terms")!)
							.font(.body.weight(.semibold))
					}
				}
				.padding(.horizontal, 24)
				.padding(.top, 32)
				.padding(.bottom, 48)
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
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}

	private func currentGoalSubtitle(for goal: Goal) -> String {
		let targetText = displayValue(goal.targetWeightKg)
		if let startKg = goal.startingWeightKg {
			let startText = displayValue(startKg)
			return String(localized: L10n.Settings.currentGoalSubtitle(targetText, startText))
		} else {
			return String(localized: L10n.Settings.currentGoalSubtitle(targetText, nil))
		}
	}
    
	private func exportData() {
		exportedData = dataManager.exportToCSV()
		showingExport = true
	}
    
	private func deleteAllData() {
		notificationService.cancelAllReminders()
		try? dataManager.deleteAllData()
	}

#if DEBUG
	private func generateSampleData() {
		do {
			try dataManager.generateSampleData()
			sampleDataAlertMessage = String(localized: L10n.Debug.sampleDataSuccess)
		} catch {
			sampleDataAlertMessage = String(localized: L10n.Debug.sampleDataFailure(error.localizedDescription))
		}
		showingSampleDataAlert = true
	}
#endif
	
	private func settingsSection<Content: View>(title: String, description: String? = nil, @ViewBuilder content: @escaping () -> Content) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(title)
				.font(.title3.weight(.semibold))
			if let description {
				Text(description)
					.font(.callout)
					.foregroundStyle(.secondary)
			}
			TrimlyCardContainer(style: .elevated) {
				VStack(spacing: 0) {
					content()
				}
			}
		}
	}
	
	private func sectionDivider() -> some View {
		Divider()
			.overlay(Color.primary.opacity(0.08))
			.padding(.vertical, 8)
	}

	private enum SettingsAccessoryPlacement {
		case trailing
		case below
	}
	
	private func settingsRow<Accessory: View>(
		icon: String,
		title: String,
		subtitle: String? = nil,
		showChevron: Bool = false,
		iconTint: Color = Color.accentColor,
		accessoryPlacement: SettingsAccessoryPlacement = .trailing,
		@ViewBuilder accessory: () -> Accessory = { EmptyView() }
	) -> some View {
		let needsTrailingSpacer = accessoryPlacement == .trailing || showChevron
		return HStack(alignment: .top, spacing: 16) {
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(iconTint.opacity(0.15))
				.frame(width: 52, height: 52)
				.overlay(
					Image(systemName: icon)
						.font(.title3)
						.foregroundStyle(iconTint)
				)
			VStack(alignment: .leading, spacing: accessoryPlacement == .below ? 10 : 2) {
				Text(title)
					.font(.body.weight(.semibold))
				if let subtitle {
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				if accessoryPlacement == .below {
					accessory()
						.frame(maxWidth: .infinity)
				}
			}
			if needsTrailingSpacer {
				Spacer(minLength: 0)
			}
			if accessoryPlacement == .trailing {
				accessory()
			}
			if showChevron {
				Image(systemName: "chevron.right")
					.font(.footnote.weight(.semibold))
					.foregroundStyle(.tertiary)
			}
		}
		.padding(.vertical, accessoryPlacement == .below ? 10 : 6)
	}
	
	private func statusPill(text: String, color: Color) -> some View {
		Text(text)
			.font(.caption.bold())
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(
				Capsule()
					.fill(color.opacity(color == .secondary ? 0.15 : 0.2))
			)
			.foregroundStyle(color == .secondary ? .secondary : color)
	}
}

#Preview {
	SettingsView()
		.environmentObject(DataManager(inMemory: true))
		.environmentObject(DeviceSettingsStore())
		.environmentObject(StoreManager())
}
