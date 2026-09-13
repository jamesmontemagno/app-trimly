import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject private var deviceSettings: DeviceSettingsStore
    @State private var showingAddEntry = false
    @State private var showingFilters = false
    @State private var selectedEntry: WeightEntry?
    @State private var editingEntry: WeightEntry?
    @State private var selectedDay: IdentifiableDate?
    @State private var searchText = ""
    @State private var sourceFilter = EntrySourceFilter.all
    @State private var hiddenOnly = false
    @State private var notesOnly = false
    @State private var dateFilter = false
    @State private var startDate = Calendar.current.startOfDay(for: Date())
    @State private var endDate = Date()
    @State private var jumpDate = Date()
    @State private var entries: [WeightEntry] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedEntries, id: \.date) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            Button { selectedEntry = entry } label: {
                                EntryRow(entry: entry,
                                         preferredUnit: dataManager.settings?.preferredUnit ?? .kilograms,
                                         decimalPrecision: dataManager.settings?.decimalPrecision ?? 1,
                                         hideWeight: deviceSettings.presentation.hideWeights)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(Text(L10n.EntryFeatures.details))
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                if entry.source == .manual {
                                    Button {
                                        editingEntry = entry
                                    } label: {
                                        Label(L10n.EntryFeatures.edit, systemImage: "pencil")
                                    }
                                    .tint(.accentColor)
                                    .accessibilityLabel(Text(L10n.EntryFeatures.edit))
                                }
                            }
                        }
                        .onDelete { deleteEntries(at: $0, in: group.entries) }
                    } header: {
                        DayHeader(date: group.date, entries: group.entries,
                                  preferredUnit: dataManager.settings?.preferredUnit ?? .kilograms,
                                  decimalPrecision: dataManager.settings?.decimalPrecision ?? 1,
                                  dailyAggregationMode: dataManager.settings?.dailyAggregationMode ?? .latest,
                                  hideWeight: deviceSettings.presentation.hideWeights)
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text(L10n.EntryFeatures.search))
            .navigationTitle(Text(L10n.Timeline.navigationTitle))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddEntry = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(Text(L10n.Accessibility.addWeightEntry))
                }
                ToolbarItem {
                    Button { showingFilters = true } label: { Image(systemName: "line.3.horizontal.decrease") }
                        .accessibilityLabel(Text(L10n.EntryFeatures.filters))
                }
            }
            .sheet(isPresented: $showingAddEntry) { AddWeightEntryView() }
            .sheet(item: $selectedEntry) { EntryDetailView(entry: $0) }
            .sheet(item: $editingEntry) { AddWeightEntryView(entry: $0) }
            .sheet(item: $selectedDay) { EntryDayDetailView(date: $0.date) }
            .sheet(isPresented: $showingFilters, onDismiss: {
                if let pendingDay {
                    selectedDay = IdentifiableDate(date: pendingDay)
                    self.pendingDay = nil
                }
            }) { filters }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        String(localized: L10n.EntryFeatures.noMatches),
                        systemImage: "magnifyingglass",
                        description: Text(L10n.EntryFeatures.noMatchesHint)
                    )
                }
            }
            .task(id: queryID) { reload() }
            .onChange(of: dataManager.dataRevision) { _, _ in reload() }
            .alert(L10n.Common.errorTitle, isPresented: errorPresented) {
                Button(L10n.Common.okButton, role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var filters: some View {
        NavigationStack {
            Form {
                Picker(selection: $sourceFilter) {
                    ForEach(EntrySourceFilter.allCases) { Text($0.title).tag($0) }
                } label: { Text(L10n.EntryFeatures.source) }
                .accessibilityLabel(Text(L10n.EntryFeatures.source))
                Toggle(isOn: $hiddenOnly) { Text(L10n.EntryFeatures.hiddenOnly) }
                    .accessibilityLabel(Text(L10n.EntryFeatures.hiddenOnly))
                Toggle(isOn: $notesOnly) { Text(L10n.EntryFeatures.notesOnly) }
                    .accessibilityLabel(Text(L10n.EntryFeatures.notesOnly))
                Toggle(isOn: $dateFilter) { Text(L10n.EntryFeatures.dateRange) }
                    .accessibilityLabel(Text(L10n.EntryFeatures.dateRange))
                if dateFilter {
                    DatePicker(selection: $startDate, in: ...Date(), displayedComponents: .date) { Text(L10n.EntryFeatures.from) }
                        .accessibilityLabel(Text(L10n.EntryFeatures.from))
                    DatePicker(selection: $endDate, in: ...Date(), displayedComponents: .date) { Text(L10n.EntryFeatures.through) }
                        .accessibilityLabel(Text(L10n.EntryFeatures.through))
                }
                Section {
                    DatePicker(selection: $jumpDate, in: ...Date(), displayedComponents: .date) { Text(L10n.EntryFeatures.day) }
                        .accessibilityLabel(Text(L10n.EntryFeatures.day))
                    Button(L10n.EntryFeatures.openDay) {
                        pendingDay = jumpDate
                        showingFilters = false
                    }
                    .accessibilityLabel(Text(L10n.EntryFeatures.openDay))
                }
                Button(L10n.EntryFeatures.clearFilters) {
                    searchText = ""
                    sourceFilter = .all
                    hiddenOnly = false
                    notesOnly = false
                    dateFilter = false
                }
                .accessibilityLabel(Text(L10n.EntryFeatures.clearFilters))
            }
            .navigationTitle(Text(L10n.EntryFeatures.filters))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.doneButton) { showingFilters = false }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
        }
    }

    @State private var pendingDay: Date?

    private var queryID: String {
        "\(searchText)|\(sourceFilter.rawValue)|\(hiddenOnly)|\(notesOnly)|\(dateFilter)|\(startDate)|\(endDate)"
    }

    private var groupedEntries: [DayGroup] {
        Dictionary(grouping: entries) { WeightEntry.normalizeDate($0.timestamp) }
            .map { DayGroup(date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func reload() {
        do {
            let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate))
            let results = try dataManager.fetchEntries(
                startDate: dateFilter ? Calendar.current.startOfDay(for: startDate) : nil,
                endDate: dateFilter ? end : nil, source: sourceFilter.source,
                includeHidden: hiddenOnly, notesOnly: notesOnly, searchText: searchText
            )
            entries = hiddenOnly ? results.filter(\.isHidden) : results
        } catch {
            entries = []
            errorMessage = error.localizedDescription
        }
    }

    private func deleteEntries(at offsets: IndexSet, in group: [WeightEntry]) {
        let selected = offsets.compactMap { group.indices.contains($0) ? group[$0] : nil }
        guard dataManager.fetchAllEntries().count > selected.count else {
            errorMessage = String(localized: L10n.Timeline.lastEntryMessage)
            return
        }
        do {
            for entry in selected { try dataManager.deleteEntry(entry) }
        } catch {
            errorMessage = error.localizedDescription
        }
        reload()
    }
}

private enum EntrySourceFilter: String, CaseIterable, Identifiable {
    case all, manual, healthKit
    var id: String { rawValue }
    var source: EntrySource? {
        switch self {
        case .all: return nil
        case .manual: return .manual
        case .healthKit: return .healthKit
        }
    }
    var title: LocalizedStringResource {
        switch self {
        case .all: return L10n.EntryFeatures.allSources
        case .manual: return L10n.EntryFeatures.manual
        case .healthKit: return L10n.Timeline.healthKitLabel
        }
    }
}

struct DayGroup {
    let date: Date
    let entries: [WeightEntry]
}

struct DayHeader: View {
    let date: Date
    let entries: [WeightEntry]
    let preferredUnit: WeightUnit
    let decimalPrecision: Int
    let dailyAggregationMode: DailyAggregationMode
    var hideWeight = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date, style: .date).font(.headline)
            if !hideWeight, let weight = WeightAnalytics.aggregateByDay(entries: entries, mode: dailyAggregationMode)[WeightEntry.normalizeDate(date)] {
                Text(L10n.Timeline.dailyValue("\(EntryInput.display(preferredUnit.convert(fromKg: weight), precision: decimalPrecision)) \(preferredUnit.symbol)"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct EntryRow: View {
    let entry: WeightEntry
    let preferredUnit: WeightUnit
    let decimalPrecision: Int
    var hideWeight = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if hideWeight {
                    Label(String(localized: L10n.Insights.privacyTitle), systemImage: "eye.slash")
                } else {
                    Text("\(EntryInput.display(preferredUnit.convert(fromKg: entry.weightKg), precision: decimalPrecision)) \(preferredUnit.symbol)")
                        .font(.title3.bold())
                }
                Spacer()
                Text(entry.timestamp, style: .time).foregroundStyle(.secondary)
            }
            if entry.source == .healthKit {
                Label(String(localized: L10n.Timeline.healthKitLabel), systemImage: "heart")
                    .font(.caption)
            }
            if entry.isHidden {
                Label(String(localized: L10n.EntryFeatures.hidden), systemImage: "eye.slash")
                    .font(.caption)
            }
            if !hideWeight, let notes = entry.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
