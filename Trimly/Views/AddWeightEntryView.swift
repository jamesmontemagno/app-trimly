//
//  AddWeightEntryView.swift
//  Trimly
//
//  Created by Trimly on 11/19/2025.
//

import SwiftUI

struct AddWeightEntryView: View {
	@EnvironmentObject var dataManager: DataManager
	@Environment(\.dismiss) var dismiss
    
	@State private var weightText = ""
	@State private var selectedDate = Date()
	@State private var notes = ""
	@State private var showingError = false
	@State private var errorMessage = ""
    
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 20) {
					TrimlyCardSection(title: "Log Weight", description: "Enter today's reading in \(unitSymbol).", style: .popup) {
						VStack(alignment: .leading, spacing: 12) {
							HStack(alignment: .firstTextBaseline, spacing: 12) {
								TextField("0.0", text: $weightText)
									.textFieldStyle(.plain)
								#if os(iOS)
									.keyboardType(.decimalPad)
								#endif
									.font(.system(size: 46, weight: .bold, design: .rounded))
									.frame(maxWidth: .infinity, alignment: .leading)

								Text(unitSymbol)
									.font(.title2.weight(.semibold))
									.foregroundStyle(.secondary)
							}
							.padding(.vertical, 6)
							.padding(.horizontal, 12)
							.background(inputBackgroundColor)
							.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

							Text("Stored internally as kilograms so your analytics stay precise.")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}

					TrimlyCardSection(title: "Date & Time", description: "We normalize to your local day for charts.", style: .popup) {
						DatePicker("Date & Time", selection: $selectedDate)
						#if os(iOS)
							.datePickerStyle(.compact)
						#endif
					}

					TrimlyCardSection(title: "Notes", description: "Optional reflections or context.", style: .popup) {
						TextField("Morning weigh-in after run", text: $notes, axis: .vertical)
							.textFieldStyle(.plain)
							.lineLimit(3...6)
							.padding(.vertical, 10)
							.padding(.horizontal, 12)
							.background(inputBackgroundColor)
							.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
					}
				}
				.padding(24)
			}
			.navigationTitle("Add Weight")
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
                
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						saveEntry()
					}
					.disabled(weightText.isEmpty)
				}
			}
			.alert("Error", isPresented: $showingError) {
				Button("OK", role: .cancel) { }
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
        
		do {
			try dataManager.addWeightEntry(
				weightKg: weightKg,
				timestamp: selectedDate,
				unit: unit,
				notes: notes.isEmpty ? nil : notes
			)
			dismiss()
		} catch {
			errorMessage = "Failed to save entry: \(error.localizedDescription)"
			showingError = true
		}
	}
}

#Preview {
	AddWeightEntryView()
		.environmentObject(DataManager(inMemory: true))
}
