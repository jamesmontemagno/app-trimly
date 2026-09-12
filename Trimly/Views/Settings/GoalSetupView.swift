//
//  GoalSetupView.swift
//  My Weight
//
//  Created by Trimly on 12/07/2025.
//

import SwiftUI

enum GoalMode {
	case new
	case edit
}

struct GoalSetupView: View {
	@EnvironmentObject var dataManager: DataManager
	@Environment(\.dismiss) var dismiss
	
	let mode: GoalMode
    
	@State private var targetWeightText = ""
	@State private var startingWeightText = ""
	@State private var notes = ""
	@State private var showingError = false
	@State private var errorMessage = ""
	@State private var hasDeadline = false
	@State private var deadline = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
	@State private var didLoad = false
	@State private var originalTargetText = ""
	@State private var originalStartText = ""
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {

					WeighCardSection(
						title: String(localized: L10n.Goals.targetTitle),
						description: String(localized: L10n.Goals.targetDescription(preferredUnit.symbol)),
						style: .popup
					) {
						HStack(spacing: 12) {
							TextField(String(localized: L10n.Goals.targetPlaceholder), text: $targetWeightText)
								.accessibilityLabel(Text(L10n.Goals.targetTitle))
								#if os(iOS)
								.keyboardType(.decimalPad)
								#endif
							Text(preferredUnit.symbol)
								.foregroundStyle(.secondary)
						}
					}

						WeighCardSection(
						title: String(localized: L10n.Goals.startTitle),
						description: String(localized: L10n.Goals.startDescription(preferredUnit.symbol)),
						style: .popup
					) {
						HStack(spacing: 12) {
							TextField(String(localized: L10n.Goals.startPlaceholder), text: $startingWeightText)
								.accessibilityLabel(Text(L10n.Goals.startTitle))
							#if os(iOS)
							.keyboardType(.decimalPad)
							#endif
							Text(preferredUnit.symbol)
								.foregroundStyle(.secondary)
						}
					}
					WeighCardSection(title: String(localized: L10n.EntryFeatures.deadline), style: .popup) {
							Toggle(isOn: $hasDeadline) { Text(L10n.EntryFeatures.useDeadline) }
								.accessibilityLabel(Text(L10n.EntryFeatures.useDeadline))
							if hasDeadline {
								DatePicker(selection: $deadline, displayedComponents: .date) {
									Text(L10n.EntryFeatures.deadline)
								}
								.accessibilityLabel(Text(L10n.EntryFeatures.deadline))
							}
							Text(L10n.EntryFeatures.deadlineHint).font(.caption).foregroundStyle(.secondary)
					}
					
					WeighCardSection(
						title: String(localized: L10n.Goals.notesTitle),
						description: String(localized: L10n.Goals.notesDescription),
						style: .popup
					) {
						TextField(String(localized: L10n.Goals.notesPlaceholder), text: $notes, axis: .vertical)
							.lineLimit(3...6)
							.accessibilityLabel(Text(L10n.Goals.notesTitle))
					}
					
					Text(L10n.Goals.unitHint)
						.font(.callout)
						.foregroundStyle(.secondary)
				}
				.padding(24)
			}
			.navigationTitle(Text(mode == .edit ? L10n.EntryFeatures.editGoal : L10n.Goals.setupTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(String(localized: L10n.Common.cancelButton)) { dismiss() }
						.accessibilityLabel(Text(L10n.Common.cancelButton))
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.saveButton)) { saveGoal() }
						.buttonStyle(.borderedProminent)
						.tint(.accentColor)
						.disabled(saveButtonDisabled)
						.accessibilityLabel(Text(L10n.Common.saveButton))
				}
			}
			.alert(L10n.Common.errorTitle, isPresented: $showingError) {
				Button(String(localized: L10n.Common.okButton), role: .cancel) { }
			} message: {
				Text(errorMessage)
			}
		}
		.task {
			guard !didLoad else { return }
			didLoad = true
			prefillDefaults()
		}
	}
    
	private var preferredUnit: WeightUnit {
		dataManager.settings?.preferredUnit ?? .pounds
	}

	private var decimalPrecision: Int {
		let precision = dataManager.settings?.decimalPrecision ?? 1
		return min(max(precision, 0), 2)
	}

	private var saveButtonDisabled: Bool {
		guard EntryInput.weight(startingWeightText) != nil,
			  EntryInput.weight(targetWeightText) != nil else {
			return true
		}
		return false
	}

	private func formattedDisplayWeight(fromKg kg: Double) -> String {
		EntryInput.display(preferredUnit.convert(fromKg: kg), precision: decimalPrecision)
	}

	private func prefillDefaults() {
		if mode == .edit, let goal = dataManager.fetchActiveGoal() {
			targetWeightText = formattedDisplayWeight(fromKg: goal.targetWeightKg)
			if let startingKg = goal.startingWeightKg {
				startingWeightText = formattedDisplayWeight(fromKg: startingKg)
			}
			notes = goal.notes ?? ""
			hasDeadline = goal.targetDate != nil
			deadline = goal.targetDate ?? deadline
			originalTargetText = targetWeightText
			originalStartText = startingWeightText
		} else if startingWeightText.isEmpty, let current = dataManager.getCurrentVisibleWeight() {
			startingWeightText = formattedDisplayWeight(fromKg: current)
		}
	}

	private func saveGoal() {
		guard let starting = EntryInput.weight(startingWeightText) else {
			errorMessage = String(localized: L10n.Goals.errorMissingStartingWeight)
			showingError = true
			return
		}
		guard let weight = EntryInput.weight(targetWeightText) else {
			errorMessage = String(localized: L10n.Goals.errorInvalidWeight)
			showingError = true
			return
		}
		guard weight > 0 else {
			errorMessage = String(localized: L10n.Goals.errorNonPositiveWeight)
			showingError = true
			return
		}
		let currentGoal = mode == .edit ? dataManager.fetchActiveGoal() : nil
		let weightKg = currentGoal.flatMap { targetWeightText == originalTargetText ? $0.targetWeightKg : nil }
			?? preferredUnit.convertToKg(weight)
		let startingKg = currentGoal.flatMap { startingWeightText == originalStartText ? $0.startingWeightKg : nil }
			?? preferredUnit.convertToKg(starting)
		do {
			if mode == .edit {
				// Edit mode: update existing goal
				try dataManager.updateGoal(
					targetWeightKg: weightKg,
					startingWeightKg: startingKg,
					targetDate: hasDeadline ? deadline : nil,
					notes: notes.isEmpty ? nil : notes
				)
			} else {
				if dataManager.hasAnyEntries() {
					try dataManager.setGoal(
						targetWeightKg: weightKg,
						startingWeightKg: startingKg,
						targetDate: hasDeadline ? deadline : nil,
						notes: notes.isEmpty ? nil : notes
					)
				} else {
					try dataManager.setGoalAndCreateStartingEntry(
						targetWeightKg: weightKg,
						startingWeightKg: startingKg,
						targetDate: hasDeadline ? deadline : nil,
						notes: notes.isEmpty ? nil : notes,
						unit: preferredUnit
					)
				}
			}
			dismiss()
		} catch {
			errorMessage = String(localized: L10n.Goals.errorSaveFailure(error.localizedDescription))
			showingError = true
		}
	}
}
