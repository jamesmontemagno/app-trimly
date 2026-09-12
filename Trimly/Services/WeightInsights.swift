import Foundation

/// Nonpersistent, descriptive analytics. Missing days are never imputed.
enum WeightInsights {
    typealias DailyWeight = (date: Date, weight: Double)

    enum SupportState: Equatable {
        case insufficient, sparse, stale, supported
    }

    struct Support {
        let state: SupportState
        let loggingDays: Int
        let calendarDays: Int
        let daysSinceLatest: Int?
    }

    static func support(
        for dailyWeights: [DailyWeight],
        now: Date = Date(),
        minimumSamples: Int = 7,
        minimumSpan: Int = 7,
        maximumAge: Int = 7,
        calendar: Calendar = .current
    ) -> Support {
        guard now.timeIntervalSinceReferenceDate.isFinite else {
            return Support(state: .insufficient, loggingDays: 0, calendarDays: 0, daysSinceLatest: nil)
        }
        let today = calendar.startOfDay(for: now)
        let data = WeightAnalytics.normalizedDailyWeights(dailyWeights, calendar: calendar).filter { $0.date <= today }
        guard let first = data.first, let last = data.last else {
            return Support(state: .insufficient, loggingDays: 0, calendarDays: 0, daysSinceLatest: nil)
        }
        let span = (calendar.dateComponents([.day], from: first.date, to: last.date).day ?? 0) + 1
        let age = calendar.dateComponents([.day], from: last.date, to: today).day ?? 0
        let state: SupportState
        if age > maximumAge {
            state = .stale
        } else if data.count < max(2, minimumSamples) || span < minimumSpan {
            state = .insufficient
        } else if Double(data.count) / Double(max(1, span)) < 0.5 {
            state = .sparse
        } else {
            state = .supported
        }
        return Support(state: state, loggingDays: data.count, calendarDays: span, daysSinceLatest: age)
    }

    enum RecapPeriod: String, CaseIterable {
        case week, month
    }

    /// Half-open calendar-day interval: includes start, excludes end.
    struct Period: Equatable {
        let start: Date
        let end: Date

        init?(start: Date, end: Date, calendar: Calendar = .current) {
            guard start.timeIntervalSinceReferenceDate.isFinite, end.timeIntervalSinceReferenceDate.isFinite else { return nil }
            self.start = calendar.startOfDay(for: start)
            self.end = calendar.startOfDay(for: end)
            guard self.end > self.start else { return nil }
        }

        static func inclusive(from start: Date, through end: Date, calendar: Calendar = .current) -> Period? {
            guard start.timeIntervalSinceReferenceDate.isFinite, end.timeIntervalSinceReferenceDate.isFinite,
                  let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end)) else { return nil }
            return Period(start: start, end: exclusiveEnd, calendar: calendar)
        }
    }

    struct PeriodSummary {
        let period: Period
        let loggingDays: Int
        let calendarDays: Int
        let averageKg: Double?
        let changeKg: Double?
        let slopeKgPerDay: Double?
    }

    struct Comparison {
        let current: PeriodSummary
        let previous: PeriodSummary

        var averageDifferenceKg: Double? {
            guard let current = current.averageKg, let previous = previous.averageKg else { return nil }
            let difference = current - previous
            return difference.isFinite ? difference : nil
        }
    }

    static func summarize(_ data: [DailyWeight], in period: Period, calendar: Calendar = .current) -> PeriodSummary {
        let days = WeightAnalytics.normalizedDailyWeights(data, calendar: calendar)
            .filter { $0.date >= period.start && $0.date < period.end }
        let average = days.isEmpty ? nil : days.reduce(0.0) { $0 + $1.weight / Double(days.count) }
        let change: Double?
        if days.count >= 2, let first = days.first, let last = days.last {
            change = last.weight - first.weight
        } else {
            change = nil
        }
        return PeriodSummary(
            period: period,
            loggingDays: days.count,
            calendarDays: calendar.dateComponents([.day], from: period.start, to: period.end).day ?? 0,
            averageKg: average?.isFinite == true ? average : nil,
            changeKg: change?.isFinite == true ? change : nil,
            slopeKgPerDay: WeightAnalytics.calculateLinearRegression(dailyWeights: days, calendar: calendar).slope
        )
    }

    static func compare(
        dailyWeights: [DailyWeight], current: Period, previous: Period, calendar: Calendar = .current
    ) -> Comparison {
        Comparison(current: summarize(dailyWeights, in: current, calendar: calendar),
                   previous: summarize(dailyWeights, in: previous, calendar: calendar))
    }

    /// Compare equal elapsed calendar-day windows; shorter previous months cap both windows.
    static func recap(
        dailyWeights: [DailyWeight], period: RecapPeriod, now: Date = Date(), calendar: Calendar = .current
    ) -> Comparison? {
        guard now.timeIntervalSinceReferenceDate.isFinite else { return nil }
        let component: Calendar.Component = period == .week ? .weekOfYear : .month
        guard let currentInterval = calendar.dateInterval(of: component, for: now),
              let previousStart = calendar.date(byAdding: component, value: -1, to: currentInterval.start),
              let previousInterval = calendar.dateInterval(of: component, for: previousStart) else { return nil }
        let elapsed = (calendar.dateComponents([.day], from: currentInterval.start, to: calendar.startOfDay(for: now)).day ?? 0) + 1
        let previousDays = calendar.dateComponents([.day], from: previousInterval.start, to: previousInterval.end).day ?? 0
        let length = min(elapsed, previousDays)
        guard let currentEnd = calendar.date(byAdding: .day, value: length, to: currentInterval.start),
              let previousEnd = calendar.date(byAdding: .day, value: length, to: previousInterval.start),
              let current = Period(start: currentInterval.start, end: currentEnd, calendar: calendar),
              let previous = Period(start: previousInterval.start, end: previousEnd, calendar: calendar) else { return nil }
        return compare(dailyWeights: dailyWeights.filter { $0.date <= now }, current: current, previous: previous, calendar: calendar)
    }

    enum PaceState: Equatable {
        case noGoal, missingTargetDate, missingData, achieved, expired, insufficient, sparse, stale, available
    }

    struct GoalPace {
        let state: PaceState
        var requiredKgPerWeek: Double? = nil
        var observedKgPerWeek: Double? = nil
        var daysRemaining: Int? = nil
        var isOnPace: Bool? = nil
    }

    /// Arithmetic from the user's own target, not a recommended or medically assessed rate.
    static func goalPace(
        goal: Goal?, dailyWeights: [DailyWeight], now: Date = Date(), calendar: Calendar = .current
    ) -> GoalPace {
        guard let goal else { return GoalPace(state: .noGoal) }
        if goal.completionReason == .achieved { return GoalPace(state: .achieved) }
        guard now.timeIntervalSinceReferenceDate.isFinite, goal.targetWeightKg.isFinite, goal.targetWeightKg > 0,
              goal.startDate.timeIntervalSinceReferenceDate.isFinite else { return GoalPace(state: .missingData) }
        let today = calendar.startOfDay(for: now)
        let goalStart = calendar.startOfDay(for: goal.startDate)
        let data = WeightAnalytics.normalizedDailyWeights(dailyWeights, calendar: calendar)
            .filter { $0.date >= goalStart && $0.date <= today }
        guard let latest = data.last else { return GoalPace(state: .missingData) }
        let startWeight = goal.startingWeightKg ?? data.first?.weight
        guard let startWeight, startWeight.isFinite, startWeight > 0 else { return GoalPace(state: .missingData) }
        let unchangedTarget = goal.targetWeightKg == startWeight
        let isGainGoal = goal.targetWeightKg > (unchangedTarget ? latest.weight : startWeight)
        if (unchangedTarget && abs(latest.weight - goal.targetWeightKg) <= 0.05)
            || (!unchangedTarget && ((isGainGoal && latest.weight >= goal.targetWeightKg)
                || (!isGainGoal && latest.weight <= goal.targetWeightKg))) {
            return GoalPace(state: .achieved)
        }
        guard let targetDate = goal.targetDate else { return GoalPace(state: .missingTargetDate) }
        guard targetDate.timeIntervalSinceReferenceDate.isFinite else { return GoalPace(state: .missingTargetDate) }
        let remaining = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: targetDate)).day ?? 0
        guard remaining > 0 else { return GoalPace(state: .expired, daysRemaining: remaining) }
        let age = calendar.dateComponents([.day], from: latest.date, to: today).day ?? 0
        guard age <= 7 else { return GoalPace(state: .stale, daysRemaining: remaining) }
        let required = (goal.targetWeightKg - latest.weight) * 7 / Double(remaining)
        guard required.isFinite else { return GoalPace(state: .missingData) }
        let recentStart = calendar.date(byAdding: .day, value: -27, to: today) ?? today
        let recent = data.filter { $0.date >= recentStart }
        let evidence = support(for: recent, now: now, calendar: calendar)
        let state: PaceState
        switch evidence.state {
        case .insufficient: state = .insufficient
        case .sparse: state = .sparse
        case .stale: state = .stale
        case .supported: state = .available
        }
        guard state == .available else {
            return GoalPace(state: state, requiredKgPerWeek: evidence.state == .stale ? nil : required, daysRemaining: remaining)
        }
        guard let slope = WeightAnalytics.calculateLinearRegression(dailyWeights: recent, calendar: calendar).slope,
              (slope * 7).isFinite else { return GoalPace(state: .missingData) }
        let observed = slope * 7
        return GoalPace(state: .available, requiredKgPerWeek: required, observedKgPerWeek: observed,
                        daysRemaining: remaining, isOnPace: isGainGoal ? observed >= required : observed <= required)
    }
}
