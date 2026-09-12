import Foundation
import Testing
@testable import TrimTally

@MainActor
struct WeightReportTests {
    private let day = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_735_732_800))

    private func entry(_ kg: Double, offset: TimeInterval, hidden: Bool = false) -> WeightEntry {
        WeightEntry(timestamp: day.addingTimeInterval(offset), weightKg: kg, displayUnitAtEntry: .kilograms, isHidden: hidden)
    }

    @Test func emptyReportHasNoInventedSummary() {
        let report = WeightReport(entries: [], unit: .kilograms)
        #expect(report.points.isEmpty)
        #expect(report.firstWeightKg == nil)
        #expect(report.latestWeightKg == nil)
        #expect(report.changeKg == nil)
        #expect(report.averageKg == nil)
    }

    @Test func reportExcludesHiddenAndInvalidMeasurementsAndSortsDays() {
        let report = WeightReport(entries: [
            entry(78, offset: 86_500), entry(80, offset: 100),
            entry(10, offset: 90_000, hidden: true), entry(.nan, offset: 200),
            entry(-1, offset: 300)
        ], unit: .pounds, goalWeightKg: 75)
        #expect(report.entryCount == 2)
        #expect(report.points.count == 2)
        #expect(report.firstWeightKg == 80)
        #expect(report.latestWeightKg == 78)
        #expect(report.changeKg == -2)
        #expect(report.averageKg == 79)
        #expect(report.goalWeightKg == 75)
        #expect(report.unit == .pounds)
        #expect(report.formattedWeight(80).contains("lb"))
    }

    @Test func reportUsesSelectedDailyAggregationAndAverageOfDays() {
        let entries = [entry(80, offset: 100), entry(82, offset: 200), entry(78, offset: 86_500)]
        let latest = WeightReport(entries: entries, unit: .kilograms, aggregation: .latest)
        let average = WeightReport(entries: entries, unit: .kilograms, aggregation: .average)
        #expect(latest.points.map(\.weightKg) == [82, 78])
        #expect(average.points.map(\.weightKg) == [81, 78])
        #expect(latest.averageKg == 80)
        #expect(average.averageKg == 79.5)
        #expect(average.entryCount == 3)
    }

    @Test func singleDayAndInvalidGoalsAreHandled() {
        let report = WeightReport(entries: [entry(80, offset: 100)], unit: .stones, goalWeightKg: .infinity)
        #expect(report.changeKg == 0)
        #expect(report.averageKg == 80)
        #expect(report.goalWeightKg == nil)
        #expect(report.formattedWeight(80).contains("st"))
    }

    @Test func dateRangeIncludesWholeEndDayWithExclusiveUpperBound() throws {
        var range = PortabilityDateRange()
        range.allTime = false
        range.start = day.addingTimeInterval(3_600)
        range.end = day.addingTimeInterval(7_200)
        #expect(range.isValid)
        #expect(range.lowerBound == day)
        #expect(range.upperBound == Calendar.current.date(byAdding: .day, value: 1, to: day))
        range.start = try #require(Calendar.current.date(byAdding: .day, value: 2, to: day))
        #expect(!range.isValid)
        range.allTime = true
        #expect(range.lowerBound == nil)
        #expect(range.upperBound == nil)
    }

    @Test func shareSnapshotUsesSevenCalendarDaysAndExcludesHiddenAndFutureEntries() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2025, month: 3, day: 10, hour: 12))!
        let today = calendar.startOfDay(for: now)
        let entries = [
            WeightEntry(timestamp: calendar.date(byAdding: .day, value: -6, to: today)!, weightKg: 80, displayUnitAtEntry: .kilograms),
            WeightEntry(timestamp: calendar.date(byAdding: .day, value: -2, to: today)!, weightKg: 79, displayUnitAtEntry: .kilograms),
            WeightEntry(timestamp: calendar.date(byAdding: .day, value: 1, to: today)!, weightKg: 70, displayUnitAtEntry: .kilograms),
            WeightEntry(timestamp: today, weightKg: 90, displayUnitAtEntry: .kilograms, isHidden: true)
        ]
        let snapshot = ShareCheckInSnapshot(
            entries: entries,
            goal: nil,
            unit: .kilograms,
            aggregation: .latest,
            decimalPrecision: 1,
            calendar: calendar,
            now: now
        )
        #expect(snapshot.days.count == 7)
        #expect(snapshot.checkedInDays == 2)
        #expect(snapshot.days.first?.weightKg == 80)
        #expect(snapshot.days.last?.weightKg == nil)
        #expect(snapshot.changeKg == -1)
    }

    @Test func shareSnapshotDoesNotClaimChangeWithOneRecordedDay() {
        let snapshot = ShareCheckInSnapshot(
            entries: [entry(80, offset: 100)],
            goal: nil,
            unit: .kilograms,
            aggregation: .latest,
            decimalPrecision: 1,
            now: day
        )
        #expect(snapshot.checkedInDays == 1)
        #expect(snapshot.changeKg == nil)
    }
}
