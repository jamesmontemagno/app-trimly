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
            Form {
                Section {
                    HStack {
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.title.bold())
                        
                        Text(dataManager.settings?.preferredUnit.symbol ?? "kg")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    DatePicker("Date & Time", selection: $selectedDate)
                }
                
                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Add Weight")
            .navigationBarTitleDisplayMode(.inline)
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
