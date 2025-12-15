//
//  GoalSetupView.swift
//  TrimTally
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
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {

					TrimlyCardSection(
						title: String(localized: L10n.Goals.targetTitle),
						description: String(localized: L10n.Goals.targetDescription(preferredUnit.symbol)),
						style: .popup
					) {
						HStack(spacing: 12) {
							TextField(String(localized: L10n.Goals.targetPlaceholder), text: $targetWeightText)
								#if os(iOS)
								.keyboardType(.decimalPad)
								#endif
							Text(preferredUnit.symbol)
								.foregroundStyle(.secondary)
						}
					}

						TrimlyCardSection(
						title: String(localized: L10n.Goals.startTitle),
						description: String(localized: L10n.Goals.startDescription(preferredUnit.symbol)),
						style: .popup
					) {
						HStack(spacing: 12) {
							TextField(String(localized: L10n.Goals.startPlaceholder), text: $startingWeightText)
							#if os(iOS)
							.keyboardType(.decimalPad)
							#endif
							Text(preferredUnit.symbol)
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
			.navigationTitle(Text(mode == .edit ? "Edit Goal" : L10n.Goals.setupTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(String(localized: L10n.Common.cancelButton)) { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.saveButton)) { saveGoal() }
						.buttonStyle(.borderedProminent)
						.tint(.accentColor)
						.disabled(saveButtonDisabled)
				}
			}
			.alert(L10n.Common.errorTitle, isPresented: $showingError) {
				Button(String(localized: L10n.Common.okButton), role: .cancel) { }
			} message: {
				Text(errorMessage)
			}
		}
		.task {
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
		guard let start = Double(startingWeightText), start > 0,
			  let target = Double(targetWeightText), target > 0 else {
			return true
		}
		return false
	}

	private func formattedDisplayWeight(fromKg kg: Double) -> String {
		let unitValue = preferredUnit.convert(fromKg: kg)
		let format: String
		switch decimalPrecision {
		case ..<1:
			format = "%.0f"
		case 1:
			format = "%.1f"
		default:
			format = "%.2f"
		}
		return String(format: format, unitValue)
	}

	private func prefillDefaults() {
		if mode == .edit, let goal = dataManager.fetchActiveGoal() {
			targetWeightText = formattedDisplayWeight(fromKg: goal.targetWeightKg)
			if let startingKg = goal.startingWeightKg {
				startingWeightText = formattedDisplayWeight(fromKg: startingKg)
			}
			notes = goal.notes ?? ""
		} else if startingWeightText.isEmpty, let current = dataManager.getCurrentWeight() {
			startingWeightText = formattedDisplayWeight(fromKg: current)
		}
	}

	private func saveGoal() {
		guard let starting = Double(startingWeightText), starting > 0 else {
			errorMessage = String(localized: L10n.Goals.errorMissingStartingWeight)
			showingError = true
			return
		}
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
		let weightKg = preferredUnit.convertToKg(weight)
		let startingKg = preferredUnit.convertToKg(starting)
		do {
			if mode == .edit {
				// Edit mode: update existing goal
				try dataManager.updateGoal(
					targetWeightKg: weightKg,
					startingWeightKg: startingKg,
					notes: notes.isEmpty ? nil : notes
				)
			} else {
				// New mode: create new goal (archives old one)
				// When setting a goal from Settings, also log a corresponding entry
				// so history and analytics align with the new starting point.
				try dataManager.addWeightEntry(
					weightKg: startingKg,
					unit: preferredUnit
				)
				try dataManager.setGoal(targetWeightKg: weightKg,
								startingWeightKg: startingKg,
									notes: notes.isEmpty ? nil : notes)
			}
			dismiss()
		} catch {
			errorMessage = String(localized: L10n.Goals.errorSaveFailure(error.localizedDescription))
			showingError = true
		}
	}
}
