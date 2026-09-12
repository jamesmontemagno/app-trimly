import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var range = PortabilityDateRange()
    @State private var includeNotes = false
    @State private var includeHidden = false
    @State private var unit = WeightUnit.kilograms
    @State private var document: PortabilityDocument?
    @State private var showingExporter = false
    @State private var showingPaywall = false
    @State private var exportedURL: URL?
    @State private var hasExportAccess = false
    @State private var errorMessage: String?
    @State private var entryCount = 0

    var body: some View {
        NavigationStack {
            Form {
                PortabilityRangeSection(range: $range)
                Section {
                    PortabilityUnitPicker(unit: $unit)
                    Toggle(String(localized: L10n.Portability.includeNotes), isOn: $includeNotes)
                        .accessibilityLabel(Text(L10n.Portability.includeNotes))
                    Toggle(String(localized: L10n.Portability.includeHidden), isOn: $includeHidden)
                        .accessibilityLabel(Text(L10n.Portability.includeHidden))
                } footer: {
                    Text(L10n.Portability.exportPrivacy)
                }
                Section {
                    Button(String(localized: L10n.Portability.createCSV), action: createCSV)
                        .accessibilityLabel(Text(L10n.Portability.createCSV))
                        .disabled(!range.isValid)
                    if let document {
                        Text(L10n.Portability.entryCount(entryCount))
                        ScrollView(.horizontal) {
                            Text(verbatim: String(decoding: document.data.prefix(8_000), as: UTF8.self))
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        Text(L10n.Portability.previewExcerpt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(String(localized: L10n.Portability.saveCSV)) { showingExporter = true }
                            .accessibilityLabel(Text(L10n.Portability.saveCSV))
                    }
                    if let exportedURL {
                        ShareLink(item: exportedURL) {
                            Label(String(localized: L10n.Portability.shareFile), systemImage: "square.and.arrow.up")
                        }
                        .accessibilityLabel(Text(L10n.Portability.shareFile))
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text(L10n.Settings.exportTitle))
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
        .onChange(of: range) { _, _ in invalidate() }
        .onChange(of: includeNotes) { _, _ in invalidate() }
        .onChange(of: includeHidden) { _, _ in invalidate() }
        .onChange(of: unit) { _, _ in invalidate() }
        .onChange(of: dataManager.dataRevision) { _, _ in invalidate() }
        .onChange(of: storeManager.isPro) { _, isPro in if !isPro { invalidate() } }
        .onDisappear(perform: releaseExportAccess)
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .fileExporter(
            isPresented: $showingExporter,
            document: document,
            contentType: .commaSeparatedText,
            defaultFilename: "TrimTally-weights.csv"
        ) { result in
            switch result {
            case .success(let url):
                releaseExportAccess()
                hasExportAccess = url.startAccessingSecurityScopedResource()
                exportedURL = url
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
        .portabilityError($errorMessage)
    }

    private func invalidate() {
        releaseExportAccess()
        document = nil
        exportedURL = nil
    }

    private func releaseExportAccess() {
        if hasExportAccess { exportedURL?.stopAccessingSecurityScopedResource() }
        hasExportAccess = false
    }

    private func createCSV() {
        guard storeManager.isPro else {
            showingPaywall = true
            return
        }
        do {
            let entries = try dataManager.fetchEntries(
                startDate: range.lowerBound, endDate: range.upperBound, includeHidden: includeHidden
            )
            entryCount = entries.count
            let csv = WeightCSV.encode(entries: entries, unit: unit, includeNotes: includeNotes, includeHidden: includeHidden)
            document = PortabilityDocument(data: Data(csv.utf8))
            releaseExportAccess()
            exportedURL = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// FileDocument carries bytes, rather than sharing CSV as a plain-text message.
struct PortabilityDocument: FileDocument {
    nonisolated static var readableContentTypes: [UTType] { [.commaSeparatedText, .pdf] }
    nonisolated let data: Data

    nonisolated init(data: Data) { self.data = data }

    nonisolated init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct PortabilityDateRange: Equatable {
    var allTime = true
    var start = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var end = Date()

    var isValid: Bool {
        allTime || Calendar.current.startOfDay(for: start) <= Calendar.current.startOfDay(for: end)
    }
    var lowerBound: Date? { allTime ? nil : Calendar.current.startOfDay(for: start) }
    var upperBound: Date? {
        allTime ? nil : Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: end))
    }
}

struct PortabilityRangeSection: View {
    @Binding var range: PortabilityDateRange

    var body: some View {
        Section {
            Toggle(String(localized: L10n.Portability.allTime), isOn: $range.allTime)
                .accessibilityLabel(Text(L10n.Portability.allTime))
            if !range.allTime {
                DatePicker(String(localized: L10n.Portability.startDate), selection: $range.start, displayedComponents: .date)
                    .accessibilityLabel(Text(L10n.Portability.startDate))
                DatePicker(String(localized: L10n.Portability.endDate), selection: $range.end, displayedComponents: .date)
                    .accessibilityLabel(Text(L10n.Portability.endDate))
                if !range.isValid {
                    Label(String(localized: L10n.Portability.invalidRange), systemImage: "exclamationmark.triangle")
                }
            }
        } header: {
            Text(L10n.Portability.dateRange)
        } footer: {
            Text(L10n.Portability.inclusiveDates)
        }
    }
}

struct PortabilityUnitPicker: View {
    @Binding var unit: WeightUnit
    var body: some View {
        Picker(String(localized: L10n.Settings.weightUnitTitle), selection: $unit) {
            Text(L10n.Onboarding.unitOptionKilograms).tag(WeightUnit.kilograms)
            Text(L10n.Onboarding.unitOptionPounds).tag(WeightUnit.pounds)
            Text(L10n.Onboarding.unitOptionStones).tag(WeightUnit.stones)
        }
        .accessibilityLabel(Text(L10n.Settings.weightUnitTitle))
    }
}

extension View {
    func portabilityError(_ message: Binding<String?>) -> some View {
        alert(String(localized: L10n.Common.errorTitle), isPresented: Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )) {
            Button(String(localized: L10n.Common.okButton), role: .cancel) { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
