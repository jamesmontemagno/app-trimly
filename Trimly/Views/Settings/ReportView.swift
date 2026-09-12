import SwiftUI
import Charts
import CoreGraphics
import QuickLook
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
        .fileExporter(isPresented: $showingExporter, document: document, contentType: .pdf, defaultFilename: "TrimTally-progress.pdf") { result in
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

                    private enum ShareCardFormat: String, CaseIterable, Identifiable {
                        case checkIns
                        case goal
                        var id: String { rawValue }
                    }

                    private enum SharePrivacy: String, CaseIterable, Identifiable {
                        case checkInsOnly
                        case trend
                        case detailed
                        var id: String { rawValue }
                    }

                    struct ShareCheckInView: View {
                        @EnvironmentObject private var dataManager: DataManager
                        @Environment(\.dismiss) private var dismiss
                        @State private var format = ShareCardFormat.checkIns
                        @State private var privacy = SharePrivacy.checkInsOnly
                        @State private var portrait = true
                        @State private var darkAppearance = false
                        @State private var showFooter = true
                        @State private var includeGraph = true
                        @State private var includeCurrent = false
                        @State private var includeChange = false
                        @State private var includeGoalDetails = false
                        @State private var snapshot: ShareCheckInSnapshot?
                        @State private var shareURL: URL?
                        @State private var errorMessage: String?

                        var body: some View {
                            NavigationStack {
                                Form {
                                    Section {
                                        if let snapshot {
                                            ShareCardContent(snapshot: snapshot, format: format, privacy: privacy,
                                                             showFooter: showFooter, includeGraph: includeGraph,
                                                             includeCurrent: includeCurrent, includeChange: includeChange,
                                                             includeGoalDetails: includeGoalDetails)
                                            .padding(16)
                                            .background(darkAppearance ? Color.black : Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .environment(\.colorScheme, darkAppearance ? .dark : .light)
                                        } else {
                                            Text(L10n.Portability.shareNoData)
                                                .foregroundStyle(.secondary)
                                        }
                                    } header: {
                                        Text(L10n.Portability.shareCheckInSubtitle)
                                    }
                                    Section(String(localized: L10n.Portability.shareFormat)) {
                                        Picker(String(localized: L10n.Portability.shareFormat), selection: $format) {
                                            Text(L10n.Portability.shareCheckIns).tag(ShareCardFormat.checkIns)
                                            Text(L10n.Portability.shareGoal).tag(ShareCardFormat.goal)
                                        }
                                        .pickerStyle(.segmented)
                                        .accessibilityLabel(Text(L10n.Portability.shareFormat))
                                    }
                                    Section(String(localized: L10n.Portability.sharePrivacy)) {
                                        Picker(String(localized: L10n.Portability.sharePrivacy), selection: $privacy) {
                                            Text(L10n.Portability.shareCheckInsOnly).tag(SharePrivacy.checkInsOnly)
                                            Text(L10n.Portability.shareTrend).tag(SharePrivacy.trend)
                                            Text(L10n.Portability.shareDetailed).tag(SharePrivacy.detailed)
                                        }
                                        .pickerStyle(.menu)
                                        Toggle(String(localized: L10n.Portability.shareWeightGraph), isOn: $includeGraph)
                                        if privacy == .detailed {
                                            Toggle(String(localized: L10n.Portability.shareCurrentWeight), isOn: $includeCurrent)
                                            Toggle(String(localized: L10n.Portability.shareChange), isOn: $includeChange)
                                            Toggle(String(localized: L10n.Portability.shareGoalValue), isOn: $includeGoalDetails)
                                        }
                                        Text(L10n.Portability.sharePrivacyHint)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Section {
                                        Toggle(String(localized: L10n.Portability.sharePortrait), isOn: $portrait)
                                        Toggle(String(localized: L10n.Portability.shareDark), isOn: $darkAppearance)
                                        Toggle(String(localized: L10n.Portability.shareFooter), isOn: $showFooter)
                                        Button(String(localized: L10n.Portability.sharePrepare), action: prepareImage)
                                            .disabled(snapshot == nil)
                                    }
                                    if let shareURL {
                                        Section {
                                            ShareLink(item: shareURL) {
                                                Label(String(localized: L10n.Portability.shareImage), systemImage: "square.and.arrow.up")
                                            }
                                        }
                                    }
                                }
                                .formStyle(.grouped)
                                .navigationTitle(Text(L10n.Portability.shareCheckIn))
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button(String(localized: L10n.Common.doneButton)) { dismiss() }
                                    }
                                }
                            }
                            #if os(macOS)
                            .frame(minWidth: 520, minHeight: 720)
                            #endif
                            .onAppear(perform: refreshSnapshot)
                            .onChange(of: dataManager.dataRevision) { _, _ in refreshSnapshot() }
                            .onChange(of: format) { _, _ in shareURL = nil }
                            .onChange(of: privacy) { _, newValue in
                                if newValue != .detailed {
                                    includeCurrent = false
                                    includeChange = false
                                    includeGoalDetails = false
                                }
                                shareURL = nil
                            }
                            .onChange(of: portrait) { _, _ in shareURL = nil }
                            .onChange(of: darkAppearance) { _, _ in shareURL = nil }
                            .onChange(of: showFooter) { _, _ in shareURL = nil }
                            .onChange(of: includeGraph) { _, _ in shareURL = nil }
                            .onChange(of: includeCurrent) { _, _ in shareURL = nil }
                            .onChange(of: includeChange) { _, _ in shareURL = nil }
                            .onChange(of: includeGoalDetails) { _, _ in shareURL = nil }
                            .onDisappear(perform: removeTemporaryImage)
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
                            let entries = dataManager.fetchAllEntries()
                            snapshot = ShareCheckInSnapshot(
                                entries: entries,
                                goal: dataManager.fetchActiveGoal(),
                                unit: dataManager.settings?.preferredUnit ?? .kilograms,
                                aggregation: dataManager.settings?.dailyAggregationMode ?? .latest,
                                decimalPrecision: dataManager.settings?.decimalPrecision ?? 1
                            )
                            shareURL = nil
                        }

                        private func prepareImage() {
                            guard let snapshot else { return }
                            let content = ShareCardContent(snapshot: snapshot, format: format, privacy: privacy,
                                                          showFooter: showFooter, includeGraph: includeGraph,
                                                          includeCurrent: includeCurrent, includeChange: includeChange,
                                                          includeGoalDetails: includeGoalDetails)
                                .padding(28)
                                .frame(width: portrait ? 700 : 800, height: portrait ? 900 : 800, alignment: .top)
                                .background(darkAppearance ? Color.black : Color.white)
                                .environment(\.colorScheme, darkAppearance ? .dark : .light)
                                .environment(\.dynamicTypeSize, .large)
                            let renderer = ImageRenderer(content: content)
                            #if canImport(UIKit)
                            guard let image = renderer.uiImage, let data = image.pngData() else {
                                errorMessage = String(localized: L10n.Portability.shareFailed)
                                return
                            }
                            #elseif canImport(AppKit)
                            guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
                                  let representation = NSBitmapImageRep(data: tiff),
                                  let data = representation.representation(using: .png, properties: [:]) else {
                                errorMessage = String(localized: L10n.Portability.shareFailed)
                                return
                            }
                            #else
                            errorMessage = String(localized: L10n.Portability.shareFailed)
                            return
                            #endif
                            removeTemporaryImage()
                            let url = FileManager.default.temporaryDirectory
                                .appendingPathComponent("trimtally-share-\(UUID().uuidString).png")
                            do {
                                try data.write(to: url, options: .atomic)
                                shareURL = url
                            } catch {
                                errorMessage = String(localized: L10n.Portability.shareFailed)
                            }

                        }

                    private func removeTemporaryImage() {
                        guard let shareURL else { return }
                        try? FileManager.default.removeItem(at: shareURL)
                        self.shareURL = nil
                    }
                }

                private struct ShareCardContent: View {
                        let snapshot: ShareCheckInSnapshot
                        let format: ShareCardFormat
                        let privacy: SharePrivacy
                        let showFooter: Bool
                        let includeGraph: Bool
                        let includeCurrent: Bool
                        let includeChange: Bool
                        let includeGoalDetails: Bool
                        @ScaledMetric(relativeTo: .body) private var chartHeight = 190

                        private var showsValues: Bool { privacy == .detailed }
                        private var graphPoints: [ShareCheckInSnapshot.Day] {
                            snapshot.days.filter { $0.weightKg != nil }
                        }

                        var body: some View {
                            VStack(alignment: .leading, spacing: 18) {
                                Text(format == .goal ? L10n.Portability.shareGoal : L10n.Portability.shareCheckIn)
                                    .font(.largeTitle.bold())
                                    .accessibilityAddTraits(.isHeader)
                                Text(L10n.Portability.sevenDayCount(snapshot.checkedInDays))
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    ForEach(snapshot.days) { day in
                                        VStack(spacing: 6) {
                                            Image(systemName: day.hasCheckIn ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(day.hasCheckIn ? .green : .secondary)
                                            Text(day.date, format: .dateTime.weekday(.narrow))
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                                        .accessibilityValue(Text(day.hasCheckIn ? L10n.Portability.shareCheckedIn : L10n.Portability.shareNoCheckIn))
                                    }
                                }
                                if includeGraph && !graphPoints.isEmpty && privacy != .checkInsOnly {
                                    Chart(graphPoints) { day in
                                        if let weight = day.weightKg {
                                            LineMark(x: .value(String(localized: L10n.Portability.shareDayAxis), day.date), y: .value(String(localized: L10n.Portability.shareTrendAxis), weight))
                                                .foregroundStyle(.blue)
                                            PointMark(x: .value(String(localized: L10n.Portability.shareDayAxis), day.date), y: .value(String(localized: L10n.Portability.shareTrendAxis), weight))
                                                .foregroundStyle(.blue)
                                        }
                                        if format == .goal, privacy == .detailed, includeGoalDetails,
                                           let goal = snapshot.goalWeightKg {
                                            RuleMark(y: .value(String(localized: L10n.Portability.goal), goal))
                                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    .chartYScale(domain: .automatic(includesZero: false))
                                    .chartYAxis(privacy == .detailed ? .automatic : .hidden)
                                    .frame(height: chartHeight)
                                    .accessibilityLabel(Text(L10n.Portability.reportChart))
                                } else if includeGraph {
                                    Text(L10n.Portability.shareNoData).font(.subheadline).foregroundStyle(.secondary)
                                }
                                if showsValues {
                                    if includeCurrent, let current = snapshot.currentWeightKg {
                                        valueRow(L10n.Portability.latestWeight, snapshot.formattedWeight(current))
                                    }
                                    if includeChange, let change = snapshot.changeKg {
                                        valueRow(L10n.Portability.change, snapshot.formattedWeight(change, signed: true))
                                    }
                                    if format == .goal, includeGoalDetails, let goal = snapshot.goalWeightKg {
                                        valueRow(L10n.Portability.goal, snapshot.formattedWeight(goal))
                                    }
                                }
                                if showFooter {
                                    Text(L10n.Portability.shareBrand)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .contain)
                        }

                        private func valueRow(_ label: LocalizedStringResource, _ value: String) -> some View {
                            HStack {
                                Text(label)
                                Spacer()
                                Text(value).fontWeight(.semibold)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
