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
	@State private var showingGoalSheet = false
	@State private var showingGoalHistory = false
	@State private var showingExport = false
	@State private var showingDeleteConfirmation = false
	@State private var exportedData = ""
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 32) {
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
							Button {
								showingGoalSheet = true
							} label: {
								settingsRow(
									icon: "flag.checkered",
									title: String(localized: L10n.Settings.currentGoalTitle),
									subtitle: displayValue(goal.targetWeightKg),
									showChevron: true
								)
							}
							.buttonStyle(.plain)
							
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
								subtitle: dataManager.settings?.reminderTime != nil ? String(localized: L10n.Settings.remindersSubtitleOn) : String(localized: L10n.Settings.remindersSubtitleOff),
								showChevron: true
							) {
								if dataManager.settings?.reminderTime != nil {
									statusPill(text: String(localized: L10n.Settings.remindersStatusOn), color: .green)
								} else {
									statusPill(text: String(localized: L10n.Settings.remindersStatusOff), color: .secondary)
								}
							}
						}
						.buttonStyle(.plain)
					}
					
					settingsSection(title: String(localized: L10n.Settings.integrationsTitle)) {
						NavigationLink {
							HealthKitView()
						} label: {
							settingsRow(
								icon: "heart.fill",
								title: String(localized: L10n.Settings.healthTitle),
								subtitle: String(localized: L10n.Settings.healthSubtitle),
								showChevron: true,
								iconTint: .pink
							) {
								if dataManager.settings?.healthKitEnabled == true {
									statusPill(text: String(localized: L10n.Settings.healthConnected), color: .green)
								}
							}
						}
						.buttonStyle(.plain)
					}
					
					settingsSection(title: String(localized: L10n.Settings.consistencyTitle)) {
						settingsRow(
							icon: "chart.bar.fill",
							title: String(localized: L10n.Settings.consistencyWindowTitle),
							subtitle: String(localized: L10n.Settings.consistencyWindowSubtitle(dataManager.settings?.consistencyScoreWindow ?? 30))
						) {
							Stepper("", value: binding(\.consistencyScoreWindow), in: 7...90, step: 1)
								.labelsHidden()
						}
					}
					
					settingsSection(title: String(localized: L10n.Settings.dataPrivacyTitle)) {
						Button {
							exportData()
						} label: {
							settingsRow(
								icon: "square.and.arrow.up",
								title: String(localized: L10n.Settings.exportTitle),
								subtitle: String(localized: L10n.Settings.exportSubtitle),
								showChevron: true
							)
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
					
					settingsSection(title: String(localized: L10n.Settings.aboutTitle)) {
						HStack {
							Text(L10n.Settings.versionLabel)
							Spacer()
							Text("1.0.0")
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
			.scrollIndicators(.hidden)
			.background(Color.clear)
			.navigationTitle(Text(L10n.Settings.navigationTitle))
			.sheet(isPresented: $showingGoalSheet) { GoalSetupView() }
			.sheet(isPresented: $showingGoalHistory) { GoalHistoryView() }
			.sheet(isPresented: $showingExport) { ExportView(csvData: exportedData) }
			.confirmationDialog(String(localized: L10n.Common.deleteAllDataTitle), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
				Button(String(localized: L10n.Settings.deleteAllTitle), role: .destructive) { deleteAllData() }
				Button(String(localized: L10n.Common.cancelButton), role: .cancel) { }
			} message: {
				Text(L10n.Settings.deleteWarning)
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
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
    
	private func exportData() {
		exportedData = dataManager.exportToCSV()
		showingExport = true
	}
    
	private func deleteAllData() {
		try? dataManager.deleteAllData()
	}
	
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

struct GoalSetupView: View {
	@EnvironmentObject var dataManager: DataManager
	@Environment(\.dismiss) var dismiss
    
	@State private var targetWeightText = ""
	@State private var notes = ""
	@State private var showingError = false
	@State private var errorMessage = ""
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					TrimlyCardSection(
						title: String(localized: L10n.Goals.targetTitle),
						description: String(localized: L10n.Goals.targetDescription(dataManager.settings?.preferredUnit.symbol ?? "kg")),
						style: .popup
					) {
						HStack(spacing: 12) {
							TextField(String(localized: L10n.Goals.targetPlaceholder), text: $targetWeightText)
								#if os(iOS)
								.keyboardType(.decimalPad)
								#endif
							Text(dataManager.settings?.preferredUnit.symbol ?? "kg")
								.foregroundStyle(.secondary)
						}
					}
					
					TrimlyCardSection(
						title: String(localized: L10n.Goals.notesTitle),
						description: String(localized: L10n.Goals.notesDescription),
						style: .popup
					) {
						TextField(String(localized: L10n.Goals.notesPlaceholder), text: $notes, axis: .vertical)
							.lineLimit(3...6)
					}
					
					Text(L10n.Goals.unitHint)
						.font(.callout)
						.foregroundStyle(.secondary)
				}
				.padding(24)
			}
			.navigationTitle(Text(L10n.Goals.setupTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(String(localized: L10n.Common.cancelButton)) { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.saveButton)) { saveGoal() }
						.disabled(targetWeightText.isEmpty)
				}
			}
			.alert(L10n.Common.errorTitle, isPresented: $showingError) {
				Button(String(localized: L10n.Common.okButton), role: .cancel) { }
			} message: {
				Text(errorMessage)
			}
		}
	}
    
	private func saveGoal() {
		guard let weight = Double(targetWeightText) else {
			errorMessage = String(localized: L10n.Goals.errorInvalidWeight)
			showingError = true
			return
		}
		guard weight > 0 else {
			errorMessage = String(localized: L10n.Goals.errorNonPositiveWeight)
			showingError = true
			return
		}
		guard let unit = dataManager.settings?.preferredUnit else {
			errorMessage = String(localized: L10n.Goals.errorMissingSettings)
			showingError = true
			return
		}
		let weightKg = unit.convertToKg(weight)
		let currentWeight = dataManager.getCurrentWeight()
		do {
			try dataManager.setGoal(targetWeightKg: weightKg,
									startingWeightKg: currentWeight,
									notes: notes.isEmpty ? nil : notes)
			dismiss()
		} catch {
			errorMessage = String(localized: L10n.Goals.errorSaveFailure(error.localizedDescription))
			showingError = true
		}
	}
}

struct GoalHistoryView: View {
	@EnvironmentObject var dataManager: DataManager
	@Environment(\.dismiss) var dismiss
    
	var body: some View {
		NavigationStack {
			let history = dataManager.fetchGoalHistory()
			ScrollView {
				LazyVStack(spacing: 16) {
					ForEach(history) { goal in
						historyCard(goal)
					}
				}
				.padding(24)
			}
			.navigationTitle(Text(L10n.Goals.historyTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.doneButton)) { dismiss() }
				}
			}
			.overlay {
				if history.isEmpty {
					ContentUnavailableView(
						String(localized: L10n.Goals.noHistoryTitle),
						systemImage: "flag",
						description: Text(L10n.Goals.noHistoryDescription)
					)
				}
			}
		}
	}
    
	private func historyCard(_ goal: Goal) -> some View {
		TrimlyCardContainer(style: .popup) {
			VStack(alignment: .leading, spacing: 10) {
				HStack(alignment: .firstTextBaseline) {
					Text(displayValue(goal.targetWeightKg))
						.font(.title3.weight(.semibold))
					Spacer()
					if let reason = goal.completionReason {
						let pill = completionPillColors(for: reason)
						Text(completionLabel(for: reason))
							.font(.caption.weight(.semibold))
							.padding(.horizontal, 10)
							.padding(.vertical, 4)
							.background(pill.background)
							.foregroundStyle(pill.foreground)
							.clipShape(Capsule())
					}
				}
				Text(L10n.Goals.setOn(goal.startDate.formatted(date: .abbreviated, time: .omitted)))
					.font(.caption)
					.foregroundStyle(.secondary)
				if let completedDate = goal.completedDate {
					Text(L10n.Goals.completedOn(completedDate.formatted(date: .abbreviated, time: .omitted)))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				if let notes = goal.notes, !notes.isEmpty {
					Text(notes)
						.font(.callout)
						.foregroundStyle(.secondary)
				}
			}
		}
	}

	private func completionPillColors(for reason: CompletionReason) -> (foreground: Color, background: Color) {
		switch reason {
		case .achieved:
			return (Color.green, Color.green.opacity(0.15))
		case .changed:
			return (Color.blue, Color.blue.opacity(0.15))
		case .abandoned:
			return (Color.orange, Color.orange.opacity(0.15))
		}
	}

	private func completionLabel(for reason: CompletionReason) -> String {
		switch reason {
		case .achieved:
			return String(localized: L10n.Goals.completionAchieved)
		case .changed:
			return String(localized: L10n.Goals.completionChanged)
		case .abandoned:
			return String(localized: L10n.Goals.completionAbandoned)
		}
	}
	
	private func displayValue(_ kg: Double) -> String {
		guard let unit = dataManager.settings?.preferredUnit else {
			return String(format: "%.1f kg", kg)
		}
		let value = unit.convert(fromKg: kg)
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return String(format: "%.*f %@", precision, value, unit.symbol as NSString)
	}
}

struct ExportView: View {
	let csvData: String
	@Environment(\.dismiss) var dismiss

	private var trimmedCSV: String {
		csvData.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var hasContent: Bool {
		!trimmedCSV.isEmpty
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					Text(String(localized: L10n.Export.hint))
						.font(.callout)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.leading)

					if hasContent {
						TrimlyCardContainer(style: .popup) {
							ScrollView(.horizontal, showsIndicators: true) {
								Text(verbatim: csvData)
									.font(.system(.caption, design: .monospaced))
									.multilineTextAlignment(.leading)
									.textSelection(.enabled)
									.frame(maxWidth: .infinity, alignment: .topLeading)
							}
						}
					} else {
						ContentUnavailableView(
							String(localized: L10n.Export.emptyTitle),
							systemImage: "doc.text.magnifyingglass",
							description: Text(L10n.Export.emptyDescription)
						)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(24)
			}
			.navigationTitle(Text(L10n.Export.navigationTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.doneButton)) { dismiss() }
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
