import Foundation
import Testing
@testable import TrimTally

@MainActor
struct InsightsTests {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        value.firstWeekday = 2
        value.minimumDaysInFirstWeek = 4
        return value
    }

    private func date(_ year: Int = 2026, _ month: Int = 3, _ day: Int = 18) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func offset(_ days: Int, from date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }

    private func series(latest: Double, slope: Double, count: Int = 14, now: Date) -> [WeightInsights.DailyWeight] {
        (0..<count).map { index in
            let daysAgo = count - 1 - index
            return (date: offset(-daysAgo, from: now), weight: latest - slope * Double(daysAgo))
        }
    }

    @Test func chartSelection_snapsToNearestLoggedDayAcrossGaps() {
        let first = ChartDataPoint(date: date(), weight: 80)
        let last = ChartDataPoint(date: offset(6, from: date()), weight: 79)
        let points = [first, last]

        #expect(ChartDataPoint.nearest(to: offset(1, from: date()), in: points) == first)
        #expect(ChartDataPoint.nearest(to: offset(5, from: date()), in: points) == last)
        #expect(ChartDataPoint.nearest(to: offset(3, from: date()), in: points) == first)
        #expect(ChartDataPoint.nearest(to: last.date, in: points) == last)
    }

    @Test func chartSelection_handlesEdgesSinglePointAndEmptyData() {
        let first = ChartDataPoint(date: date(), weight: 80)
        let last = ChartDataPoint(date: offset(6, from: date()), weight: 79)

        #expect(ChartDataPoint.nearest(to: offset(-10, from: date()), in: [first, last]) == first)
        #expect(ChartDataPoint.nearest(to: offset(10, from: date()), in: [first, last]) == last)
        #expect(ChartDataPoint.nearest(to: last.date, in: [first]) == first)
        #expect(ChartDataPoint.nearest(to: date(), in: []) == nil)
    }

    @Test func weeklyRecap_comparesSameElapsedDaysAndExcludesLaterDays() throws {
        let now = date()
        let data: [WeightInsights.DailyWeight] = [
            (date(2026, 3, 9), 84), (date(2026, 3, 10), 82), (date(2026, 3, 11), 80),
            (date(2026, 3, 12), 150), (date(2026, 3, 16), 81), (date(2026, 3, 18), 79),
            (date(2026, 3, 19), 200)
        ]
        let recap = try #require(WeightInsights.recap(dailyWeights: data, period: .week, now: now, calendar: calendar))
        #expect(recap.current.calendarDays == 3)
        #expect(recap.previous.calendarDays == 3)
        #expect(recap.current.loggingDays == 2)
        #expect(recap.previous.loggingDays == 3)
        #expect(recap.current.averageKg == 80)
        #expect(recap.previous.averageKg == 82)
        #expect(recap.averageDifferenceKg == -2)
    }

    @Test func monthlyRecap_capsBothWindowsToShorterMonthIncludingLeapYears() throws {
        let recap = try #require(WeightInsights.recap(dailyWeights: [], period: .month, now: date(2026, 3, 31), calendar: calendar))
        #expect(recap.current.calendarDays == 28)
        #expect(recap.previous.calendarDays == 28)
        #expect(recap.current.period.end == date(2026, 3, 29))
        let leap = try #require(WeightInsights.recap(dailyWeights: [], period: .month, now: date(2024, 3, 31), calendar: calendar))
        #expect(leap.current.calendarDays == 29)
        #expect(leap.previous.calendarDays == 29)
        #expect(recap.averageDifferenceKg == nil)
    }

    @Test func recap_firstDayAndYearBoundary() throws {
        let recap = try #require(WeightInsights.recap(dailyWeights: [(date(2026, 1, 1), 80)],
                                                     period: .month, now: date(2026, 1, 1), calendar: calendar))
        #expect(recap.current.calendarDays == 1)
        #expect(recap.previous.calendarDays == 1)
        #expect(recap.previous.period.start == date(2025, 12, 1))
        #expect(recap.previous.averageKg == nil)
        #expect(recap.averageDifferenceKg == nil)
    }

    @Test func summary_weightsDaysEquallyAndUsesHalfOpenBounds() throws {
        let period = try #require(WeightInsights.Period.inclusive(from: date(), through: offset(1, from: date()), calendar: calendar))
        let data: [WeightInsights.DailyWeight] = [
            (date(), 80), (date().addingTimeInterval(3600), 84),
            (offset(1, from: date()), 90), (offset(2, from: date()), 200), (date(), .nan)
        ]
        let summary = WeightInsights.summarize(data, in: period, calendar: calendar)
        #expect(summary.averageKg == 86)
        #expect(summary.loggingDays == 2)
        #expect(summary.calendarDays == 2)
        #expect(summary.changeKg == 8)
        #expect(summary.slopeKgPerDay == 8)
    }

    @Test func customComparison_supportsDifferentLengthsAndMissingPeriods() throws {
        let first = try #require(WeightInsights.Period.inclusive(from: date(), through: offset(2, from: date()), calendar: calendar))
        let second = try #require(WeightInsights.Period.inclusive(from: offset(-7, from: date()), through: offset(-1, from: date()), calendar: calendar))
        let comparison = WeightInsights.compare(dailyWeights: [(date(), 80)], current: first, previous: second, calendar: calendar)
        #expect(comparison.current.calendarDays == 3)
        #expect(comparison.previous.calendarDays == 7)
        #expect(comparison.averageDifferenceKg == nil)
        #expect(WeightInsights.Period.inclusive(from: date(), through: offset(-1, from: date()), calendar: calendar) == nil)
    }

    @Test func recap_usesVisibleDailyAggregatesNotRawCheckinCount() throws {
        let now = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let entries = [
            WeightEntry(timestamp: now, weightKg: 80, displayUnitAtEntry: .kilograms),
            WeightEntry(timestamp: now.addingTimeInterval(3600), weightKg: 84, displayUnitAtEntry: .kilograms),
            WeightEntry(timestamp: tomorrow, weightKg: 90, displayUnitAtEntry: .kilograms),
            WeightEntry(timestamp: tomorrow, weightKg: 200, displayUnitAtEntry: .kilograms, isHidden: true)
        ]
        let daily = WeightAnalytics.aggregateByDay(entries: entries, mode: .average).map { (date: $0.key, weight: $0.value) }
        let period = try #require(WeightInsights.Period.inclusive(from: now, through: tomorrow))
        let summary = WeightInsights.summarize(daily, in: period)
        #expect(summary.loggingDays == 2)
        #expect(summary.averageKg == 86)
    }

    @Test func support_distinguishesSparseStaleAndInsufficient() {
        let now = date()
        let sparse = (0..<7).map { (date: offset(-$0 * 5, from: now), weight: 80.0) }
        #expect(WeightInsights.support(for: sparse, now: now, calendar: calendar).state == .sparse)
        #expect(WeightInsights.support(for: [(now, 80)], now: now, calendar: calendar).state == .insufficient)
        let stale = series(latest: 80, slope: 0, now: offset(-8, from: now))
        #expect(WeightInsights.support(for: stale, now: now, calendar: calendar).state == .stale)
        #expect(WeightInsights.support(for: series(latest: 80, slope: 0, now: now), now: now, calendar: calendar).state == .supported)
    }

    @Test func goalPace_lossAndGainHaveCorrectSignedRatesAndDirection() throws {
        let now = date()
        let loss = Goal(targetWeightKg: 79, startDate: offset(-20, from: now), targetDate: offset(14, from: now), startingWeightKg: 90)
        let lossPace = WeightInsights.goalPace(goal: loss, dailyWeights: series(latest: 80, slope: -0.1, now: now), now: now, calendar: calendar)
        #expect(lossPace.state == .available)
        #expect(lossPace.requiredKgPerWeek == -0.5)
        #expect(abs(try #require(lossPace.observedKgPerWeek) + 0.7) < 0.000001)
        #expect(lossPace.isOnPace == true)

        let gain = Goal(targetWeightKg: 66, startDate: offset(-20, from: now), targetDate: offset(14, from: now), startingWeightKg: 60)
        let gainPace = WeightInsights.goalPace(goal: gain, dailyWeights: series(latest: 65, slope: 0.1, now: now), now: now, calendar: calendar)
        #expect(gainPace.state == .available)
        #expect(gainPace.requiredKgPerWeek == 0.5)
        #expect(abs(try #require(gainPace.observedKgPerWeek) - 0.7) < 0.000001)
        #expect(gainPace.isOnPace == true)

        let wrongDirection = WeightInsights.goalPace(goal: gain, dailyWeights: series(latest: 65, slope: -0.1, now: now), now: now, calendar: calendar)
        #expect(wrongDirection.isOnPace == false)
        loss.targetWeightKg = 75
        #expect(WeightInsights.goalPace(goal: loss, dailyWeights: series(latest: 80, slope: -0.1, now: now), now: now, calendar: calendar).isOnPace == false)
    }

    @Test func goalPace_explicitMissingAchievedAndExpiredStates() {
        let now = date()
        let data = series(latest: 80, slope: -0.1, now: now)
        #expect(WeightInsights.goalPace(goal: nil, dailyWeights: data, now: now).state == .noGoal)
        let goal = Goal(targetWeightKg: 75, startDate: offset(-20, from: now), startingWeightKg: 90)
        #expect(WeightInsights.goalPace(goal: goal, dailyWeights: data, now: now, calendar: calendar).state == .missingTargetDate)
        #expect(WeightInsights.goalPace(goal: goal, dailyWeights: [], now: now, calendar: calendar).state == .missingData)
        goal.targetDate = now
        #expect(WeightInsights.goalPace(goal: goal, dailyWeights: data, now: now, calendar: calendar).state == .expired)
        goal.targetWeightKg = 81
        #expect(WeightInsights.goalPace(goal: goal, dailyWeights: data, now: now, calendar: calendar).state == .achieved)
        goal.targetWeightKg = 75
        goal.startingWeightKg = 70
        #expect(WeightInsights.goalPace(goal: goal, dailyWeights: data, now: now, calendar: calendar).state == .achieved)
        goal.markAchieved()
        #expect(WeightInsights.goalPace(goal: goal, dailyWeights: [], now: now, calendar: calendar).state == .achieved)
    }

    @Test func plateau_rejectsShortSparseStaleAndVariableHistory() {
        let now = date()
        let detector = PlateauDetectionService()
        #expect(detector.detectPlateau(dailyWeights: series(latest: 80, slope: 0, now: now), now: now, calendar: calendar)?.duration == 14)
        #expect(detector.detectPlateau(dailyWeights: series(latest: 80, slope: 0, count: 7, now: now), now: now, calendar: calendar) == nil)
        let sparse = (0..<14).map { (date: offset(-$0 * 3, from: now), weight: 80.0) }
        #expect(detector.detectPlateau(dailyWeights: sparse, now: now, calendar: calendar) == nil)
        #expect(detector.detectPlateau(dailyWeights: series(latest: 80, slope: 0, now: offset(-8, from: now)), now: now, calendar: calendar) == nil)
        let variable = (0..<14).map { (date: offset(-$0, from: now), weight: $0 == 0 || $0 == 13 ? 80.0 : $0.isMultiple(of: 2) ? 82.0 : 78.0) }
        #expect(detector.detectPlateau(dailyWeights: variable, now: now, calendar: calendar) == nil)
    }

    @Test func goalPace_suppressesStaleAndSparseObservedRates() {
        let now = date()
        let goal = Goal(targetWeightKg: 75, startDate: offset(-90, from: now),
                        targetDate: offset(14, from: now), startingWeightKg: 90)
        let stale = WeightInsights.goalPace(goal: goal, dailyWeights: series(latest: 80, slope: -0.1, now: offset(-40, from: now)),
                                           now: now, calendar: calendar)
        #expect(stale.state == .stale)
        #expect(stale.requiredKgPerWeek == nil)
        #expect(stale.observedKgPerWeek == nil)
        let sparse = (0..<7).map { (date: offset(-$0 * 4, from: now), weight: 80.0 + Double($0)) }
        let result = WeightInsights.goalPace(goal: goal, dailyWeights: sparse, now: now, calendar: calendar)
        #expect(result.state == .sparse)
        #expect(result.requiredKgPerWeek != nil)
        #expect(result.observedKgPerWeek == nil)
        #expect(result.isOnPace == nil)
    }

    @Test func chartRanges_includeEndpointsAndRequireGoalForSinceGoal() throws {
        let now = date()
        let custom = try #require(ChartRange.custom.period(now: now, firstDate: nil, goalStart: nil,
                                                         customStart: offset(-3, from: now), customEnd: now, calendar: calendar))
        #expect(custom.start == offset(-3, from: now))
        #expect(custom.end == offset(1, from: now))
        #expect(ChartRange.sinceGoal.period(now: now, firstDate: nil, goalStart: nil, customStart: now, customEnd: now) == nil)
        let all = try #require(ChartRange.allTime.period(now: now, firstDate: offset(-1000, from: now), goalStart: nil,
                                                       customStart: now, customEnd: now, calendar: calendar))
        #expect(all.start == offset(-1000, from: now))
    }

    @Test func unchangedTargetDoesNotTreatLowerWeightAsAchievement() {
        let now = date()
        let goal = Goal(targetWeightKg: 80, startDate: offset(-20, from: now),
                        targetDate: offset(14, from: now), startingWeightKg: 80)
        let result = WeightInsights.goalPace(
            goal: goal, dailyWeights: series(latest: 79, slope: 0.1, now: now), now: now, calendar: calendar
        )
        #expect(result.state == .available)
        #expect(result.requiredKgPerWeek == 0.5)
        #expect(result.isOnPace == true)
    }
}
