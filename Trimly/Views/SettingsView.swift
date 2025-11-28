//
//  SettingsView.swift
//  Trimly
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
						title: "Personalization",
						description: "Fine-tune how Trimly displays your weight, decimals, and appearance."
					) {
						settingsRow(
							icon: "scalemass",
							title: "Weight Unit",
							subtitle: "Display entries in your preferred unit.",
							accessoryPlacement: .below
						) {
							Picker("Weight Unit", selection: binding(\.preferredUnit)) {
								Text("Pounds").tag(WeightUnit.pounds)
								Text("Kilograms").tag(WeightUnit.kilograms)
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
						
						sectionDivider()
						
						settingsRow(
							icon: "number",
							title: "Decimal Precision",
							subtitle: "Control the number of decimal places you see.",
							accessoryPlacement: .below
						) {
							Picker("Decimal Precision", selection: binding(\.decimalPrecision)) {
								Text("1 place").tag(1)
								Text("2 places").tag(2)
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
						
						sectionDivider()
						
						settingsRow(
							icon: "circle.lefthalf.filled",
							title: "Theme",
							subtitle: "Choose Trimly's appearance.",
							accessoryPlacement: .below
						) {
							Picker("Theme", selection: binding(\.appearance)) {
								ForEach(AppAppearance.allCases) { option in
									Text(option.displayName).tag(option)
								}
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
					}
					
					settingsSection(title: "Goals") {
						if let goal = dataManager.fetchActiveGoal() {
							Button {
								showingGoalSheet = true
							} label: {
								settingsRow(
									icon: "flag.checkered",
									title: "Current Goal",
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
									title: "Goal History",
									subtitle: "See past targets and outcomes.",
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
									title: "Set Goal",
									subtitle: "Track progress toward a target weight.",
									showChevron: true
								)
							}
							.buttonStyle(.plain)
						}
					}
					
					settingsSection(
						title: "Daily Value",
						description: "Choose how Trimly treats multiple entries recorded in the same day."
					) {
						settingsRow(
							icon: "calendar.day.timeline.left",
							title: "Daily Calculation",
							subtitle: "Latest entry or daily average.",
							accessoryPlacement: .below
						) {
							Picker("Daily Value", selection: binding(\.dailyAggregationMode)) {
								Text("Latest").tag(DailyAggregationMode.latest)
								Text("Average").tag(DailyAggregationMode.average)
							}
							.labelsHidden()
							.pickerStyle(.segmented)
						}
					}
					
					settingsSection(title: "Habits & Reminders") {
						NavigationLink {
							RemindersView()
						} label: {
							settingsRow(
								icon: "bell.badge.fill",
								title: "Reminders",
								subtitle: dataManager.settings?.reminderTime != nil ? "Daily nudges to log your weight." : "Set a daily reminder to stay consistent.",
								showChevron: true
							) {
								if dataManager.settings?.reminderTime != nil {
									statusPill(text: "On", color: .green)
								} else {
									statusPill(text: "Off", color: .secondary)
								}
							}
						}
						.buttonStyle(.plain)
					}
					
					settingsSection(title: "Integrations") {
						NavigationLink {
							HealthKitView()
						} label: {
							settingsRow(
								icon: "heart.fill",
								title: "Apple Health",
								subtitle: "Import and sync weight data.",
								showChevron: true,
								iconTint: .pink
							) {
								if dataManager.settings?.healthKitEnabled == true {
									statusPill(text: "Connected", color: .green)
								}
							}
						}
						.buttonStyle(.plain)
					}
					
					settingsSection(title: "Consistency Score") {
						settingsRow(
							icon: "chart.bar.fill",
							title: "Window Length",
							subtitle: "Currently \(dataManager.settings?.consistencyScoreWindow ?? 30) days."
						) {
							Stepper("", value: binding(\.consistencyScoreWindow), in: 7...90, step: 1)
								.labelsHidden()
						}
					}
					
					settingsSection(title: "Data & Privacy") {
						Button {
							exportData()
						} label: {
							settingsRow(
								icon: "square.and.arrow.up",
								title: "Export Data",
								subtitle: "Create a CSV copy of your entries.",
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
								title: "Delete All Data",
								subtitle: "Remove every entry from this device.",
								showChevron: true,
								iconTint: .red
							)
						}
						.buttonStyle(.plain)
					}
					
					settingsSection(title: "About Trimly") {
						HStack {
							Text("Version")
							Spacer()
							Text("1.0.0")
								.foregroundStyle(.secondary)
						}
						
						sectionDivider()
						
						Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
							.font(.body.weight(.semibold))
						Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
							.font(.body.weight(.semibold))
					}
				}
				.padding(.horizontal, 24)
				.padding(.top, 32)
				.padding(.bottom, 48)
			}
			.scrollIndicators(.hidden)
			.background(Color.clear)
			.navigationTitle("Settings")
			.sheet(isPresented: $showingGoalSheet) { GoalSetupView() }
			.sheet(isPresented: $showingGoalHistory) { GoalHistoryView() }
			.sheet(isPresented: $showingExport) { ExportView(csvData: exportedData) }
			.confirmationDialog("Delete All Data", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
				Button("Delete All Data", role: .destructive) { deleteAllData() }
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
					TrimlyCardSection(title: "Target Weight", description: "Enter a value in \(dataManager.settings?.preferredUnit.symbol ?? "kg").", style: .popup) {
						HStack(spacing: 12) {
							TextField("145", text: $targetWeightText)
								#if os(iOS)
								.keyboardType(.decimalPad)
								#endif
							Text(dataManager.settings?.preferredUnit.symbol ?? "kg")
								.foregroundStyle(.secondary)
						}
					}
					
					TrimlyCardSection(title: "Notes", description: "Optional context you'll revisit later.", style: .popup) {
						TextField("Why this goal matters", text: $notes, axis: .vertical)
							.lineLimit(3...6)
					}
					
					Text("We use your preferred units and precision settings to track progress and estimate timelines.")
						.font(.callout)
						.foregroundStyle(.secondary)
				}
				.padding(24)
			}
			.navigationTitle("Set Goal")
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") { saveGoal() }
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
			try dataManager.setGoal(targetWeightKg: weightKg,
									startingWeightKg: currentWeight,
									notes: notes.isEmpty ? nil : notes)
			dismiss()
		} catch {
			errorMessage = "Failed to save goal: \(error.localizedDescription)"
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
			.navigationTitle("Goal History")
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") { dismiss() }
				}
			}
			.overlay {
				if history.isEmpty {
					ContentUnavailableView("No Goal History",
											 systemImage: "flag",
											 description: Text("Past goals will appear here"))
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
						Text(reason.rawValue.capitalized)
							.font(.caption.weight(.semibold))
							.padding(.horizontal, 10)
							.padding(.vertical, 4)
							.background(pill.background)
							.foregroundStyle(pill.foreground)
							.clipShape(Capsule())
					}
				}
				Text("Set on \(goal.startDate.formatted(date: .abbreviated, time: .omitted))")
					.font(.caption)
					.foregroundStyle(.secondary)
				if let completedDate = goal.completedDate {
					Text("Completed on \(completedDate.formatted(date: .abbreviated, time: .omitted))")
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

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					Text("Copy or share your data export. Each row includes a timestamp, normalized date, and weight in kilograms.")
						.font(.callout)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.leading)

					TrimlyCardContainer(style: .popup) {
						Text(csvData)
							.font(.system(.caption, design: .monospaced))
							.textSelection(.enabled)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
				}
				.padding(24)
			}
			.navigationTitle("Export Data")
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") { dismiss() }
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
