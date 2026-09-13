import Foundation

/// A plain measurement import, deliberately without HealthKit identity or hidden state.
struct WeightEntryDraft {
    var weightKg: Double
    var timestamp: Date
    var unit: WeightUnit
    var notes: String?
}

enum WeightCSV {
    enum Issue: Error, LocalizedError, Equatable {
        case emptyFile, invalidEncoding, tooLarge, malformedQuote, unclosedQuote
        case invalidMapping, columnCount, invalidWeight, invalidDate, futureDate, invalidUnit

        nonisolated var errorDescription: String? {
            String(localized: L10n.Portability.csvIssue(self))
        }
    }

    enum DateConvention: String, CaseIterable, Identifiable {
        case iso8601, monthFirst, dayFirst
        var id: String { rawValue }
    }

    struct Record: Identifiable {
        let line: Int
        let fields: [String]
        let issue: Issue?
        var id: Int { line }
    }

    struct Table {
        let headers: [String]
        let records: [Record]
    }

    struct Mapping: Equatable {
        var timestamp = 0
        var weight = 1
        var unit: Int?
        var notes: Int?
    }

    struct ReviewRow: Identifiable {
        let line: Int
        let draft: WeightEntryDraft?
        let issue: Issue?
        let isDuplicate: Bool
        var id: Int { line }
    }

    /// The limit bounds memory and preview work before parsing an untrusted file.
    static let maximumBytes = 10 * 1_024 * 1_024

    static func decode(_ data: Data) throws -> String {
        guard data.count <= maximumBytes else { throw Issue.tooLarge }
        guard let text = String(data: data, encoding: .utf8) else { throw Issue.invalidEncoding }
        return text
    }

    /// Parses RFC 4180 quoting, including embedded newlines and escaped double quotes.
    /// Syntax errors stay attached to their record instead of discarding measurements.
    static func parse(_ text: String, hasHeader: Bool = true) throws -> Table {
        guard text.utf8.count <= maximumBytes else { throw Issue.tooLarge }
        let normalized = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        let bytes = Array(normalized.utf8)
        var records: [Record] = []
        var fields: [String] = []
        var field: [UInt8] = []
        var quoted = false
        var closedQuote = false
        var issue: Issue?
        var line = 1
        var recordLine = 1
        var index = 0
        var hasRecordContent = false

        func finishField() {
            fields.append(String(decoding: field, as: UTF8.self))
            field.removeAll(keepingCapacity: true)
            closedQuote = false
        }
        func finishRecord() {
            finishField()
            if hasRecordContent || fields.count > 1 {
                records.append(Record(line: recordLine, fields: fields, issue: issue))
            }
            fields.removeAll(keepingCapacity: true)
            issue = nil
            hasRecordContent = false
        }

        while index < bytes.count {
            let byte = bytes[index]
            let isNewline = byte == 10 || byte == 13
            let isCRLF = byte == 13 && index + 1 < bytes.count && bytes[index + 1] == 10
            if quoted {
                if byte == 34 {
                    if index + 1 < bytes.count && bytes[index + 1] == 34 {
                        field.append(34)
                        index += 1
                    } else {
                        quoted = false
                        closedQuote = true
                    }
                } else {
                    field.append(byte)
                    if isNewline {
                        line += 1
                        if isCRLF {
                            field.append(10)
                            index += 1
                        }
                    }
                }
            } else if byte == 44 {
                hasRecordContent = true
                finishField()
            } else if isNewline {
                finishRecord()
                line += 1
                recordLine = line
                if isCRLF { index += 1 }
            } else {
                hasRecordContent = true
                if byte == 34 && field.isEmpty && !closedQuote {
                    quoted = true
                } else {
                    if byte == 34 || closedQuote { issue = .malformedQuote }
                    field.append(byte)
                }
            }
            index += 1
        }
        if quoted { issue = .unclosedQuote }
        if hasRecordContent || !field.isEmpty || !fields.isEmpty { finishRecord() }
        guard let first = records.first else { throw Issue.emptyFile }
        if hasHeader {
            if let issue = first.issue { throw issue }
            return Table(headers: first.fields, records: Array(records.dropFirst()))
        }
        return Table(headers: first.fields.indices.map { String($0 + 1) }, records: records)
    }

    static func suggestedMapping(for table: Table) -> Mapping {
        let headers = table.headers.map {
            $0.lowercased().filter { $0.isLetter || $0.isNumber }
        }
        func column(_ names: [String]) -> Int? {
            headers.firstIndex { names.contains($0) }
        }
        let weight = column(["weight", "weightkg", "weightlb", "weightst", "value"]) ?? (headers.count > 1 ? 1 : 0)
        let hasEmbeddedUnit = headers.indices.contains(weight) && ["weightkg", "weightlb", "weightst"].contains(headers[weight])
        return Mapping(
            timestamp: column(["timestamp", "date", "datetime", "recordedat"]) ?? 0,
            weight: weight,
            unit: hasEmbeddedUnit ? nil : column(["unit", "weightunit", "displayunitatentry"]),
            notes: column(["notes", "note", "comment"])
        )
    }

    static func suggestedUnit(for table: Table, mapping: Mapping) -> WeightUnit? {
        guard table.headers.indices.contains(mapping.weight) else { return nil }
        let name = table.headers[mapping.weight].lowercased().filter { $0.isLetter }
        switch name {
        case "weightkg": return .kilograms
        case "weightlb": return .pounds
        case "weightst": return .stones
        default: return nil
        }
    }

    /// Duplicate candidates have the same instant (within one second) and weight
    /// (within 0.001 kg). Notes never cause an existing record to be overwritten.
    static func review(
        _ table: Table,
        mapping: Mapping,
        defaultUnit: WeightUnit,
        dateConvention: DateConvention,
        existing: [WeightEntryDraft] = [],
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [ReviewRow] {
        let selected = [mapping.timestamp, mapping.weight] + [mapping.unit, mapping.notes].compactMap { $0 }
        let validMapping = Set(selected).count == selected.count
            && selected.allSatisfy { table.headers.indices.contains($0) }
        var candidates: [Int64: [WeightEntryDraft]] = [:]
        func bucket(_ draft: WeightEntryDraft) -> Int64? {
            let seconds = draft.timestamp.timeIntervalSince1970
            guard seconds.isFinite, abs(seconds) < Double(Int64.max) - 2 else { return nil }
            return Int64(floor(seconds))
        }
        func remember(_ draft: WeightEntryDraft) {
            if let key = bucket(draft) { candidates[key, default: []].append(draft) }
        }
        existing.forEach(remember)
        return table.records.map { record in
            var draft: WeightEntryDraft?
            var issue = record.issue
            var duplicate = false
            if issue == nil {
                do throws(Issue) {
                    guard validMapping else { throw Issue.invalidMapping }
                    guard record.fields.count == table.headers.count else { throw Issue.columnCount }
                    let value = record.fields[mapping.weight].trimmingCharacters(in: .whitespaces)
                    guard let weight = Double(value), weight.isFinite, weight > 0 else { throw Issue.invalidWeight }
                    let unit: WeightUnit
                    if let column = mapping.unit {
                        let symbol = record.fields[column].trimmingCharacters(in: .whitespaces).lowercased()
                        guard let parsed = parseUnit(symbol) else { throw Issue.invalidUnit }
                        unit = parsed
                    } else {
                        unit = defaultUnit
                    }
                    let kg = unit.convertToKg(weight)
                    guard kg.isFinite, kg > 0 else { throw Issue.invalidWeight }
                    guard let date = parseDate(record.fields[mapping.timestamp], convention: dateConvention, timeZone: timeZone),
                          date.timeIntervalSinceReferenceDate.isFinite else { throw Issue.invalidDate }
                    guard date <= now else { throw Issue.futureDate }
                    let note = mapping.notes.map { record.fields[$0] }
                    let item = WeightEntryDraft(weightKg: kg, timestamp: date, unit: unit, notes: note?.isEmpty == true ? nil : note)
                    if let key = bucket(item) {
                        duplicate = (key - 1...key + 1).contains { nearby in
                            candidates[nearby, default: []].contains {
                                abs($0.timestamp.timeIntervalSince(date)) < 1
                                    && abs($0.weightKg - kg) < 0.001
                            }
                        }
                    }
                    remember(item)
                    draft = item
                } catch {
                    issue = error
                }
            }
            return ReviewRow(line: record.line, draft: draft, issue: issue, isDuplicate: duplicate)
        }
    }

    static func draftsToImport(from rows: [ReviewRow], keepingDuplicates: Set<Int> = []) -> [WeightEntryDraft] {
        rows.compactMap { row in
            guard row.issue == nil, !row.isDuplicate || keepingDuplicates.contains(row.id) else { return nil }
            return row.draft
        }
    }

    static func encode(entries: [WeightEntry], unit: WeightUnit, includeNotes: Bool, includeHidden: Bool) -> String {
        var header = ["timestamp", "weight", "unit"]
        if includeNotes { header.append("notes") }
        if includeHidden { header.append("hidden") }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var rows = [header]
        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) where includeHidden || !entry.isHidden {
            var row = [formatter.string(from: entry.timestamp), String(unit.convert(fromKg: entry.weightKg)), unit.rawValue]
            if includeNotes { row.append(entry.notes ?? "") }
            if includeHidden { row.append(entry.isHidden ? "true" : "false") }
            rows.append(row)
        }
        return rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "\"" || $0 == "," || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func parseUnit(_ value: String) -> WeightUnit? {
        switch value {
        case "kg", "kilogram", "kilograms": return .kilograms
        case "lb", "lbs", "pound", "pounds": return .pounds
        case "st", "stone", "stones": return .stones
        default: return nil
        }
    }

    private static func parseDate(_ text: String, convention: DateConvention, timeZone: TimeZone) -> Date? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if convention == .iso8601 {
            let pattern = #"^\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,9})?(?:Z|[+-](?:[01]\d|2[0-3]):?[0-5]\d)$"#
            if value.range(of: pattern, options: .regularExpression) != nil {
                let dayFormatter = DateFormatter()
                dayFormatter.locale = Locale(identifier: "en_US_POSIX")
                dayFormatter.calendar = Calendar(identifier: .gregorian)
                dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                dayFormatter.dateFormat = "yyyy-MM-dd"
                dayFormatter.isLenient = false
                let dayText = String(value.prefix(10))
                guard let day = dayFormatter.date(from: dayText), dayFormatter.string(from: day) == dayText else { return nil }
                let zoneStart = value.suffix(5).first
                let instant = zoneStart == "+" || zoneStart == "-"
                    ? String(value.dropLast(2)) + ":" + String(value.suffix(2))
                    : value
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: instant) { return date }
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: instant) { return date }
            }
        }
        let formats: [String]
        switch convention {
        case .iso8601: formats = ["yyyy-MM-dd", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss.SSS"]
        case .monthFirst: formats = ["MM/dd/yyyy", "MM/dd/yyyy HH:mm", "MM/dd/yyyy HH:mm:ss"]
        case .dayFirst: formats = ["dd/MM/yyyy", "dd/MM/yyyy HH:mm", "dd/MM/yyyy HH:mm:ss"]
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.isLenient = false
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value), formatter.string(from: date) == value {
                return date
            }
        }
        return nil
    }
}
