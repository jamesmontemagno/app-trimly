import Foundation

extension L10n {
    enum Portability {
        nonisolated static let allTime = LocalizedStringResource("range.allTime", defaultValue: "All time", table: "Portability")
        nonisolated static let dateRange = LocalizedStringResource("range.title", defaultValue: "Date range", table: "Portability")
        nonisolated static let startDate = LocalizedStringResource("range.start", defaultValue: "Start date", table: "Portability")
        nonisolated static let endDate = LocalizedStringResource("range.end", defaultValue: "End date", table: "Portability")
        nonisolated static let inclusiveDates = LocalizedStringResource("range.hint", defaultValue: "Includes the entire start and end dates in your current time zone.", table: "Portability")
        nonisolated static let invalidRange = LocalizedStringResource("range.invalid", defaultValue: "The end date must be on or after the start date.", table: "Portability")
        nonisolated static let includeNotes = LocalizedStringResource("export.notes", defaultValue: "Include notes", table: "Portability")
        nonisolated static let includeHidden = LocalizedStringResource("export.hidden", defaultValue: "Include hidden entries", table: "Portability")
        nonisolated static let exportPrivacy = LocalizedStringResource("export.privacy", defaultValue: "CSV files contain weight values even when privacy mode is on. Notes and hidden entries are excluded unless selected. Share only with people you trust.", table: "Portability")
        nonisolated static let createCSV = LocalizedStringResource("export.create", defaultValue: "Prepare CSV", table: "Portability")
        nonisolated static let saveCSV = LocalizedStringResource("export.save", defaultValue: "Save CSV file", table: "Portability")
        nonisolated static let shareFile = LocalizedStringResource("file.share", defaultValue: "Share saved file", table: "Portability")
        nonisolated static let previewExcerpt = LocalizedStringResource("export.excerpt", defaultValue: "Preview shows the first 8 KB. The saved file includes every selected entry.", table: "Portability")
        nonisolated static let importTitle = LocalizedStringResource("import.title", defaultValue: "Import CSV", table: "Portability")
        nonisolated static let importSubtitle = LocalizedStringResource("import.subtitle", defaultValue: "Map columns and review every measurement before importing", table: "Portability")
        nonisolated static let chooseCSV = LocalizedStringResource("import.choose", defaultValue: "Choose CSV file", table: "Portability")
        nonisolated static let importExplanation = LocalizedStringResource("import.explanation", defaultValue: "Import UTF-8, comma-separated files up to 10 MB. This adds manual measurements, not a backup restore. HealthKit identity, hidden status, goals and settings are never restored from CSV.", table: "Portability")
        nonisolated static let hasHeader = LocalizedStringResource("import.header", defaultValue: "First row contains column names", table: "Portability")
        nonisolated static let dateColumn = LocalizedStringResource("import.dateColumn", defaultValue: "Date", table: "Portability")
        nonisolated static let weightColumn = LocalizedStringResource("import.weightColumn", defaultValue: "Weight", table: "Portability")
        nonisolated static let unitColumn = LocalizedStringResource("import.unitColumn", defaultValue: "Unit column", table: "Portability")
        nonisolated static let notesColumn = LocalizedStringResource("import.notesColumn", defaultValue: "Notes column", table: "Portability")
        nonisolated static let dateConvention = LocalizedStringResource("import.dateConvention", defaultValue: "Date convention", table: "Portability")
        nonisolated static let reviewImport = LocalizedStringResource("import.review", defaultValue: "Preview and review rows", table: "Portability")
        nonisolated static let columnMapping = LocalizedStringResource("import.mapping", defaultValue: "Column mapping", table: "Portability")
        nonisolated static let mappingHint = LocalizedStringResource("import.mappingHint", defaultValue: "Choose distinct date and weight columns. Units may be kg, lb or st. Without a unit column, the selected unit applies to every row. Dates without a time zone use your current time zone. Slash dates require two-digit days and months; optional time is 24-hour HH:mm or HH:mm:ss. Weight decimals use a period.", table: "Portability")
        nonisolated static let notMapped = LocalizedStringResource("import.notMapped", defaultValue: "Not mapped", table: "Portability")
        nonisolated static let importSelected = LocalizedStringResource("import.commit", defaultValue: "Import reviewed measurements", table: "Portability")
        nonisolated static let importReviewHint = LocalizedStringResource("import.reviewHint", defaultValue: "Invalid rows are not imported. Correct them in the original file and choose the file again. Existing measurements are never overwritten.", table: "Portability")
        nonisolated static let duplicateWarning = LocalizedStringResource("import.duplicate", defaultValue: "Possible duplicate — skipped by default", table: "Portability")
        nonisolated static let keepDuplicate = LocalizedStringResource("import.keep", defaultValue: "Keep as a separate measurement", table: "Portability")
        nonisolated static let ready = LocalizedStringResource("import.ready", defaultValue: "Ready to import", table: "Portability")
        nonisolated static let importPreview = LocalizedStringResource("import.preview", defaultValue: "Row preview", table: "Portability")
        nonisolated static let duplicateExplanation = LocalizedStringResource("import.duplicateExplanation", defaultValue: "A possible duplicate is within one second and 0.001 kg of an existing measurement (including hidden entries) or an earlier CSV row. Enable Keep only for rows you want to add separately; nothing is merged.", table: "Portability")
        nonisolated static let importComplete = LocalizedStringResource("import.complete", defaultValue: "Import complete", table: "Portability")
        nonisolated static let reportTitle = LocalizedStringResource("report.title", defaultValue: "Progress report", table: "Portability")
        nonisolated static let reportSubtitle = LocalizedStringResource("report.subtitle", defaultValue: "Preview and share a PDF chart and summary", table: "Portability")
        nonisolated static let includeGoal = LocalizedStringResource("report.includeGoal", defaultValue: "Include current goal", table: "Portability")
        nonisolated static let createReport = LocalizedStringResource("report.create", defaultValue: "Prepare report", table: "Portability")
        nonisolated static let reportPrivacy = LocalizedStringResource("report.privacy", defaultValue: "Reports include weight values even when privacy mode is on. Notes and hidden entries are always excluded. Preview your report before sharing.", table: "Portability")
        nonisolated static let noMeasurements = LocalizedStringResource("report.empty", defaultValue: "No visible measurements in this date range.", table: "Portability")
        nonisolated static let savePDF = LocalizedStringResource("report.save", defaultValue: "Save PDF report", table: "Portability")
        nonisolated static let previewPDF = LocalizedStringResource("report.preview", defaultValue: "Preview saved PDF", table: "Portability")
        nonisolated static let reportFailed = LocalizedStringResource("report.failed", defaultValue: "The PDF could not be created. Please try again.", table: "Portability")
        nonisolated static let goal = LocalizedStringResource("report.goal", defaultValue: "Current goal (dashed line)", table: "Portability")
        nonisolated static let reportChart = LocalizedStringResource("report.chart", defaultValue: "Daily weight progress chart", table: "Portability")
        nonisolated static let firstWeight = LocalizedStringResource("report.first", defaultValue: "First daily weight", table: "Portability")
        nonisolated static let latestWeight = LocalizedStringResource("report.latest", defaultValue: "Latest daily weight", table: "Portability")
        nonisolated static let change = LocalizedStringResource("report.change", defaultValue: "Change", table: "Portability")
        nonisolated static let dailyAverage = LocalizedStringResource("report.average", defaultValue: "Average of daily weights", table: "Portability")
        nonisolated static let reportLatest = LocalizedStringResource("report.mode.latest", defaultValue: "Uses the latest measurement on each logged day. Missing days are not filled in.", table: "Portability")
        nonisolated static let reportAverage = LocalizedStringResource("report.mode.average", defaultValue: "Uses the average measurement on each logged day. Missing days are not filled in.", table: "Portability")
        nonisolated static let shareCheckIn = LocalizedStringResource("share.title", defaultValue: "Share check-in", table: "Portability")
        nonisolated static let shareCheckInSubtitle = LocalizedStringResource("share.subtitle", defaultValue: "Create a privacy-conscious seven-day card", table: "Portability")
        nonisolated static let shareFormat = LocalizedStringResource("share.format", defaultValue: "Card format", table: "Portability")
        nonisolated static let shareCheckIns = LocalizedStringResource("share.format.checkins", defaultValue: "Check-ins", table: "Portability")
        nonisolated static let shareGoal = LocalizedStringResource("share.format.goal", defaultValue: "Goal progress", table: "Portability")
        nonisolated static let sharePrivacy = LocalizedStringResource("share.privacy", defaultValue: "Privacy", table: "Portability")
        nonisolated static let shareCheckInsOnly = LocalizedStringResource("share.privacy.checkins", defaultValue: "Check-ins only", table: "Portability")
        nonisolated static let shareTrend = LocalizedStringResource("share.privacy.trend", defaultValue: "Trend only", table: "Portability")
        nonisolated static let shareDetailed = LocalizedStringResource("share.privacy.detailed", defaultValue: "Detailed values", table: "Portability")
        nonisolated static let sharePortrait = LocalizedStringResource("share.portrait", defaultValue: "Portrait layout", table: "Portability")
        nonisolated static let shareDark = LocalizedStringResource("share.dark", defaultValue: "Dark appearance", table: "Portability")
        nonisolated static let shareFooter = LocalizedStringResource("share.footer", defaultValue: "Show TrimTally footer", table: "Portability")
        nonisolated static let shareWeightGraph = LocalizedStringResource("share.weightGraph", defaultValue: "Include weight graph", table: "Portability")
        nonisolated static let shareCurrentWeight = LocalizedStringResource("share.current", defaultValue: "Include current weight", table: "Portability")
        nonisolated static let shareChange = LocalizedStringResource("share.change", defaultValue: "Include period change", table: "Portability")
        nonisolated static let shareGoalValue = LocalizedStringResource("share.goalValue", defaultValue: "Include goal details", table: "Portability")
        nonisolated static let sharePrepare = LocalizedStringResource("share.prepare", defaultValue: "Prepare image", table: "Portability")
        nonisolated static let shareImage = LocalizedStringResource("share.image", defaultValue: "Share image", table: "Portability")
        nonisolated static let shareNoData = LocalizedStringResource("share.noData", defaultValue: "No visible weight data in this period.", table: "Portability")
        nonisolated static let sharePrivacyHint = LocalizedStringResource("share.privacyHint", defaultValue: "Check-ins only is the safest option. Recipients and the destination you choose control copies after sharing.", table: "Portability")
        nonisolated static let shareFailed = LocalizedStringResource("share.failed", defaultValue: "The share image could not be created. Please try again.", table: "Portability")
        nonisolated static let shareCheckedIn = LocalizedStringResource("share.checkedIn", defaultValue: "Checked in", table: "Portability")
        nonisolated static let shareNoCheckIn = LocalizedStringResource("share.noCheckIn", defaultValue: "No check-in", table: "Portability")
        nonisolated static let shareDayAxis = LocalizedStringResource("share.dayAxis", defaultValue: "Day", table: "Portability")
        nonisolated static let shareTrendAxis = LocalizedStringResource("share.trendAxis", defaultValue: "Trend", table: "Portability")
        nonisolated static let shareBrand = LocalizedStringResource("share.brand", defaultValue: "TrimTally", table: "Portability")
        nonisolated static let presentationTitle = LocalizedStringResource("presentation.title", defaultValue: "Dashboard & privacy", table: "Portability")
        nonisolated static let hideWeights = LocalizedStringResource("presentation.hideWeights", defaultValue: "Hide weight values", table: "Portability")
        nonisolated static let hideWeightsHint = LocalizedStringResource("presentation.hideHint", defaultValue: "Hide weight values in dashboard, history, charts and widgets on this device. Entry forms, goal settings and explicitly prepared exports still show weights. This is not an app lock.", table: "Portability")
        nonisolated static let privacy = LocalizedStringResource("presentation.privacy", defaultValue: "Privacy", table: "Portability")
        nonisolated static let deviceLocal = LocalizedStringResource("settings.deviceLocal", defaultValue: "These preferences apply only to this device and do not sync with iCloud.", table: "Portability")
        nonisolated static let visibleCards = LocalizedStringResource("presentation.visible", defaultValue: "Visible dashboard cards", table: "Portability")
        nonisolated static let hiddenCards = LocalizedStringResource("presentation.hidden", defaultValue: "Hidden dashboard cards", table: "Portability")
        nonisolated static let reorderHint = LocalizedStringResource("presentation.reorderHint", defaultValue: "Use the arrows or drag to reorder. Hiding a card never deletes your data.", table: "Portability")
        nonisolated static let resetCards = LocalizedStringResource("presentation.reset", defaultValue: "Restore all cards in default order", table: "Portability")
        nonisolated static let nextReminder = LocalizedStringResource("reminders.next", defaultValue: "Next scheduled reminder", table: "Portability")
        nonisolated static let noNextReminder = LocalizedStringResource("reminders.none", defaultValue: "No upcoming reminder is scheduled.", table: "Portability")
        nonisolated static let openNotificationSettings = LocalizedStringResource("reminders.openSettings", defaultValue: "Open notification settings", table: "Portability")
        nonisolated static let reminderScheduleFailed = LocalizedStringResource("reminders.failed", defaultValue: "A reminder could not be scheduled. Check notification permissions and try saving again.", table: "Portability")
        nonisolated static let notificationAuthorized = LocalizedStringResource("reminders.authorized", defaultValue: "Notifications allowed", table: "Portability")
        nonisolated static let notificationDenied = LocalizedStringResource("reminders.denied", defaultValue: "Notifications denied in system settings", table: "Portability")
        nonisolated static let notificationNotRequested = LocalizedStringResource("reminders.notRequested", defaultValue: "Notification permission not requested", table: "Portability")
        nonisolated static let notificationLimited = LocalizedStringResource("reminders.limited", defaultValue: "Limited notification permission", table: "Portability")
        nonisolated static let notificationUnknown = LocalizedStringResource("reminders.unknown", defaultValue: "Notification permission unavailable", table: "Portability")

        nonisolated static func entryCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("summary.entries", defaultValue: "Measurements: \(count)", table: "Portability")
        }
        nonisolated static func sevenDayCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("share.sevenDayCount", defaultValue: "\(count) of 7 days", table: "Portability")
        }
        nonisolated static func readyCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("import.readyCount", defaultValue: "Selected for import: \(count)", table: "Portability")
        }
        nonisolated static func invalidCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("import.invalidCount", defaultValue: "Invalid rows (not imported): \(count)", table: "Portability")
        }
        nonisolated static func importedCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("import.importedCount", defaultValue: "Manual measurements added: \(count)", table: "Portability")
        }
        nonisolated static func columnName(_ index: Int, _ name: String) -> LocalizedStringResource {
            LocalizedStringResource("import.columnName", defaultValue: "\(index): \(name)", table: "Portability")
        }
        nonisolated static func rowNumber(_ number: Int) -> LocalizedStringResource {
            LocalizedStringResource("import.rowNumber", defaultValue: "Line \(number)", table: "Portability")
        }
        nonisolated static func keepDuplicateRow(_ number: Int) -> LocalizedStringResource {
            LocalizedStringResource("import.keepRow", defaultValue: "Keep duplicate on line \(number) as a separate measurement", table: "Portability")
        }
        nonisolated static func loggedDays(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("report.loggedDays", defaultValue: "Days logged: \(count)", table: "Portability")
        }
        nonisolated static func reportDates(_ start: String, _ end: String) -> LocalizedStringResource {
            LocalizedStringResource("report.dates", defaultValue: "\(start) – \(end)", table: "Portability")
        }
        nonisolated static func dateConventionName(_ convention: WeightCSV.DateConvention) -> LocalizedStringResource {
            switch convention {
            case .iso8601: LocalizedStringResource("import.date.iso", defaultValue: "ISO 8601 / YYYY-MM-DD", table: "Portability")
            case .monthFirst: LocalizedStringResource("import.date.month", defaultValue: "Month first (MM/DD/YYYY)", table: "Portability")
            case .dayFirst: LocalizedStringResource("import.date.day", defaultValue: "Day first (DD/MM/YYYY)", table: "Portability")
            }
        }
        nonisolated static func csvIssue(_ issue: WeightCSV.Issue) -> LocalizedStringResource {
            switch issue {
            case .emptyFile: LocalizedStringResource("csv.error.empty", defaultValue: "The CSV file is empty.", table: "Portability")
            case .invalidEncoding: LocalizedStringResource("csv.error.encoding", defaultValue: "Save the CSV file as UTF-8 text and try again.", table: "Portability")
            case .tooLarge: LocalizedStringResource("csv.error.size", defaultValue: "Choose a CSV file smaller than 10 MB.", table: "Portability")
            case .malformedQuote: LocalizedStringResource("csv.error.quote", defaultValue: "Invalid quote escaping in this row.", table: "Portability")
            case .unclosedQuote: LocalizedStringResource("csv.error.unclosed", defaultValue: "A quoted field is not closed before the end of the file.", table: "Portability")
            case .invalidMapping: LocalizedStringResource("csv.error.mapping", defaultValue: "Select distinct, valid columns for each mapped field.", table: "Portability")
            case .columnCount: LocalizedStringResource("csv.error.columns", defaultValue: "This row has a different number of columns.", table: "Portability")
            case .invalidWeight: LocalizedStringResource("csv.error.weight", defaultValue: "Weight must be a finite number greater than zero.", table: "Portability")
            case .invalidDate: LocalizedStringResource("csv.error.date", defaultValue: "The date is invalid or does not match the selected convention.", table: "Portability")
            case .futureDate: LocalizedStringResource("csv.error.future", defaultValue: "Measurements cannot be dated in the future.", table: "Portability")
            case .invalidUnit: LocalizedStringResource("csv.error.unit", defaultValue: "Unrecognized unit. Use kg, lb or st.", table: "Portability")
            }
        }
        nonisolated static func cardTitle(_ card: DashboardCard) -> LocalizedStringResource {
            switch card {
            case .today: LocalizedStringResource("card.today", defaultValue: "Today", table: "Portability")
            case .progress: LocalizedStringResource("card.progress", defaultValue: "Goal progress", table: "Portability")
            case .sparkline: LocalizedStringResource("card.sparkline", defaultValue: "Recent weights", table: "Portability")
            case .consistency: LocalizedStringResource("card.consistency", defaultValue: "Consistency", table: "Portability")
            case .trend: LocalizedStringResource("card.trend", defaultValue: "Trend", table: "Portability")
            case .calendar: LocalizedStringResource("card.calendar", defaultValue: "Calendar", table: "Portability")
            case .plateau: LocalizedStringResource("card.plateau", defaultValue: "Plateau", table: "Portability")
            case .projection: LocalizedStringResource("card.projection", defaultValue: "Projection", table: "Portability")
            case .recap: LocalizedStringResource("card.recap", defaultValue: "Recap", table: "Portability")
            }
        }
        nonisolated static func moveUp(_ card: DashboardCard) -> LocalizedStringResource {
            LocalizedStringResource("card.moveUp", defaultValue: "Move \(String(localized: cardTitle(card))) up", table: "Portability")
        }
        nonisolated static func moveDown(_ card: DashboardCard) -> LocalizedStringResource {
            LocalizedStringResource("card.moveDown", defaultValue: "Move \(String(localized: cardTitle(card))) down", table: "Portability")
        }
        nonisolated static func hideCard(_ card: DashboardCard) -> LocalizedStringResource {
            LocalizedStringResource("card.hide", defaultValue: "Hide \(String(localized: cardTitle(card)))", table: "Portability")
        }
        nonisolated static func showCard(_ card: DashboardCard) -> LocalizedStringResource {
            LocalizedStringResource("card.show", defaultValue: "Show \(String(localized: cardTitle(card)))", table: "Portability")
        }
    }
}
