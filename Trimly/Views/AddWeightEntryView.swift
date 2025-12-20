//
//  AddWeightEntryView.swift
//  TrimTally
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct AddWeightEntryView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var deviceSettings: DeviceSettingsStore
	@EnvironmentObject var celebrationService: CelebrationService
	@StateObject private var healthKitService = HealthKitService()
	@Environment(\.dismiss) var dismiss
    
	@State private var weightText = ""
	@State private var selectedDate = Date()
	@State private var notes = ""
	@State private var showingError = false
	@State private var errorMessage = ""
	@State private var showHealthKitSuccess = false
	@FocusState private var focusedField: Field?
	@ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 46

	private enum Field: Hashable {
		case weight
		case notes
	}
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					TrimlyCardSection(
						title: String(localized: L10n.AddEntry.weightCardTitle),
						description: String(localized: L10n.AddEntry.weightDescription(unitSymbol)),
						style: .popup
					) {
						VStack(alignment: .leading, spacing: 12) {
							HStack(alignment: .firstTextBaseline, spacing: 12) {
								TextField(String(localized: L10n.AddEntry.weightPlaceholder), text: $weightText)
									.textFieldStyle(.plain)
								#if os(iOS)
									.keyboardType(.decimalPad)
								#endif
									.font(.system(size: weightFontSize, weight: .bold, design: .rounded))
									.task {
										focusedField = .weight
									}
									.frame(maxWidth: .infinity, alignment: .leading)
									.focused($focusedField, equals: .weight)
									.accessibilityLabel(String(localized: L10n.Accessibility.weightValue))
									.accessibilityHint(String(localized: L10n.Accessibility.weightValueHint(unitSymbol)))

								Text(unitSymbol)
									.font(.title2.weight(.semibold))
									.foregroundStyle(.secondary)
									.accessibilityHidden(true)
							}
							.padding(.vertical, 6)
							.padding(.horizontal, 12)
							.background(inputBackgroundColor)
							.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

								Text(L10n.AddEntry.storageNote)
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}

						TrimlyCardSection(
							title: String(localized: L10n.AddEntry.dateTitle),
							description: String(localized: L10n.AddEntry.dateDescription),
							style: .popup
						) {
							DatePicker(String(localized: L10n.AddEntry.dateTitle), selection: $selectedDate, in: ...Date())
						#if os(iOS)
							.datePickerStyle(.compact)
						#endif
							.accessibilityLabel(String(localized: L10n.Accessibility.dateAndTime))
					}

						TrimlyCardSection(
							title: String(localized: L10n.AddEntry.notesTitle),
							description: String(localized: L10n.AddEntry.notesDescription),
							style: .popup
						) {
							TextField(String(localized: L10n.AddEntry.notesPlaceholder), text: $notes, axis: .vertical)
							.textFieldStyle(.plain)
							.lineLimit(3...6)
							.padding(.vertical, 10)
							.padding(.horizontal, 12)
							.background(inputBackgroundColor)
							.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
							.focused($focusedField, equals: .notes)
							.accessibilityLabel(String(localized: L10n.Accessibility.notes))
							.accessibilityHint(String(localized: L10n.Accessibility.notesHint))
					}
				}
				.padding(24)
			}
#if os(iOS)
			.scrollDismissesKeyboard(.interactively)
#endif
				.navigationTitle(Text(L10n.AddEntry.navigationTitle))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(String(localized: L10n.Common.cancelButton)) {
						dismiss()
					}
				}
                
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.saveButton)) {
						saveEntry()
					}
					.buttonStyle(.borderedProminent)
					.tint(.accentColor)
					.disabled(weightText.isEmpty)
					.accessibilityHint(String(localized: L10n.Accessibility.saveEntryHint))
				}
#if os(iOS)
				ToolbarItemGroup(placement: .keyboard) {
					Spacer()
					Button(String(localized: L10n.Common.doneButton)) {
						focusedField = nil
					}
					.buttonStyle(.borderedProminent)
					.tint(.accentColor)
				}
#endif
			}
				.alert(L10n.Common.errorTitle, isPresented: $showingError) {
					Button(String(localized: L10n.Common.okButton), role: .cancel) { }
			} message: {
				Text(errorMessage)
			}
		}
	}

	private var unitSymbol: String {
		dataManager.settings?.preferredUnit.symbol ?? "kg"
	}

	private var inputBackgroundColor: Color {
		#if os(macOS)
		return Color(nsColor: .textBackgroundColor).opacity(0.9)
		#else
		return Color(.tertiarySystemBackground)
		#endif
	}
    
	private func saveEntry() {
		guard let weight = Double(weightText) else {
			errorMessage = String(localized: L10n.AddEntry.errorInvalidWeight)
			showingError = true
			return
		}
        
		guard weight > 0 else {
			errorMessage = String(localized: L10n.AddEntry.errorNonPositiveWeight)
			showingError = true
			return
		}
        
		guard selectedDate <= Date() else {
			errorMessage = String(localized: L10n.AddEntry.errorFutureDate)
			showingError = true
			return
		}
        
		guard let unit = dataManager.settings?.preferredUnit else {
			errorMessage = String(localized: L10n.AddEntry.errorMissingSettings)
			showingError = true
			return
		}
        
		let weightKg = unit.convertToKg(weight)
		
		do {
			focusedField = nil
			try dataManager.addWeightEntry(
				weightKg: weightKg,
				timestamp: selectedDate,
				unit: unit,
				notes: notes.isEmpty ? nil : notes
			)
			
			// Check for all celebrations after saving entry
			celebrationService.checkAllCelebrations(dataManager: dataManager)
			
			if deviceSettings.healthKit.writeEnabled {
				Task {
					do {
						try await healthKitService.saveWeightToHealthKit(weightKg: weightKg, timestamp: selectedDate)
						showHealthKitSuccess = true
					} catch {
						// Show a gentle, one-time warning if HealthKit write fails
						if !showHealthKitSuccess {
							errorMessage = String(localized: L10n.Health.writeFailedHint)
							showingError = true
						}
					}
				}
			}
			dismiss()
		} catch {
			errorMessage = String(localized: L10n.AddEntry.errorSaveFailure(error.localizedDescription))
			showingError = true
		}
	}
}

#Preview {
	AddWeightEntryView()
		.environmentObject(DataManager(inMemory: true))
		.environmentObject(DeviceSettingsStore())
		.environmentObject(CelebrationService())
}
