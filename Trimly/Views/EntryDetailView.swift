import SwiftUI

struct EntryDetailView: View {
    let entry: WeightEntry
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var notes = ""
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    EntryRow(entry: entry, preferredUnit: dataManager.settings?.preferredUnit ?? .kilograms,
                             decimalPrecision: dataManager.settings?.decimalPrecision ?? 1)
                    Text(entry.timestamp, format: .dateTime.day().month().year().hour().minute())
                    LabeledContent {
                        Text(entry.source == .healthKit ? L10n.Timeline.healthKitLabel : L10n.EntryFeatures.manual)
                    } label: { Text(L10n.EntryFeatures.source) }
                }
                Section {
                    TextField(String(localized: L10n.AddEntry.notesPlaceholder), text: $notes, axis: .vertical)
                        .lineLimit(3...12)
                        .accessibilityLabel(Text(L10n.Accessibility.notes))
                    Button(L10n.EntryFeatures.saveNotes) {
                        perform {
                            try dataManager.updateEntry(entry, notes: notes.isEmpty ? nil : notes)
                        }
                    }
                    .disabled(notes == (entry.notes ?? ""))
                    .accessibilityLabel(Text(L10n.EntryFeatures.saveNotes))
                } header: { Text(L10n.AddEntry.notesTitle) }

                Section {
                    if entry.source == .manual {
                        Button(L10n.EntryFeatures.edit) { showingEditor = true }
                            .accessibilityLabel(Text(L10n.EntryFeatures.edit))
                    }
                    Button(entry.isHidden ? L10n.EntryFeatures.unhide : L10n.EntryFeatures.hide) {
                        perform { try dataManager.setEntryHidden(entry, isHidden: !entry.isHidden) }
                    }
                    .accessibilityLabel(Text(entry.isHidden ? L10n.EntryFeatures.unhide : L10n.EntryFeatures.hide))
                    .accessibilityHint(Text(L10n.EntryFeatures.visibilityHint))
                    Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                        Text(L10n.EntryFeatures.delete)
                    }
                    .accessibilityLabel(Text(L10n.EntryFeatures.delete))
                    Text(entry.source == .healthKit ? L10n.EntryFeatures.healthReadOnly : L10n.EntryFeatures.localEdits)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Text(L10n.EntryFeatures.details))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.doneButton) { dismiss() }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
            .sheet(isPresented: $showingEditor, onDismiss: { notes = entry.notes ?? "" }) {
                AddWeightEntryView(entry: entry)
            }
            .confirmationDialog(String(localized: L10n.EntryFeatures.delete), isPresented: $showingDeleteConfirmation) {
                Button(role: .destructive) {
                    guard dataManager.fetchAllEntries().count > 1 else {
                        errorMessage = String(localized: L10n.Timeline.lastEntryMessage)
                        return
                    }
                    perform {
                        try dataManager.deleteEntry(entry)
                        dismiss()
                    }
                } label: { Text(L10n.EntryFeatures.delete) }
            } message: { Text(L10n.EntryFeatures.deleteHint) }
            .alert(L10n.Common.errorTitle, isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button(L10n.Common.okButton, role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .onAppear { notes = entry.notes ?? "" }
        }
    }

    private func perform(_ action: () throws -> Void) {
        do { try action() }
        catch { errorMessage = error.localizedDescription }
    }
}

struct EntryDayDetailView: View {
    let date: Date
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var deviceSettings: DeviceSettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntry: WeightEntry?
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(dataManager.fetchEntriesForDate(date)) { entry in
                    Button { selectedEntry = entry } label: {
                        EntryRow(entry: entry, preferredUnit: dataManager.settings?.preferredUnit ?? .kilograms,
                                 decimalPrecision: dataManager.settings?.decimalPrecision ?? 1,
                                 hideWeight: deviceSettings.presentation.hideWeights)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text(L10n.EntryFeatures.details))
                }
            }
            .overlay {
                if dataManager.fetchEntriesForDate(date).isEmpty {
                    ContentUnavailableView(String(localized: L10n.Calendar.noEntry), systemImage: "calendar")
                }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .disabled(Calendar.current.startOfDay(for: date) > Date())
                        .accessibilityLabel(Text(L10n.Accessibility.addWeightEntry))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.doneButton) { dismiss() }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
            .sheet(item: $selectedEntry) { EntryDetailView(entry: $0) }
            .sheet(isPresented: $showingAdd) { AddWeightEntryView(initialDate: date) }
        }
    }
}
