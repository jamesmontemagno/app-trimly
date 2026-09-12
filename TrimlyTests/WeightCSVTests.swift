import Foundation
import Testing
@testable import TrimTally

@MainActor
struct WeightCSVTests {
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    @Test func quotedFieldsPreserveCommasQuotesAndMultilineCRLF() throws {
        let table = try WeightCSV.parse("\u{FEFF}timestamp,weight,notes\r\n2025-01-01,70,\"First, \"\"quoted\"\"\r\nsecond line\"\r\n2025-01-02,71,OK\r\n")
        #expect(table.headers == ["timestamp", "weight", "notes"])
        #expect(table.records.count == 2)
        #expect(table.records[0].fields[2] == "First, \"quoted\"\r\nsecond line")
        #expect(table.records[0].line == 2)
        #expect(table.records[1].line == 4)
        #expect(table.records.allSatisfy { $0.issue == nil })
    }

    @Test func malformedRecordsAreNotSilentlyDiscarded() throws {
        let table = try WeightCSV.parse("date,weight,notes\n2025-01-01,70,bad\"quote\n2025-01-02,71,\"ok\"suffix\n2025-01-03,72,\"unfinished")
        #expect(table.records.map(\.issue) == [.malformedQuote, .malformedQuote, .unclosedQuote])
    }

    @Test func mappingConvertsUnitsAndPreservesNotes() throws {
        let table = try WeightCSV.parse("comment,amount,when,units\n\"After, lunch\",154.3234,2025-01-02T13:14:15.125Z,lbs")
        let rows = WeightCSV.review(table, mapping: .init(timestamp: 2, weight: 1, unit: 3, notes: 0), defaultUnit: .stones, dateConvention: .iso8601, now: now)
        let draft = try #require(rows.first?.draft)
        #expect(abs(draft.weightKg - 70) < 0.000001)
        #expect(draft.unit == .pounds)
        #expect(draft.notes == "After, lunch")
        #expect(rows[0].issue == nil)
    }

    @Test func legacyKilogramColumnDoesNotUseHistoricalDisplayUnit() throws {
        let table = try WeightCSV.parse("id,timestamp,weight_kg,displayUnitAtEntry,notes\nabc,2025-01-01,70,lb,")
        let mapping = WeightCSV.suggestedMapping(for: table)
        #expect(mapping.weight == 2)
        #expect(mapping.unit == nil)
        #expect(WeightCSV.suggestedUnit(for: table, mapping: mapping) == .kilograms)
        let rows = WeightCSV.review(table, mapping: mapping, defaultUnit: .kilograms, dateConvention: .iso8601, now: now)
        #expect(rows.first?.draft?.weightKg == 70)
    }

    @Test func invalidRowsExposeTheirIndividualErrors() throws {
        let table = try WeightCSV.parse("date,weight,unit\n2025-01-01,nan,kg\n2025-01-01,inf,kg\n2025-01-01,0,kg\n2025-01-01,-2,kg\nnot-a-date,70,kg\n2025-01-01,70,oz\n2025-01-01,70\n2025-01-01,70,kg")
        let rows = WeightCSV.review(table, mapping: .init(timestamp: 0, weight: 1, unit: 2), defaultUnit: .kilograms, dateConvention: .iso8601, now: now)
        #expect(rows.map(\.issue) == [.invalidWeight, .invalidWeight, .invalidWeight, .invalidWeight, .invalidDate, .invalidUnit, .columnCount, nil])
        #expect(WeightCSV.draftsToImport(from: rows).count == 1)
    }

    @Test func invalidDatesFutureDatesAndOverflowAreRejected() throws {
        let table = try WeightCSV.parse("date,weight\n2025-02-30T12:00:00Z,70\n2025-01-01T12:00:00Zjunk,70\n2099-01-01,70\n2025-01-01,1e309")
        let rows = WeightCSV.review(table, mapping: .init(), defaultUnit: .kilograms, dateConvention: .iso8601, now: now)
        #expect(rows.map(\.issue) == [.invalidDate, .invalidDate, .futureDate, .invalidWeight])
    }

    @Test func dateConventionIsExplicitAndDatesUseChosenTimeZone() throws {
        let table = try WeightCSV.parse("date,weight\n03/04/2025,70")
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let monthFirst = WeightCSV.review(table, mapping: .init(), defaultUnit: .kilograms, dateConvention: .monthFirst, now: now, timeZone: utc)
        let dayFirst = WeightCSV.review(table, mapping: .init(), defaultUnit: .kilograms, dateConvention: .dayFirst, now: now, timeZone: utc)
        let iso = WeightCSV.review(table, mapping: .init(), defaultUnit: .kilograms, dateConvention: .iso8601, now: now, timeZone: utc)
        #expect(monthFirst[0].draft?.timestamp != dayFirst[0].draft?.timestamp)
        #expect(iso[0].issue == .invalidDate)
        #expect(monthFirst[0].issue == nil)
        #expect(dayFirst[0].issue == nil)
    }

    @Test func offsetTimestampPreservesInstant() throws {
        let table = try WeightCSV.parse("date,weight\n2025-01-01T12:00:00+02:00,70\n2025-01-01T10:00:00Z,70\n2025-01-01T12:00:00+0200,70")
        let rows = WeightCSV.review(table, mapping: .init(), defaultUnit: .kilograms, dateConvention: .iso8601, now: now)
        #expect(rows[0].draft?.timestamp == rows[1].draft?.timestamp)
        #expect(rows[0].draft?.timestamp == rows[2].draft?.timestamp)
        #expect(rows[1].isDuplicate)
    }

    @Test func duplicatesRequireExplicitKeepAndNeverMergeNotes() throws {
        let table = try WeightCSV.parse("date,weight,notes\n2025-01-01T10:00:00Z,70,one\n2025-01-01T10:00:00Z,70,two\n2025-01-01T11:00:00Z,70,three")
        let rows = WeightCSV.review(table, mapping: .init(timestamp: 0, weight: 1, notes: 2), defaultUnit: .kilograms, dateConvention: .iso8601, now: now)
        #expect(rows.map(\.isDuplicate) == [false, true, false])
        #expect(WeightCSV.draftsToImport(from: rows).map(\.notes) == ["one", "three"])
        #expect(WeightCSV.draftsToImport(from: rows, keepingDuplicates: [3]).map(\.notes) == ["one", "two", "three"])
        let existing = try #require(rows[0].draft)
        let checked = WeightCSV.review(table, mapping: .init(timestamp: 0, weight: 1, notes: 2), defaultUnit: .kilograms, dateConvention: .iso8601, existing: [existing], now: now)
        #expect(checked.map(\.isDuplicate) == [true, true, false])
        #expect(existing.notes == "one")
    }

    @Test func invalidMappingCannotReadWrongColumns() throws {
        let table = try WeightCSV.parse("date,weight\n2025-01-01,70")
        for mapping in [WeightCSV.Mapping(timestamp: 0, weight: 0), .init(timestamp: 0, weight: 9)] {
            let rows = WeightCSV.review(table, mapping: mapping, defaultUnit: .kilograms, dateConvention: .iso8601, now: now)
            #expect(rows[0].issue == .invalidMapping)
        }
    }

    @Test func headerlessDataRetainsFirstRecord() throws {
        let table = try WeightCSV.parse("2025-01-01,70\r2025-01-02,71", hasHeader: false)
        #expect(table.headers == ["1", "2"])
        #expect(table.records.count == 2)
        #expect(table.records[0].line == 1)
    }

    @Test func exportRoundTripsNotesAndRespectsPrivacyOptions() throws {
        let timestamp = Date(timeIntervalSince1970: 1_735_732_800)
        let visible = WeightEntry(timestamp: timestamp, weightKg: 70, displayUnitAtEntry: .pounds, notes: "a,\"b\"\r\nc")
        let hidden = WeightEntry(timestamp: timestamp.addingTimeInterval(60), weightKg: 71, displayUnitAtEntry: .kilograms, isHidden: true)
        let text = WeightCSV.encode(entries: [hidden, visible], unit: .stones, includeNotes: true, includeHidden: true)
        #expect(text.contains("\r\n"))
        let table = try WeightCSV.parse(text)
        let rows = WeightCSV.review(table, mapping: WeightCSV.suggestedMapping(for: table), defaultUnit: .pounds, dateConvention: .iso8601, now: now)
        #expect(rows.count == 2)
        #expect(abs((rows[0].draft?.weightKg ?? 0) - 70) < 0.000001)
        #expect(rows[0].draft?.notes == visible.notes)
        let privateTable = try WeightCSV.parse(WeightCSV.encode(entries: [visible, hidden], unit: .kilograms, includeNotes: false, includeHidden: false))
        #expect(privateTable.headers == ["timestamp", "weight", "unit"])
        #expect(privateTable.records.count == 1)
    }

    @Test func decodingRejectsInvalidUTF8AndEmptyInput() throws {
        #expect(throws: WeightCSV.Issue.invalidEncoding) { try WeightCSV.decode(Data([0xFF])) }
        #expect(throws: WeightCSV.Issue.emptyFile) { try WeightCSV.parse("\r\n") }
        #expect(throws: WeightCSV.Issue.tooLarge) { try WeightCSV.decode(Data(repeating: 65, count: WeightCSV.maximumBytes + 1)) }
    }
}
