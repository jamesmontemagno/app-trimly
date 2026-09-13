import Foundation

extension L10n {
    enum Insights {
        static let allTime = LocalizedStringResource("range.allTime", defaultValue: "All time", table: "Insights")
        static let sinceGoal = LocalizedStringResource("range.sinceGoal", defaultValue: "Since goal", table: "Insights")
        static let customRange = LocalizedStringResource("range.custom", defaultValue: "Custom range", table: "Insights")
        static let rangeWeekShort = LocalizedStringResource("range.short.week", defaultValue: "7D", table: "Insights")
        static let rangeMonthShort = LocalizedStringResource("range.short.month", defaultValue: "1M", table: "Insights")
        static let rangeQuarterShort = LocalizedStringResource("range.short.quarter", defaultValue: "3M", table: "Insights")
        static let rangeYearShort = LocalizedStringResource("range.short.year", defaultValue: "1Y", table: "Insights")
        static let moreRanges = LocalizedStringResource("range.more", defaultValue: "More", table: "Insights")
        static let startDate = LocalizedStringResource("range.start", defaultValue: "Start date", table: "Insights")
        static let endDate = LocalizedStringResource("range.end", defaultValue: "End date", table: "Insights")
        static let noGoalRange = LocalizedStringResource("range.noGoal", defaultValue: "Set a goal to view its date range.", table: "Insights")
        static let invalidRange = LocalizedStringResource("range.invalid", defaultValue: "Choose an end date on or after the start date.", table: "Insights")
        static let recapTitle = LocalizedStringResource("recap.title", defaultValue: "Period recap", table: "Insights")
        static let weekly = LocalizedStringResource("recap.weekly", defaultValue: "This week", table: "Insights")
        static let monthly = LocalizedStringResource("recap.monthly", defaultValue: "This month", table: "Insights")
        static let currentPeriod = LocalizedStringResource("recap.current", defaultValue: "Current period", table: "Insights")
        static let previousPeriod = LocalizedStringResource("recap.previous", defaultValue: "Previous period", table: "Insights")
        static let comparePeriods = LocalizedStringResource("recap.compare", defaultValue: "Compare custom periods", table: "Insights")
        static let comparePeriodsTitle = LocalizedStringResource("recap.compareTitle", defaultValue: "Compare periods", table: "Insights")
        static let recapExplanation = LocalizedStringResource("recap.explanation", defaultValue: "Equal elapsed calendar-day windows are compared. A shorter previous month caps both windows. Each logged day has equal weight; missing days are not estimated.", table: "Insights")
        static let customExplanation = LocalizedStringResource("recap.customExplanation", defaultValue: "Compare daily averages and logging coverage. Periods can have different lengths; missing days are not estimated.", table: "Insights")
        static let averageDifference = LocalizedStringResource("recap.difference", defaultValue: "Average change from previous period", table: "Insights")
        static let unavailableComparison = LocalizedStringResource("recap.unavailable", defaultValue: "Log in both periods to compare averages.", table: "Insights")
        static let noMeasurements = LocalizedStringResource("recap.noMeasurements", defaultValue: "No measurements in this period", table: "Insights")
        static let loggingDays = LocalizedStringResource("analytics.loggingDays", defaultValue: "Logging days", table: "Insights")
        static let loggingDayAverage = LocalizedStringResource("analytics.loggingDayAverage", defaultValue: "Average · last 7 logging days", table: "Insights")
        static let samplesExplanation = LocalizedStringResource("analytics.samplesExplanation", defaultValue: "SMA and EMA use logging-day samples, not elapsed calendar days. Missing days are skipped. Earlier history warms the lines before the visible range.", table: "Insights")
        static let insufficient = LocalizedStringResource("support.insufficient", defaultValue: "More logging history is needed for a reliable trend.", table: "Insights")
        static let sparse = LocalizedStringResource("support.sparse", defaultValue: "Measurements cover fewer than half the days. Trend estimates are unavailable.", table: "Insights")
        static let stale = LocalizedStringResource("support.stale", defaultValue: "No recent measurement. Log again to update the estimate.", table: "Insights")
        static let supportExplanation = LocalizedStringResource("support.explanation", defaultValue: "Trends require at least 7 logging days spanning a week, coverage of half the days, and a measurement within 7 days.", table: "Insights")
        static let plateauExplanation = LocalizedStringResource("plateau.explanation", defaultValue: "Recent measurements show little overall change and low variation. This describes the data for either gain or loss goals, not a diagnosis or a reason to change your plan.", table: "Insights")
        static let dismissPlateau = LocalizedStringResource("plateau.dismiss", defaultValue: "Dismiss plateau insight", table: "Insights")
        static let dayDetails = LocalizedStringResource("chart.dayDetails", defaultValue: "Entries and notes", table: "Insights")
        static let dayDetailsHint = LocalizedStringResource("chart.dayDetailsHint", defaultValue: "Opens all entries and notes for this day", table: "Insights")
        static let notes = LocalizedStringResource("chart.notes", defaultValue: "Has notes", table: "Insights")
        static let chooseDay = LocalizedStringResource("chart.chooseDay", defaultValue: "Choose a logging day", table: "Insights")
        static let weightTrend = LocalizedStringResource("chart.weightTrend", defaultValue: "Weight trend", table: "Insights")
        static let dateAxis = LocalizedStringResource("chart.date", defaultValue: "Date", table: "Insights")
        static let seriesAxis = LocalizedStringResource("chart.series", defaultValue: "Series", table: "Insights")
        static let paceTitle = LocalizedStringResource("pace.title", defaultValue: "Goal pace", table: "Insights")
        static let requiredPace = LocalizedStringResource("pace.required", defaultValue: "Required average change", table: "Insights")
        static let observedPace = LocalizedStringResource("pace.observed", defaultValue: "Observed change · last 28 days", table: "Insights")
        static let paceExplanation = LocalizedStringResource("pace.explanation", defaultValue: "Arithmetic based on your chosen target and date, not a recommended rate or medical advice. Trends can change.", table: "Insights")
        static let noGoal = LocalizedStringResource("pace.noGoal", defaultValue: "Set a goal to see its pace.", table: "Insights")
        static let missingTargetDate = LocalizedStringResource("pace.missingDate", defaultValue: "Add a target date to your goal to compare pace.", table: "Insights")
        static let missingData = LocalizedStringResource("pace.missingData", defaultValue: "A valid measurement since the goal started is needed.", table: "Insights")
        static let achieved = LocalizedStringResource("pace.achieved", defaultValue: "Goal already achieved", table: "Insights")
        static let expired = LocalizedStringResource("pace.expired", defaultValue: "Target date reached or passed. Choose a future date to compare pace.", table: "Insights")
        static let onPace = LocalizedStringResource("pace.onPace", defaultValue: "Observed trend meets the chosen pace", table: "Insights")
        static let behindPace = LocalizedStringResource("pace.behind", defaultValue: "Observed trend does not currently meet the chosen pace", table: "Insights")
        static let customize = LocalizedStringResource("dashboard.customize", defaultValue: "Customize dashboard", table: "Insights")
        static let hideWeights = LocalizedStringResource("dashboard.hideWeights", defaultValue: "Hide dashboard weights", table: "Insights")
        static let privacyTitle = LocalizedStringResource("dashboard.privacyTitle", defaultValue: "Weights hidden", table: "Insights")
        static let privacyExplanation = LocalizedStringResource("dashboard.privacyExplanation", defaultValue: "Weight values and charts are hidden on this dashboard, including from VoiceOver. Other screens remain visible.", table: "Insights")
        static let visibleCards = LocalizedStringResource("dashboard.visibleCards", defaultValue: "Visible cards", table: "Insights")
        static let hiddenCards = LocalizedStringResource("dashboard.hiddenCards", defaultValue: "Hidden cards", table: "Insights")
        static let moveUp = LocalizedStringResource("dashboard.moveUp", defaultValue: "Move up", table: "Insights")
        static let moveDown = LocalizedStringResource("dashboard.moveDown", defaultValue: "Move down", table: "Insights")
        static let hideCard = LocalizedStringResource("dashboard.hideCard", defaultValue: "Hide card", table: "Insights")
        static let showCard = LocalizedStringResource("dashboard.showCard", defaultValue: "Show card", table: "Insights")
        static let restoreCards = LocalizedStringResource("dashboard.restoreCards", defaultValue: "Restore default cards", table: "Insights")
        static let noCards = LocalizedStringResource("dashboard.noCards", defaultValue: "All dashboard cards are hidden. Customize the dashboard to show them again.", table: "Insights")

        static func coverage(_ logged: Int, _ total: Int) -> LocalizedStringResource {
            LocalizedStringResource("recap.coverage", defaultValue: "Logging days: \(logged) of \(total)", table: "Insights")
        }
        static func samplePeriod(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("analytics.samplePeriod", defaultValue: "Logging-day samples: \(count)", table: "Insights")
        }
        static func supportCounts(_ logged: Int, _ span: Int) -> LocalizedStringResource {
            LocalizedStringResource("support.counts", defaultValue: "Logging days: \(logged); calendar days: \(span)", table: "Insights")
        }
        static func plateauMessage(_ days: Int) -> LocalizedStringResource {
            LocalizedStringResource("plateau.message", defaultValue: "Little overall change across \(days) calendar days.", table: "Insights")
        }
        static func weeklyRate(_ value: String) -> LocalizedStringResource {
            LocalizedStringResource("pace.weeklyRate", defaultValue: "\(value) per week", table: "Insights")
        }
        static func remainingDays(_ days: Int) -> LocalizedStringResource {
            LocalizedStringResource("pace.remaining", defaultValue: "Calendar days remaining: \(days)", table: "Insights")
        }
    }
}
