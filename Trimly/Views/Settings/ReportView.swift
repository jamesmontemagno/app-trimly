import SwiftUI
import Charts
import CoreGraphics
import QuickLook
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ReportView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var range = PortabilityDateRange()
    @State private var unit = WeightUnit.kilograms
    @State private var includeGoal = true
    @State private var report: WeightReport?
    @State private var document: PortabilityDocument?
    @State private var showingExporter = false
    @State private var showingPaywall = false
    @State private var exportedURL: URL?
    @State private var hasExportAccess = false
    @State private var previewURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                PortabilityRangeSection(range: $range)
                Section {
                    PortabilityUnitPicker(unit: $unit)
                    Toggle(String(localized: L10n.Portability.includeGoal), isOn: $includeGoal)
                        .accessibilityLabel(Text(L10n.Portability.includeGoal))
                    Button(String(localized: L10n.Portability.createReport), action: createReport)
                        .accessibilityLabel(Text(L10n.Portability.createReport))
                        .disabled(!range.isValid)
                } footer: {
                    Text(L10n.Portability.reportPrivacy)
                }
                if let report {
                    Section {
                        if report.points.isEmpty {
                            Text(L10n.Portability.noMeasurements)
                        } else {
                            WeightReportContent(report: report)
                            Button(String(localized: L10n.Portability.savePDF)) { showingExporter = true }
                                .accessibilityLabel(Text(L10n.Portability.savePDF))
                                .disabled(document == nil)
                        }
                        if let exportedURL {
                            ShareLink(item: exportedURL) {
                                Label(String(localized: L10n.Portability.shareFile), systemImage: "square.and.arrow.up")
                            }
                            .accessibilityLabel(Text(L10n.Portability.shareFile))
                            Button(String(localized: L10n.Portability.previewPDF)) { previewURL = exportedURL }
                                .accessibilityLabel(Text(L10n.Portability.previewPDF))
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text(L10n.Portability.reportTitle))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.doneButton)) { dismiss() }
                        .accessibilityLabel(Text(L10n.Common.doneButton))
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 640)
        #endif
        .onAppear { unit = dataManager.settings?.preferredUnit ?? .kilograms }
        .onChange(of: range) { _, _ in invalidate() }
        .onChange(of: unit) { _, _ in invalidate() }
        .onChange(of: includeGoal) { _, _ in invalidate() }
        .onChange(of: dataManager.dataRevision) { _, _ in invalidate() }
        .onChange(of: storeManager.isPro) { _, isPro in if !isPro { invalidate() } }
        .onDisappear(perform: releaseExportAccess)
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .quickLookPreview($previewURL)
        .fileExporter(
            isPresented: $showingExporter,
            document: document,
            contentType: .pdf,
            defaultFilename: String(localized: L10n.Portability.reportFilename)
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
        report = nil
        document = nil
        exportedURL = nil
        previewURL = nil
    }

    private func releaseExportAccess() {
        if hasExportAccess { exportedURL?.stopAccessingSecurityScopedResource() }
        hasExportAccess = false
    }

    private func createReport() {
        guard storeManager.isPro else {
            showingPaywall = true
            return
        }
        do {
            let entries = try dataManager.fetchEntries(startDate: range.lowerBound, endDate: range.upperBound)
            let snapshot = WeightReport(
                entries: entries,
                unit: unit,
                aggregation: dataManager.settings?.dailyAggregationMode ?? .latest,
                goalWeightKg: includeGoal ? dataManager.fetchActiveGoal()?.targetWeightKg : nil,
                decimalPrecision: dataManager.settings?.decimalPrecision ?? 1
            )
            report = snapshot
            releaseExportAccess()
            exportedURL = nil
            document = snapshot.points.isEmpty ? nil : PortabilityDocument(data: try makePDF(snapshot))
        } catch {
            document = nil
            errorMessage = error.localizedDescription
        }
    }

    /// ImageRenderer draws into Core Graphics on both iOS and macOS without UIKit.
    private func makePDF(_ report: WeightReport) throws -> Data {
        let content = WeightReportContent(report: report)
            .padding(32)
            .frame(width: 580)
            .background(.white)
            .environment(\.colorScheme, .light)
            .environment(\.dynamicTypeSize, .large)
        let renderer = ImageRenderer(content: content)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw ReportRenderingError.failed
        }
        var rendered = false
        renderer.render { size, draw in
            guard size.width > 0, size.height > 0 else { return }
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
            rendered = true
        }
        guard rendered, data.length > 0 else { throw ReportRenderingError.failed }
        return data as Data
    }
}

private enum ReportRenderingError: LocalizedError {
    case failed
    nonisolated var errorDescription: String? { String(localized: L10n.Portability.reportFailed) }
}

private struct WeightReportContent: View {
    let report: WeightReport
    @ScaledMetric(relativeTo: .body) private var chartHeight = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.Portability.reportTitle)
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
            if let first = report.points.first, let last = report.points.last {
                Text(L10n.Portability.reportDates(
                    first.date.formatted(date: .abbreviated, time: .omitted),
                    last.date.formatted(date: .abbreviated, time: .omitted)
                ))
                .font(.subheadline)
                Chart {
                    ForEach(report.points) { point in
                        LineMark(
                            x: .value(String(localized: L10n.Portability.dateColumn), point.date),
                            y: .value(String(localized: L10n.Portability.weightColumn), report.unit.convert(fromKg: point.weightKg))
                        )
                        .foregroundStyle(.blue)
                        PointMark(
                            x: .value(String(localized: L10n.Portability.dateColumn), point.date),
                            y: .value(String(localized: L10n.Portability.weightColumn), report.unit.convert(fromKg: point.weightKg))
                        )
                        .foregroundStyle(.blue)
                        .accessibilityLabel(Text(point.date, format: .dateTime.year().month().day()))
                        .accessibilityValue(report.formattedWeight(point.weightKg))
                    }

                    if let goal = report.goalWeightKg {
                        RuleMark(y: .value(String(localized: L10n.Portability.goal), report.unit.convert(fromKg: goal)))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text(L10n.Portability.goal))
                            .accessibilityValue(report.formattedWeight(goal))
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxisLabel(report.unit.symbol)
                .frame(height: chartHeight)
                .accessibilityLabel(Text(L10n.Portability.reportChart))
            }
            VStack(spacing: 10) {
                summary(L10n.Portability.firstWeight, value: report.firstWeightKg.map { report.formattedWeight($0) })
                summary(L10n.Portability.latestWeight, value: report.latestWeightKg.map { report.formattedWeight($0) })
                summary(L10n.Portability.change, value: report.changeKg.map { report.formattedWeight($0, signed: true) })
                summary(L10n.Portability.dailyAverage, value: report.averageKg.map { report.formattedWeight($0) })
                if let goal = report.goalWeightKg {
                    summary(L10n.Portability.goal, value: report.formattedWeight(goal))
                }
            }
            Text(L10n.Portability.entryCount(report.entryCount))
            Text(L10n.Portability.loggedDays(report.points.count))
            Text(report.aggregation == .latest ? L10n.Portability.reportLatest : L10n.Portability.reportAverage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func summary(_ label: LocalizedStringResource, value: String?) -> some View {
        if let value {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(label)
                    Spacer()
                    Text(value).fontWeight(.semibold)
                }
                VStack(alignment: .leading) {
                    Text(label)
                    Text(value).fontWeight(.semibold)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

enum SharePrivacy: String, CaseIterable, Identifiable {
    case checkInsOnly
    case trend
    case detailed
    var id: String { rawValue }
}

enum ShareAccent: String, CaseIterable, Identifiable {
    case blue
    case teal
    case purple
    case orange

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: .blue
        case .teal: .teal
        case .purple: .purple
        case .orange: .orange
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .blue: L10n.Portability.shareAccentBlue
        case .teal: L10n.Portability.shareAccentTeal
        case .purple: L10n.Portability.shareAccentPurple
        case .orange: L10n.Portability.shareAccentOrange
        }
    }
}

/// Groups appearance/lifecycle-related modifiers for `ShareCheckInView` so the
/// compiler doesn't have to type-check one enormous modifier chain at once.
private struct ShareCheckInLifecycleModifiers: ViewModifier {
    let onAppear: () -> Void
    let onDisappear: () -> Void
    let dataRevision: Int
    let onRefresh: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onAppear)
            .onChange(of: dataRevision) { _, _ in onRefresh() }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                onRefresh()
            }
            .onDisappear(perform: onDisappear)
    }
}

/// Groups the "invalidate the prepared share image when an option changes"
/// modifiers so they type-check as their own smaller expression.
private struct ShareCheckInOptionChangeModifiers: ViewModifier {
    let privacy: SharePrivacy
    let accent: ShareAccent
    let portrait: Bool
    let darkAppearance: Bool
    let showFooter: Bool
    let includeGraph: Bool
    let includeCurrent: Bool
    let includeChange: Bool
    let includeGoal: Bool
    let onOptionChanged: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: privacy) { _, _ in onOptionChanged() }
            .onChange(of: accent) { _, _ in onOptionChanged() }
            .onChange(of: portrait) { _, _ in onOptionChanged() }
            .onChange(of: darkAppearance) { _, _ in onOptionChanged() }
            .onChange(of: showFooter) { _, _ in onOptionChanged() }
            .onChange(of: includeGraph) { _, _ in onOptionChanged() }
            .onChange(of: includeCurrent) { _, _ in onOptionChanged() }
            .onChange(of: includeChange) { _, _ in onOptionChanged() }
            .onChange(of: includeGoal) { _, _ in onOptionChanged() }
    }
}

struct ShareCheckInView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var privacy = SharePrivacy.detailed
    @State private var accent = ShareAccent.blue
    @State private var portrait = true
    @State private var darkAppearance = false
    @State private var showFooter = true
    @State private var includeGraph = true
    @State private var includeCurrent = true
    @State private var includeChange = true
    @State private var includeGoal = true
    @State private var snapshot: WeightReport.ShareCheckInSnapshot?
    @State private var shareURL: URL?
    @State private var errorMessage: String?
    #if canImport(UIKit)
    @State private var shareItem: ShareImageItem?
    #elseif canImport(AppKit)
    @State private var sharingPicker: NSSharingServicePicker?
    #endif

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let snapshot {
                        ShareCardPreview(
                            snapshot: snapshot,
                            privacy: privacy,
                            accent: accent,
                            portrait: portrait,
                            darkAppearance: darkAppearance,
                            showFooter: showFooter,
                            includeGraph: includeGraph,
                            includeCurrent: includeCurrent,
                            includeChange: includeChange,
                            includeGoal: includeGoal
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                } header: {
                    Text(L10n.Portability.shareCheckInSubtitle)
                }
                Section(String(localized: L10n.Portability.sharePrivacy)) {
                    Picker(String(localized: L10n.Portability.sharePrivacy), selection: $privacy) {
                        Text(L10n.Portability.shareCheckInsOnly).tag(SharePrivacy.checkInsOnly)
                        Text(L10n.Portability.shareTrend).tag(SharePrivacy.trend)
                        Text(L10n.Portability.shareDetailed).tag(SharePrivacy.detailed)
                    }
                    .pickerStyle(.menu)
                    if privacy != .checkInsOnly {
                        Toggle(String(localized: L10n.Portability.shareWeightGraph), isOn: $includeGraph)
                    }
                    if privacy == .detailed {
                        Toggle(String(localized: L10n.Portability.shareCurrentWeight), isOn: $includeCurrent)
                        Toggle(String(localized: L10n.Portability.shareChange), isOn: $includeChange)
                        if snapshot?.goalWeightKg != nil {
                            Toggle(String(localized: L10n.Portability.shareGoalValue), isOn: $includeGoal)
                        }
                    }
                    Text(L10n.Portability.sharePrivacyHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if privacy == .trend {
                        Text(L10n.Portability.shareTrendDisclosure)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Picker(String(localized: L10n.Portability.shareAccent), selection: $accent) {
                        ForEach(ShareAccent.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    Toggle(String(localized: L10n.Portability.sharePortrait), isOn: $portrait)
                    Toggle(String(localized: L10n.Portability.shareDark), isOn: $darkAppearance)
                    Toggle(String(localized: L10n.Portability.shareFooter), isOn: $showFooter)
                    if shareURL == nil {
                        Button(action: prepareImage) {
                            HStack {
                                Spacer(minLength: 0)
                                Label(String(localized: L10n.Portability.prepareImage), systemImage: "photo")
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(minHeight: 44)
                        .accessibilityLabel(Text(L10n.Portability.prepareImage))
                        .disabled(snapshot == nil)
                    } else {
                        Button(action: shareImage) {
                            HStack {
                                Spacer(minLength: 0)
                                Label(String(localized: L10n.Portability.shareImage), systemImage: "square.and.arrow.up")
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(minHeight: 44)
                        .accessibilityLabel(Text(L10n.Portability.shareImage))
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text(L10n.Portability.shareCheckIn))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: L10n.Common.doneButton)) {
                        saveShareSettings()
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 720)
        #endif
        .modifier(ShareCheckInLifecycleModifiers(
            onAppear: {
                loadShareSettings()
                refreshSnapshot()
            },
            onDisappear: {
                saveShareSettings()
                #if canImport(UIKit)
                if shareItem == nil {
                    removeTemporaryImage()
                }
                #else
                removeTemporaryImage()
                #endif
            },
            dataRevision: dataManager.dataRevision,
            onRefresh: refreshSnapshot
        ))
        .modifier(ShareCheckInOptionChangeModifiers(
            privacy: privacy,
            accent: accent,
            portrait: portrait,
            darkAppearance: darkAppearance,
            showFooter: showFooter,
            includeGraph: includeGraph,
            includeCurrent: includeCurrent,
            includeChange: includeChange,
            includeGoal: includeGoal,
            onOptionChanged: removeTemporaryImage
        ))
        #if canImport(UIKit)
        .sheet(item: $shareItem, onDismiss: removeTemporaryImage) { item in
            ShareActivityView(items: [item.url])
        }
        #endif
        .alert(String(localized: L10n.Common.errorTitle), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: L10n.Common.okButton), role: .cancel) {}
        } message: {
            Text(errorMessage ?? String(localized: L10n.Portability.shareFailed))
        }
    }

    private func refreshSnapshot() {
        let refreshed = WeightReport.ShareCheckInSnapshot(
            entries: dataManager.fetchAllEntries(),
            goal: dataManager.fetchActiveGoal(),
            unit: dataManager.settings?.preferredUnit ?? .kilograms,
            aggregation: dataManager.settings?.dailyAggregationMode ?? .latest,
            decimalPrecision: dataManager.settings?.decimalPrecision ?? 1
        )
        snapshot = refreshed
        removeTemporaryImage()
    }

    private func prepareImage() {
        saveShareSettings()
        _ = renderImage()
    }

    private func shareImage() {
        guard let url = shareURL else { return }
        #if canImport(UIKit)
        shareItem = ShareImageItem(url: url)
        #elseif canImport(AppKit)
        guard let sourceView = (NSApp.keyWindow ?? NSApp.mainWindow)?.contentView else {
            removeTemporaryImage()
            errorMessage = String(localized: L10n.Portability.shareFailed)
            return
        }
        let picker = NSSharingServicePicker(items: [url])
        sharingPicker = picker
        let sourceRect = NSRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 1, height: 1)
        picker.show(relativeTo: sourceRect, of: sourceView, preferredEdge: .minY)
        #endif
    }

    private func renderImage() -> URL? {
        guard let snapshot else { return nil }
        let content = ShareCardCanvas(
            snapshot: snapshot,
            privacy: privacy,
            accent: accent,
            portrait: portrait,
            darkAppearance: darkAppearance,
            showFooter: showFooter,
            includeGraph: includeGraph,
            includeCurrent: includeCurrent,
            includeChange: includeChange,
            includeGoal: includeGoal
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        #if canImport(UIKit)
        guard let image = renderer.uiImage, let data = image.pngData() else {
            errorMessage = String(localized: L10n.Portability.shareFailed)
            return nil
        }
        #elseif canImport(AppKit)
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff),
              let data = representation.representation(using: .png, properties: [:]) else {
            errorMessage = String(localized: L10n.Portability.shareFailed)
            return nil
        }
        #else
        errorMessage = String(localized: L10n.Portability.shareFailed)
        return nil
        #endif
        removeTemporaryImage()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("image-\(UUID().uuidString).png")
        do {
            try data.write(to: url, options: .atomic)
            shareURL = url
            return url
        } catch {
            errorMessage = String(localized: L10n.Portability.shareFailed)
            return nil
        }
    }

    private func loadShareSettings() {
        let settings = dataManager.deviceSettings.shareCard
        privacy = SharePrivacy(rawValue: settings.privacy) ?? .detailed
        accent = ShareAccent(rawValue: settings.accent) ?? .blue
        portrait = settings.portrait
        darkAppearance = settings.darkAppearance
        showFooter = settings.showFooter
        includeGraph = settings.includeGraph
        includeCurrent = settings.includeCurrent
        includeChange = settings.includeChange
        includeGoal = settings.includeGoal
    }

    private func saveShareSettings() {
        dataManager.deviceSettings.updateShareCard { settings in
            settings.privacy = privacy.rawValue
            settings.accent = accent.rawValue
            settings.portrait = portrait
            settings.darkAppearance = darkAppearance
            settings.showFooter = showFooter
            settings.includeGraph = includeGraph
            settings.includeCurrent = includeCurrent
            settings.includeChange = includeChange
            settings.includeGoal = includeGoal
        }
    }

    private func removeTemporaryImage() {
        #if canImport(UIKit)
        // Keep the file available until the activity controller has finished with it.
        guard shareItem == nil else { return }
        #endif
        guard let shareURL else { return }
        try? FileManager.default.removeItem(at: shareURL)
        self.shareURL = nil
    }
}

private struct ShareCardPreview: View {
    let snapshot: WeightReport.ShareCheckInSnapshot
    let privacy: SharePrivacy
    let accent: ShareAccent
    let portrait: Bool
    let darkAppearance: Bool
    let showFooter: Bool
    let includeGraph: Bool
    let includeCurrent: Bool
    let includeChange: Bool
    let includeGoal: Bool
    @State private var canvasHeight: CGFloat = 800

    private var exportWidth: CGFloat {
        portrait ? 700 : 800
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / exportWidth
            ShareCardCanvas(
                snapshot: snapshot,
                privacy: privacy,
                accent: accent,
                portrait: portrait,
                darkAppearance: darkAppearance,
                showFooter: showFooter,
                includeGraph: includeGraph,
                includeCurrent: includeCurrent,
                includeChange: includeChange,
                includeGoal: includeGoal
            )
            .background {
                GeometryReader { canvas in
                    Color.clear.preference(key: ShareCardHeightKey.self, value: canvas.size.height)
                }
            }
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(exportWidth / canvasHeight, contentMode: .fit)
        .onPreferenceChange(ShareCardHeightKey.self) { height in
            guard height.isFinite, height > 0 else { return }
            canvasHeight = height
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ShareCardHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 800

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ShareCardCanvas: View {
    let snapshot: WeightReport.ShareCheckInSnapshot
    let privacy: SharePrivacy
    let accent: ShareAccent
    let portrait: Bool
    let darkAppearance: Bool
    let showFooter: Bool
    let includeGraph: Bool
    let includeCurrent: Bool
    let includeChange: Bool
    let includeGoal: Bool

    var body: some View {
        ShareCardContent(
            snapshot: snapshot,
            privacy: privacy,
            accent: accent,
            showFooter: showFooter,
            includeGraph: includeGraph,
            includeCurrent: includeCurrent,
            includeChange: includeChange,
            includeGoal: includeGoal
        )
        .padding(28)
        .frame(width: portrait ? 700 : 800, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(darkAppearance ? Color.black : Color.white)
        .environment(\.colorScheme, darkAppearance ? .dark : .light)
        .environment(\.dynamicTypeSize, .large)
    }
}

private struct ShareCardContent: View {
    let snapshot: WeightReport.ShareCheckInSnapshot
    let privacy: SharePrivacy
    let accent: ShareAccent
    let showFooter: Bool
    let includeGraph: Bool
    let includeCurrent: Bool
    let includeChange: Bool
    let includeGoal: Bool
    @ScaledMetric(relativeTo: .body) private var chartHeight = 320
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 56
    @ScaledMetric(relativeTo: .body) private var bodySize = 30
    @ScaledMetric(relativeTo: .caption) private var captionSize = 24
    @ScaledMetric(relativeTo: .title) private var valueSize = 36

    private var showsValues: Bool { privacy == .detailed }
    private var normalizedGraph: Bool { privacy == .trend }
    private var includesGoal: Bool { showsValues && includeGoal && snapshot.goalWeightKg != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(includesGoal ? L10n.Portability.shareGoal : L10n.Portability.shareCheckIn)
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .accessibilityAddTraits(.isHeader)
            todayStatus
            Text(L10n.Portability.sevenDayCount(snapshot.checkedInDays))
                .fontWeight(.semibold)
            checkInDays
            if privacy != .checkInsOnly, includeGraph {
                if snapshot.graphPoints.isEmpty {
                    Text(L10n.Portability.shareTrendNoData)
                        .font(.system(size: bodySize))
                        .foregroundStyle(.secondary)
                } else {
                    trendChart
                }
            }
            if showsValues {
                if includeCurrent, let current = snapshot.currentWeightKg {
                    valueRow(L10n.Portability.latestWeight, snapshot.formattedWeight(current))
                }
                if includeChange, let change = snapshot.changeKg {
                    valueRow(L10n.Portability.change, snapshot.formattedWeight(change, signed: true))
                }
                if includesGoal {
                    goalProgress
                }
            }
            if showFooter {
                Text(L10n.Portability.shareBrand)
                    .font(.system(size: captionSize, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: bodySize))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var todayStatus: some View {
        let checkedIn = snapshot.days.last?.hasCheckIn == true
        return Label {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    Text(L10n.Portability.shareToday)
                        .fontWeight(.semibold)
                    Text(checkedIn ? L10n.Portability.shareCheckedIn : L10n.Portability.shareNoCheckIn)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Portability.shareToday)
                        .fontWeight(.semibold)
                    Text(checkedIn ? L10n.Portability.shareCheckedIn : L10n.Portability.shareNoCheckIn)
                }
            }
        } icon: {
            Image(systemName: checkedIn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(checkedIn ? accent.color : .secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var checkInDays: some View {
        HStack(spacing: 8) {
            ForEach(snapshot.days) { day in
                VStack(spacing: 6) {
                    Image(systemName: day.hasCheckIn ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: valueSize))
                        .foregroundStyle(day.hasCheckIn ? accent.color : .secondary)
                    dayLabel(day)
                        .font(.system(size: captionSize, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(relativeDayAccessibilityLabel(day))
                .accessibilityValue(Text(day.hasCheckIn ? L10n.Portability.shareCheckedIn : L10n.Portability.shareNoCheckIn))
            }
        }
    }

    private var trendChart: some View {
        let yDomain = snapshot.chartYDomain(normalized: normalizedGraph, includeGoal: includesGoal) ?? 0...1
        let firstDate = snapshot.days.first?.date ?? Date()
        let lastDate = snapshot.days.last?.date ?? Date()
        let xDomain = firstDate.addingTimeInterval(-12 * 60 * 60)...lastDate.addingTimeInterval(12 * 60 * 60)
        return Chart {
            ForEach(snapshot.graphPoints) { point in
                LineMark(
                    x: .value(String(localized: L10n.Portability.shareDayAxis), point.date),
                    y: .value(String(localized: L10n.Portability.shareTrendAxis),
                              snapshot.graphValue(point.weightKg, normalized: normalizedGraph)),
                    series: .value(String(localized: L10n.Portability.shareTrendAxis), point.segment)
                )
                .lineStyle(StrokeStyle(lineWidth: 4))
                .foregroundStyle(accent.color)
                PointMark(
                    x: .value(String(localized: L10n.Portability.shareDayAxis), point.date),
                    y: .value(String(localized: L10n.Portability.shareTrendAxis),
                              snapshot.graphValue(point.weightKg, normalized: normalizedGraph))
                )
                .symbolSize(120)
                .foregroundStyle(accent.color)
            }
            if includesGoal, let goal = snapshot.goalWeightKg {
                RuleMark(
                    y: .value(String(localized: L10n.Portability.goal), snapshot.displayValue(goal))
                )
                .lineStyle(StrokeStyle(lineWidth: 3, dash: [8, 6]))
                .foregroundStyle(.orange)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: snapshot.days.map(\.date)) { value in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(.system(size: captionSize))
                    }
                }
            }
        }
        .chartYAxis {
            if privacy == .detailed, includeCurrent {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                        .font(.system(size: captionSize))
                }
            }
        }
        .chartYAxisLabel {
            if privacy == .detailed, includeCurrent {
                Text(snapshot.unit.symbol)
                    .font(.system(size: captionSize))
            }
        }
        .frame(height: chartHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(
            privacy == .detailed && includeCurrent
                ? L10n.Portability.reportChart
                : L10n.Portability.shareTrendAccessibility
        ))
        .accessibilityValue(chartAccessibilityValue)
    }

    @ViewBuilder
    private var goalProgress: some View {
        if let progress = snapshot.goalProgress {
            ProgressView(value: progress) {
                Text(L10n.Portability.shareGoal)
                    .font(.system(size: bodySize))
            } currentValueLabel: {
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: bodySize, weight: .semibold))
            }
            .tint(accent.color)
            .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
        } else {
            Text(L10n.Portability.shareGoalUnavailable)
                .font(.system(size: bodySize))
                .foregroundStyle(.secondary)
        }
        if let goal = snapshot.goalWeightKg {
            valueRow(L10n.Portability.goal, snapshot.formattedWeight(goal))
        }
    }

    @ViewBuilder
    private func dayLabel(_ day: WeightReport.ShareCheckInSnapshot.Day) -> some View {
        if day.date == snapshot.days.last?.date {
            Text(L10n.Portability.shareToday)
        } else {
            Text(day.date, format: .dateTime.weekday(.narrow))
        }
    }

    private func relativeDayAccessibilityLabel(_ day: WeightReport.ShareCheckInSnapshot.Day) -> String {
        if day.date == snapshot.days.last?.date {
            return String(localized: L10n.Portability.shareToday)
        }
        return day.date.formatted(.dateTime.weekday(.wide))
    }

    private var chartAccessibilityValue: String {
        guard privacy == .detailed, includeCurrent, let currentWeightKg = snapshot.currentWeightKg else {
            return ""
        }
        return snapshot.formattedWeight(currentWeightKg)
    }

    private func valueRow(_ label: LocalizedStringResource, _ value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .font(.system(size: valueSize, weight: .semibold, design: .rounded))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                Text(value)
                    .font(.system(size: valueSize, weight: .semibold, design: .rounded))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#if canImport(UIKit)
private struct ShareImageItem: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ShareActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
