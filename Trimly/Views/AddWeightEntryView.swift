//
//  AddWeightEntryView.swift
//  My Weight
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct AddWeightEntryView: View {
	@EnvironmentObject var dataManager: DataManager
	@EnvironmentObject var deviceSettings: DeviceSettingsStore
	@StateObject private var healthKitService = HealthKitService()
	@Environment(\.dismiss) var dismiss
    
	@State private var weightText = ""
	@State private var selectedDate = Date()
	@State private var notes = ""
	@State private var showingError = false
	@State private var errorMessage = ""
	@State private var didLoad = false
	@State private var isSaving = false
	@State private var hasSaved = false
	@State private var originalWeightText = ""
	@State private var entryUnit: WeightUnit = .kilograms
	private let entry: WeightEntry?
	private let initialDate: Date?
	@FocusState private var focusedField: Field?
	@ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 46

	private enum Field: Hashable {
		case weight
		case notes
	}

	init(entry: WeightEntry? = nil, initialDate: Date? = nil) {
		self.entry = entry
		self.initialDate = initialDate
	}
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					WeighCardSection(
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

						WeighCardSection(
							title: String(localized: L10n.AddEntry.dateTitle),
							description: String(localized: L10n.AddEntry.dateDescription),
							style: .popup
						) {
							VStack(alignment: .leading, spacing: 12) {
								DatePicker(
									String(localized: L10n.AddEntry.dateTitle),
									selection: $selectedDate,
									in: ...Date()
								)
								.labelsHidden()
							#if os(iOS)
								.datePickerStyle(.compact)
							#endif
								.frame(maxWidth: .infinity, alignment: .leading)
								.accessibilityLabel(String(localized: L10n.Accessibility.dateAndTime))

								HStack(spacing: 12) {
									Button(L10n.EntryFeatures.now) { selectedDate = Date() }
										.frame(maxWidth: .infinity, minHeight: 44)
										.accessibilityLabel(Text(L10n.EntryFeatures.now))
									Button(L10n.EntryFeatures.yesterday) {
										if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
											selectedDate = yesterday
										}
									}
									.frame(maxWidth: .infinity, minHeight: 44)
									.accessibilityLabel(Text(L10n.EntryFeatures.yesterday))
								}
								.buttonStyle(.bordered)
							}
							.accessibilityElement(children: .contain)
					}

						WeighCardSection(
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
				.navigationTitle(Text(entry == nil ? L10n.AddEntry.navigationTitle : L10n.EntryFeatures.edit))
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(String(localized: L10n.Common.cancelButton)) {
						dismiss()
					}
					.disabled(isSaving)
					.accessibilityLabel(Text(L10n.Common.cancelButton))
				}
                
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: L10n.Common.saveButton)) {
						Task { await saveEntry() }
					}
					.buttonStyle(.borderedProminent)
					.tint(.accentColor)
					.disabled(weightText.isEmpty || isSaving || hasSaved)
					.accessibilityLabel(Text(L10n.Common.saveButton))
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
					Button(String(localized: L10n.Common.okButton), role: .cancel) {
						if hasSaved { dismiss() }
					}
			} message: {
				Text(errorMessage)
			}
			.interactiveDismissDisabled(isSaving)
			.task {
				guard !didLoad else { return }
				didLoad = true
				entryUnit = dataManager.settings?.preferredUnit ?? .kilograms
				if let entry {
					selectedDate = entry.timestamp
					notes = entry.notes ?? ""
					weightText = EntryInput.display(
						entryUnit.convert(fromKg: entry.weightKg), precision: dataManager.settings?.decimalPrecision ?? 1
					)
					originalWeightText = weightText
				} else if let initialDate {
					selectedDate = min(initialDate, Date())
				}
			}
		}
	}

	private var unitSymbol: String {
		entryUnit.symbol
	}

	private var inputBackgroundColor: Color {
		#if os(macOS)
		return Color(nsColor: .textBackgroundColor).opacity(0.9)
		#else
		return Color(.tertiarySystemBackground)
		#endif
	}
    
	@MainActor
	private func saveEntry() async {
		guard let weight = EntryInput.weight(weightText) else {
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
        
		let unit = entryUnit
		let weightKg = entry.flatMap { weightText == originalWeightText ? $0.weightKg : nil }
			?? unit.convertToKg(weight)
		isSaving = true
		defer { isSaving = false }
		
		do {
			focusedField = nil
			if let entry {
				try dataManager.updateEntry(entry, weightKg: weightKg, timestamp: selectedDate, unit: unit, notes: notes.isEmpty ? nil : notes)
			} else {
				try dataManager.addWeightEntry(weightKg: weightKg, timestamp: selectedDate, unit: unit, notes: notes.isEmpty ? nil : notes)
			}
			hasSaved = true
		} catch {
			errorMessage = String(localized: L10n.AddEntry.errorSaveFailure(error.localizedDescription))
			showingError = true
			return
		}
		if entry == nil && deviceSettings.healthKit.writeEnabled {
			do {
				try await healthKitService.saveWeightToHealthKit(weightKg: weightKg, timestamp: selectedDate)
			} catch {
				errorMessage = String(localized: L10n.EntryFeatures.savedHealthFailed)
				showingError = true
				return
			}
		}
		dismiss()
	}
}

#Preview {
	AddWeightEntryView()
		.environmentObject(DataManager(inMemory: true))
		.environmentObject(DeviceSettingsStore())
		.environmentObject(CelebrationService())
		.environmentObject(StoreManager())
		.environmentObject(AchievementService())
}
