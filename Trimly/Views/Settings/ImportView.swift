import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingImporter = false
    @State private var showingPaywall = false
    @State private var sourceText: String?
    @State private var table: WeightCSV.Table?
    @State private var hasHeader = true
    @State private var mapping = WeightCSV.Mapping()
    @State private var unit = WeightUnit.kilograms
    @State private var convention = WeightCSV.DateConvention.iso8601
    @State private var review: [WeightCSV.ReviewRow]?
    @State private var keepingDuplicates = Set<Int>()
    @State private var importedCount: Int?
    @State private var errorMessage: String?

    private var drafts: [WeightEntryDraft] {
        WeightCSV.draftsToImport(from: review ?? [], keepingDuplicates: keepingDuplicates)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(String(localized: L10n.Portability.chooseCSV)) { showingImporter = true }
                        .accessibilityLabel(Text(L10n.Portability.chooseCSV))
                } footer: {
                    Text(L10n.Portability.importExplanation)
                }
                if table != nil {
                    mappingSection
                    if let review {
                        reviewSection(review)
                        Section {
                            Text(L10n.Portability.readyCount(drafts.count))
                            Text(L10n.Portability.invalidCount(review.filter { $0.issue != nil }.count))
                            Button(String(localized: L10n.Portability.importSelected), action: importSelected)
                                .disabled(drafts.isEmpty)
                                .accessibilityLabel(Text(L10n.Portability.importSelected))
                        } footer: {
                            Text(L10n.Portability.importReviewHint)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text(L10n.Portability.importTitle))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.doneButton)) { dismiss() }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 560)
        #endif
        .onAppear { unit = dataManager.settings?.preferredUnit ?? .kilograms }
        .onChange(of: mapping) { _, _ in invalidateReview() }
        .onChange(of: unit) { _, _ in invalidateReview() }
        .onChange(of: convention) { _, _ in invalidateReview() }
        .onChange(of: hasHeader) { _, _ in rebuildTable() }
        .onChange(of: dataManager.dataRevision) { _, _ in invalidateReview() }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.commaSeparatedText, .plainText], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= WeightCSV.maximumBytes else { throw WeightCSV.Issue.tooLarge }
                sourceText = try WeightCSV.decode(Data(contentsOf: url, options: .mappedIfSafe))
                rebuildTable()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .alert(String(localized: L10n.Portability.importComplete), isPresented: Binding(
            get: { importedCount != nil },
            set: { if !$0 { importedCount = nil } }
        )) {
            Button(String(localized: L10n.Common.okButton)) { importedCount = nil }
        } message: {
            Text(L10n.Portability.importedCount(importedCount ?? 0))
        }
        .portabilityError($errorMessage)
    }

    private var mappingSection: some View {
        Section {
            Toggle(String(localized: L10n.Portability.hasHeader), isOn: $hasHeader)
                .accessibilityLabel(Text(L10n.Portability.hasHeader))
            columnPicker(L10n.Portability.dateColumn, selection: $mapping.timestamp)
            columnPicker(L10n.Portability.weightColumn, selection: $mapping.weight)
            optionalColumnPicker(L10n.Portability.unitColumn, selection: $mapping.unit)
            optionalColumnPicker(L10n.Portability.notesColumn, selection: $mapping.notes)
            if mapping.unit == nil { PortabilityUnitPicker(unit: $unit) }
            Picker(String(localized: L10n.Portability.dateConvention), selection: $convention) {
                ForEach(WeightCSV.DateConvention.allCases) { option in
                    Text(L10n.Portability.dateConventionName(option)).tag(option)
                }
            }
            .accessibilityLabel(Text(L10n.Portability.dateConvention))
            Button(String(localized: L10n.Portability.reviewImport), action: buildReview)
                .accessibilityLabel(Text(L10n.Portability.reviewImport))
        } header: {
            Text(L10n.Portability.columnMapping)
        } footer: {
            Text(L10n.Portability.mappingHint)
        }
    }

    private func columnPicker(_ title: LocalizedStringResource, selection: Binding<Int>) -> some View {
        Picker(String(localized: title), selection: selection) {
            ForEach(Array((table?.headers ?? []).enumerated()), id: \.offset) { index, name in
                Text(L10n.Portability.columnName(index + 1, name)).tag(index)
            }
        }
        .accessibilityLabel(Text(title))
    }

    private func optionalColumnPicker(_ title: LocalizedStringResource, selection: Binding<Int?>) -> some View {
        Picker(String(localized: title), selection: selection) {
            Text(L10n.Portability.notMapped).tag(nil as Int?)
            ForEach(Array((table?.headers ?? []).enumerated()), id: \.offset) { index, name in
                Text(L10n.Portability.columnName(index + 1, name)).tag(Optional(index))
            }
        }
        .accessibilityLabel(Text(title))
    }

    private func reviewSection(_ rows: [WeightCSV.ReviewRow]) -> some View {
        Section {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Portability.rowNumber(row.line)).font(.headline)
                    if let issue = row.issue {
                        Label(String(localized: L10n.Portability.csvIssue(issue)), systemImage: "exclamationmark.triangle")
                    } else if let draft = row.draft {
                        Text(draft.timestamp, format: .dateTime.year().month().day().hour().minute().second())
                        Text(verbatim: "\(draft.unit.convert(fromKg: draft.weightKg).formatted()) \(draft.unit.symbol)")
                        if let notes = draft.notes {
                            Text(verbatim: notes).font(.caption).lineLimit(3)
                        }
                        if row.isDuplicate {
                            Label(String(localized: L10n.Portability.duplicateWarning), systemImage: "doc.on.doc")
                            Toggle(String(localized: L10n.Portability.keepDuplicate), isOn: Binding(
                                get: { keepingDuplicates.contains(row.id) },
                                set: { keep in
                                    if keep { keepingDuplicates.insert(row.id) }
                                    else { keepingDuplicates.remove(row.id) }
                                }
                            ))
                            .accessibilityLabel(Text(L10n.Portability.keepDuplicateRow(row.line)))
                        } else {
                            Label(String(localized: L10n.Portability.ready), systemImage: "checkmark.circle")
                        }
                    }
                }
                .accessibilityElement(children: .contain)
            }
        } header: {
            Text(L10n.Portability.importPreview)
        } footer: {
            Text(L10n.Portability.duplicateExplanation)
        }
    }

    private func invalidateReview() {
        review = nil
        keepingDuplicates.removeAll()
    }

    private func rebuildTable() {
        invalidateReview()
        table = nil
        guard let sourceText else { return }
        do {
            let parsed = try WeightCSV.parse(sourceText, hasHeader: hasHeader)
            table = parsed
            mapping = WeightCSV.suggestedMapping(for: parsed)
            if let suggested = WeightCSV.suggestedUnit(for: parsed, mapping: mapping) { unit = suggested }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildReview() {
        guard let table else { return }
        do {
            let existing = try dataManager.fetchEntries(includeHidden: true).map {
                WeightEntryDraft(weightKg: $0.weightKg, timestamp: $0.timestamp, unit: $0.displayUnitAtEntry, notes: $0.notes)
            }
            keepingDuplicates.removeAll()
            review = WeightCSV.review(table, mapping: mapping, defaultUnit: unit, dateConvention: convention, existing: existing)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importSelected() {
        guard storeManager.isPro else {
            showingPaywall = true
            return
        }
        do {
            let count = try dataManager.importWeightEntries(drafts)
            invalidateReview()
            importedCount = count
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
