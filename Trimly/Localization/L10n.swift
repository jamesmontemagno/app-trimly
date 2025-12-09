import Foundation

enum L10n {
	enum Common {
		static let getStartedButton = LocalizedStringResource("common.button.getStarted", defaultValue: "Get Started")
		static let continueButton = LocalizedStringResource("common.button.continue", defaultValue: "Continue")
		static let skipButton = LocalizedStringResource("common.button.skip", defaultValue: "Skip for now")
		static let acceptButton = LocalizedStringResource("common.button.accept", defaultValue: "Accept & Continue")
		static let cancelButton = LocalizedStringResource("common.button.cancel", defaultValue: "Cancel")
		static let saveButton = LocalizedStringResource("common.button.save", defaultValue: "Save")
		static let doneButton = LocalizedStringResource("common.button.done", defaultValue: "Done")
		static let okButton = LocalizedStringResource("common.button.ok", defaultValue: "OK")
		static let deleteButton = LocalizedStringResource("common.button.delete", defaultValue: "Delete")
		static let refresh = LocalizedStringResource("common.button.refresh", defaultValue: "Refresh")
		static let addWeight = LocalizedStringResource("common.button.addWeight", defaultValue: "Add Weight")
		static let booleanYes = LocalizedStringResource("common.value.yes", defaultValue: "Yes")
		static let booleanNo = LocalizedStringResource("common.value.no", defaultValue: "No")
		static let errorTitle = LocalizedStringResource("common.alert.errorTitle", defaultValue: "Error")
		static let deleteAllDataTitle = LocalizedStringResource("common.alert.deleteAllDataTitle", defaultValue: "Delete All Data")
		static func days(_ count: Int) -> LocalizedStringResource {
			LocalizedStringResource("common.value.days", defaultValue: "\(count) days")
		}
	}

	enum Tabs {
		static let today = LocalizedStringResource("tabs.today", defaultValue: "Today")
		static let timeline = LocalizedStringResource("tabs.timeline", defaultValue: "Timeline")
		static let charts = LocalizedStringResource("tabs.charts", defaultValue: "Charts")
		static let achievements = LocalizedStringResource("tabs.achievements", defaultValue: "Achievements")
		static let settings = LocalizedStringResource("tabs.settings", defaultValue: "Settings")
	}

	enum AddEntry {
		static let navigationTitle = LocalizedStringResource("addEntry.navigation.title", defaultValue: "Add Weight")
		static let weightCardTitle = LocalizedStringResource("addEntry.card.weight.title", defaultValue: "Log Weight")
		static func weightDescription(_ unitSymbol: String) -> LocalizedStringResource {
			LocalizedStringResource("addEntry.card.weight.description", defaultValue: "Enter today's reading in \(unitSymbol).")
		}
		static let storageNote = LocalizedStringResource("addEntry.card.weight.storageNote", defaultValue: "Stored internally as kilograms so your analytics stay precise.")
		static let dateTitle = LocalizedStringResource("addEntry.card.date.title", defaultValue: "Date & Time")
		static let dateDescription = LocalizedStringResource("addEntry.card.date.description", defaultValue: "We normalize to your local day for charts.")
		static let notesTitle = LocalizedStringResource("addEntry.card.notes.title", defaultValue: "Notes")
		static let notesDescription = LocalizedStringResource("addEntry.card.notes.description", defaultValue: "Optional reflections or context.")
		static let notesPlaceholder = LocalizedStringResource("addEntry.card.notes.placeholder", defaultValue: "Morning weigh-in after run")
		static let weightPlaceholder = LocalizedStringResource("addEntry.input.weight.placeholder", defaultValue: "0.0")
		static let errorInvalidWeight = LocalizedStringResource("addEntry.error.invalidWeight", defaultValue: "Please enter a valid weight")
		static let errorNonPositiveWeight = LocalizedStringResource("addEntry.error.nonPositiveWeight", defaultValue: "Weight must be greater than zero")
		static let errorFutureDate = LocalizedStringResource("addEntry.error.futureDate", defaultValue: "Date cannot be in the future")
		static let errorMissingSettings = LocalizedStringResource("addEntry.error.missingSettings", defaultValue: "Settings not available")
		static func errorSaveFailure(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("addEntry.error.saveFailure", defaultValue: "Failed to save entry: \(message)")
		}
	}
	
	enum Onboarding {
		static let stepWelcome = LocalizedStringResource("onboarding.step.welcome", defaultValue: "Welcome")
		static let stepUnits = LocalizedStringResource("onboarding.step.units", defaultValue: "Units")
		static let stepStart = LocalizedStringResource("onboarding.step.start", defaultValue: "Start")
		static let stepGoal = LocalizedStringResource("onboarding.step.goal", defaultValue: "Goal")
		static let stepReminders = LocalizedStringResource("onboarding.step.reminders", defaultValue: "Reminders")
		static let stepCloudSync = LocalizedStringResource("onboarding.step.cloudSync", defaultValue: "iCloud Sync")
		static let stepFinish = LocalizedStringResource("onboarding.step.finish", defaultValue: "Finish")
		
		static let welcomeTitle = LocalizedStringResource("onboarding.welcome.title", defaultValue: "Welcome to TrimTally")
		static let welcomeSubtitle = LocalizedStringResource("onboarding.welcome.subtitle", defaultValue: "Your supportive companion for mindful weight tracking")
			static let cloudSyncChecking = LocalizedStringResource("onboarding.cloudSync.checking", defaultValue: "Looking for your previous TrimTally data...")
			static let cloudSyncStillChecking = LocalizedStringResource("onboarding.cloudSync.stillChecking", defaultValue: "Still checking iCloud—tap Get Started to continue manually.")
			static let cloudSyncFound = LocalizedStringResource("onboarding.cloudSync.found", defaultValue: "Found your history! Restoring it now...")
			static let cloudSyncNoData = LocalizedStringResource("onboarding.cloudSync.noData", defaultValue: "No TrimTally data found in iCloud yet—start fresh and we'll sync new entries.")
		
		static let unitTitle = LocalizedStringResource("onboarding.unit.title", defaultValue: "Choose Your Unit")
		static let unitSubtitle = LocalizedStringResource("onboarding.unit.subtitle", defaultValue: "Select your preferred weight unit")
		static let unitOptionPounds = LocalizedStringResource("onboarding.unit.option.pounds", defaultValue: "Pounds (lb)")
		static let unitOptionKilograms = LocalizedStringResource("onboarding.unit.option.kilograms", defaultValue: "Kilograms (kg)")
		static let unitPickerLabel = LocalizedStringResource("onboarding.unit.pickerLabel", defaultValue: "Preferred unit")
		
		static let startTitle = LocalizedStringResource("onboarding.start.title", defaultValue: "Starting Weight")
		static let startSubtitle = LocalizedStringResource("onboarding.start.subtitle", defaultValue: "What's your current weight?")
		static let startPlaceholder = LocalizedStringResource("onboarding.start.placeholder", defaultValue: "Weight")
		static let startFieldLabel = LocalizedStringResource("onboarding.start.fieldLabel", defaultValue: "Starting weight entry")
		static let startValidation = LocalizedStringResource("onboarding.start.error", defaultValue: "Enter a valid starting weight")
		
		static let goalTitle = LocalizedStringResource("onboarding.goal.title", defaultValue: "Set Your Goal")
		static let goalSubtitle = LocalizedStringResource("onboarding.goal.subtitle", defaultValue: "What's your target weight?")
		static let goalPlaceholder = LocalizedStringResource("onboarding.goal.placeholder", defaultValue: "Goal")
		static let goalFieldLabel = LocalizedStringResource("onboarding.goal.fieldLabel", defaultValue: "Goal weight entry")
		static let goalValidation = LocalizedStringResource("onboarding.goal.error", defaultValue: "Enter a valid target weight")
		static let goalNeedsStart = LocalizedStringResource("onboarding.goal.missingStart", defaultValue: "Enter your starting weight before setting a goal")
		
		static let remindersTitle = LocalizedStringResource("onboarding.reminder.title", defaultValue: "Daily Reminders")
		static let remindersSubtitle = LocalizedStringResource("onboarding.reminder.subtitle", defaultValue: "Stay consistent with gentle reminders")
		static let reminderToggle = LocalizedStringResource("onboarding.reminder.toggle", defaultValue: "Enable Daily Reminder")
		static let reminderHint = LocalizedStringResource("onboarding.reminder.hint", defaultValue: "We'll remind you at 9:00 AM each day")
		
		static let iCloudSyncTitle = LocalizedStringResource("onboarding.iCloudSync.title", defaultValue: "iCloud Sync")
		static let iCloudSyncSubtitle = LocalizedStringResource("onboarding.iCloudSync.subtitle", defaultValue: "Keep your data in sync across all your devices")
		static let iCloudSyncToggle = LocalizedStringResource("onboarding.iCloudSync.toggle", defaultValue: "Enable iCloud Sync")
		static let iCloudSyncDescription = LocalizedStringResource("onboarding.iCloudSync.description", defaultValue: "Your weight data is securely encrypted and synced to your private iCloud account. Only your devices can access your data—Apple cannot read it.")
		static let iCloudSyncBenefit1 = LocalizedStringResource("onboarding.iCloudSync.benefit1", defaultValue: "Automatic backup and restore")
		static let iCloudSyncBenefit2 = LocalizedStringResource("onboarding.iCloudSync.benefit2", defaultValue: "Sync across iPhone, iPad, and Mac")
		static let iCloudSyncBenefit3 = LocalizedStringResource("onboarding.iCloudSync.benefit3", defaultValue: "End-to-end encrypted")
		
		static let eulaTitle = LocalizedStringResource("onboarding.eula.title", defaultValue: "Terms & Privacy")
		static let eulaSubtitle = LocalizedStringResource("onboarding.eula.subtitle", defaultValue: "By continuing, you agree to our Terms of Service and Privacy Policy")
		static let eulaTerms = LocalizedStringResource("onboarding.eula.terms", defaultValue: "Read Terms of Service")
		static let eulaPrivacy = LocalizedStringResource("onboarding.eula.privacy", defaultValue: "Read Privacy Policy")
		
		static let incompleteError = LocalizedStringResource("onboarding.error.incomplete", defaultValue: "Please enter your starting weight and goal weight before continuing.")
	}

	enum Charts {
		static let navigationTitle = LocalizedStringResource("charts.navigation.title", defaultValue: "Charts")
		static let rangePicker = LocalizedStringResource("charts.picker.range", defaultValue: "Range")
		static let rangeWeek = LocalizedStringResource("charts.range.week", defaultValue: "Week")
		static let rangeMonth = LocalizedStringResource("charts.range.month", defaultValue: "Month")
		static let rangeQuarter = LocalizedStringResource("charts.range.quarter", defaultValue: "Quarter")
		static let rangeYear = LocalizedStringResource("charts.range.year", defaultValue: "Year")
		static let noDataTitle = LocalizedStringResource("charts.empty.title", defaultValue: "No Data")
		static let noDataDescription = LocalizedStringResource("charts.empty.description", defaultValue: "Add weight entries to see your chart")
		static let legendWeight = LocalizedStringResource("charts.legend.weight", defaultValue: "Weight")
		static let legendMovingAverage = LocalizedStringResource("charts.legend.movingAverage", defaultValue: "MA")
		static let legendEMA = LocalizedStringResource("charts.legend.ema", defaultValue: "EMA")
		static let statMin = LocalizedStringResource("charts.stats.min", defaultValue: "Min")
		static let statMax = LocalizedStringResource("charts.stats.max", defaultValue: "Max")
		static let statAvg = LocalizedStringResource("charts.stats.avg", defaultValue: "Avg")
		static let statRange = LocalizedStringResource("charts.stats.range", defaultValue: "Range")
		static let goalLabel = LocalizedStringResource("charts.goal.label", defaultValue: "Goal")
		static let maInfoTitle = LocalizedStringResource("charts.info.ma.title", defaultValue: "Moving Average")
		static let maInfoDescription = LocalizedStringResource("charts.info.ma.description", defaultValue: "A simple moving average smooths recent entries by averaging the last few days so you can spot direction without noise.")
		static let emaInfoTitle = LocalizedStringResource("charts.info.ema.title", defaultValue: "Exponential Moving Average")
		static let emaInfoDescription = LocalizedStringResource("charts.info.ema.description", defaultValue: "An exponential moving average reacts faster by giving more weight to your latest readings while still smoothing swings.")
		static let legendInfoHint = LocalizedStringResource("charts.legend.info.hint", defaultValue: "Opens a short description of this overlay")
			static let selectionTitle = LocalizedStringResource("charts.selection.title", defaultValue: "Selected Entry")
			static let selectionHint = LocalizedStringResource("charts.selection.hint", defaultValue: "Tap a point to see the exact weight.")
			static let tapToShowDotsHint = LocalizedStringResource("charts.tap.showDots.hint", defaultValue: "Tap the chart to show data points.")
		static let settingsButton = LocalizedStringResource("charts.button.settings", defaultValue: "Chart Settings")
	}

	enum ChartSettings {
		static let navigationTitle = LocalizedStringResource("chartSettings.navigation.title", defaultValue: "Chart Settings")
		static let displayModeTitle = LocalizedStringResource("chartSettings.display.title", defaultValue: "Display Mode")
		static let displayModeDescription = LocalizedStringResource("chartSettings.display.description", defaultValue: "Choose how much chart chrome you want to see.")
		static let displayMinimalist = LocalizedStringResource("chartSettings.display.minimalist", defaultValue: "Minimalist")
		static let displayAnalytical = LocalizedStringResource("chartSettings.display.analytical", defaultValue: "Analytical")
		static let trendLayersTitle = LocalizedStringResource("chartSettings.trend.title", defaultValue: "Trend Layers")
		static let trendLayersDescription = LocalizedStringResource("chartSettings.trend.description", defaultValue: "Overlay smoothed lines to better see direction without noise.")
		static let movingAverageToggle = LocalizedStringResource("chartSettings.trend.toggle.ma", defaultValue: "Show Moving Average")
		static let movingAverageInfo = LocalizedStringResource("chartSettings.trend.info.ma", defaultValue: "A simple moving average smooths recent entries by averaging the last few days.")
		static let movingAverageLabel = LocalizedStringResource("chartSettings.trend.label.ma", defaultValue: "Moving Average")
		static let emaToggle = LocalizedStringResource("chartSettings.trend.toggle.ema", defaultValue: "Show EMA")
		static let emaInfo = LocalizedStringResource("chartSettings.trend.info.ema", defaultValue: "An exponential moving average reacts faster by weighting recent entries more heavily.")
		static let emaLabel = LocalizedStringResource("chartSettings.trend.label.ema", defaultValue: "Exponential Moving Average")
		static func daysLabel(_ days: Int) -> LocalizedStringResource {
			LocalizedStringResource("chartSettings.trend.days", defaultValue: "\(days) days")
		}
		static let overlaysHint = LocalizedStringResource("chartSettings.trend.hint", defaultValue: "Both overlays respect your date filter so weekly views stay clean.")
	}

	enum Dashboard {
		static let navigationTitle = LocalizedStringResource("dashboard.navigation.title", defaultValue: "Today")
		static let currentWeight = LocalizedStringResource("dashboard.currentWeight", defaultValue: "Current Weight")
		static let noEntries = LocalizedStringResource("dashboard.noEntries", defaultValue: "No entries yet")
		static let placeholder = LocalizedStringResource("dashboard.placeholder", defaultValue: "--")
		static func latestEntry(_ time: String) -> LocalizedStringResource {
			LocalizedStringResource("dashboard.latestEntry", defaultValue: "Latest: \(time)")
		}
		static func averageEntries(_ count: Int) -> LocalizedStringResource {
			LocalizedStringResource("dashboard.averageEntries", defaultValue: "Average of \(count) entries")
		}
		static let lastSevenDays = LocalizedStringResource("dashboard.lastSevenDays", defaultValue: "Last 7 Days")
		static let notEnoughData = LocalizedStringResource("dashboard.notEnoughData", defaultValue: "Not enough data")
		static let fromStart = LocalizedStringResource("dashboard.fromStart", defaultValue: "From Start")
		static let toGoal = LocalizedStringResource("dashboard.toGoal", defaultValue: "To Goal")
		static let progress = LocalizedStringResource("dashboard.progress", defaultValue: "Progress")
		static let setGoalPrompt = LocalizedStringResource("dashboard.setGoalPrompt", defaultValue: "Set a goal to track progress")
		static func progressMetaStart(_ value: String) -> LocalizedStringResource {
			LocalizedStringResource("dashboard.progress.meta.start", defaultValue: "Start weight: \(value)")
		}
		static func progressMetaTarget(_ value: String) -> LocalizedStringResource {
			LocalizedStringResource("dashboard.progress.meta.target", defaultValue: "Target weight: \(value)")
		}
		static func progressMetaStartDate(_ value: String) -> LocalizedStringResource {
			LocalizedStringResource("dashboard.progress.meta.startDate", defaultValue: "Start date: \(value)")
		}
		static func progressMetaCheckIns(_ count: Int) -> LocalizedStringResource {
			LocalizedStringResource("dashboard.progress.meta.checkIns", defaultValue: "Check-ins: \(count)")
		}
		static let progressMetaSeparator = LocalizedStringResource("dashboard.progress.meta.separator", defaultValue: "|")
		static let consistencyScore = LocalizedStringResource("dashboard.consistencyScore", defaultValue: "Consistency Score")
		static let consistencyVery = LocalizedStringResource("dashboard.consistency.very", defaultValue: "Very consistent")
		static let consistencyConsistent = LocalizedStringResource("dashboard.consistency.consistent", defaultValue: "Consistent")
		static let consistencyModerate = LocalizedStringResource("dashboard.consistency.moderate", defaultValue: "Moderate")
		static let consistencyBuilding = LocalizedStringResource("dashboard.consistency.building", defaultValue: "Building consistency")
		static let trendTitle = LocalizedStringResource("dashboard.trend.title", defaultValue: "Trend")
		static let estimatedGoalDate = LocalizedStringResource("dashboard.estimatedGoalDate", defaultValue: "Estimated Goal Date")
		static func goalArrival(_ days: Int) -> LocalizedStringResource {
			LocalizedStringResource("dashboard.goal.arrival", defaultValue: "in \(days) days")
		}
		static let plateauDetected = LocalizedStringResource("dashboard.plateauDetected", defaultValue: "Plateau Detected")
		static let syncedToHealthKit = LocalizedStringResource("dashboard.syncedToHealthKit", defaultValue: "Also saved to Health")
		static let syncedFromICloud = LocalizedStringResource("dashboard.syncedFromICloud", defaultValue: "Synced your history from iCloud")
		static let icloudSyncLoading = LocalizedStringResource("dashboard.icloudSyncLoading", defaultValue: "Loading your history from iCloud...")
		static let monthlyCalendar = LocalizedStringResource("dashboard.monthlyCalendar", defaultValue: "This Month")
	}

	enum Reminders {
		static let navigationTitle = LocalizedStringResource("reminders.navigation.title", defaultValue: "Reminders")
		static let authorizationTitle = LocalizedStringResource("reminders.authorization.title", defaultValue: "Authorization")
		static let notificationsEnabled = LocalizedStringResource("reminders.authorization.enabled", defaultValue: "Notifications Enabled")
		static let authorizedDescription = LocalizedStringResource("reminders.authorization.description", defaultValue: "TrimTally can send you reminders on this device.")
		static let enablePrompt = LocalizedStringResource("reminders.authorization.prompt", defaultValue: "Stay on track with gentle nudges. Enable notifications so we can remind you when it counts.")
		static let grantAccess = LocalizedStringResource("reminders.authorization.grant", defaultValue: "Grant Access")
		static let dailyTitle = LocalizedStringResource("reminders.daily.title", defaultValue: "Daily Reminder")
		static let dailyDescription = LocalizedStringResource("reminders.daily.description", defaultValue: "Choose the best time for TrimTally to nudge you to log your weight.")
		static let dailyToggle = LocalizedStringResource("reminders.daily.toggle", defaultValue: "Enable Daily Reminder")
		static let reminderTimeLabel = LocalizedStringResource("reminders.daily.timeLabel", defaultValue: "Reminder Time")
		static let adaptiveTitle = LocalizedStringResource("reminders.adaptive.title", defaultValue: "Adaptive Suggestions")
		static let adaptiveDescription = LocalizedStringResource("reminders.adaptive.description", defaultValue: "Let TrimTally learn your habits and recommend smarter reminder times.")
		static let smartToggle = LocalizedStringResource("reminders.adaptive.toggle", defaultValue: "Smart Time Suggestions")
		static let suggestionTitle = LocalizedStringResource("reminders.adaptive.suggestion.title", defaultValue: "Suggested time")
		static let suggestionHint = LocalizedStringResource("reminders.adaptive.suggestion.hint", defaultValue: "Based on your recent logging")
		static let secondaryTitle = LocalizedStringResource("reminders.secondary.title", defaultValue: "Secondary Reminder")
		static let secondaryDescription = LocalizedStringResource("reminders.secondary.description", defaultValue: "Optional evening nudge for an extra check-in.")
		static let secondaryToggle = LocalizedStringResource("reminders.secondary.toggle", defaultValue: "Enable Evening Reminder")
		static let eveningLabel = LocalizedStringResource("reminders.secondary.timeLabel", defaultValue: "Evening Time")
	}

		enum Health {
			static let navigationTitle = LocalizedStringResource("health.navigation.title", defaultValue: "HealthKit Integration")
			static let authorizationTitle = LocalizedStringResource("health.authorization.title", defaultValue: "Authorization")
			static let authorizationDescription = LocalizedStringResource("health.authorization.description", defaultValue: "Allow TrimTally to securely read your Health app weight data.")
			static let statusEnabled = LocalizedStringResource("health.authorization.enabled", defaultValue: "HealthKit Enabled")
			static let statusEnabledDescription = LocalizedStringResource("health.authorization.enabledDescription", defaultValue: "You can now import history and sync future entries.")
			static let connectPrompt = LocalizedStringResource("health.authorization.prompt", defaultValue: "Connect to Health so TrimTally can keep everything in one place.")
		static let requestAccessButton = LocalizedStringResource("health.authorization.requestAccess", defaultValue: "Request Access")
		static let historicalImportTitle = LocalizedStringResource("health.import.title", defaultValue: "Historical Import")
			static let historicalImportDescription = LocalizedStringResource("health.import.description", defaultValue: "Choose a range and pull past weights into TrimTally. Duplicates are automatically skipped.")
		static let startDateLabel = LocalizedStringResource("health.import.startDate", defaultValue: "Start")
		static let endDateLabel = LocalizedStringResource("health.import.endDate", defaultValue: "End")
		static let countingSamples = LocalizedStringResource("health.import.counting", defaultValue: "Counting samples")
		static let samplesFoundLabel = LocalizedStringResource("health.import.samplesFound", defaultValue: "Samples Found")
		static let selectRangeHint = LocalizedStringResource("health.import.rangeHint", defaultValue: "Select a range to preview available entries.")
		static let importRecentButton = LocalizedStringResource("health.import.recent.button", defaultValue: "Import recent")
		static let importButton = LocalizedStringResource("health.import.button", defaultValue: "Import Data")
		static let importProgressTitle = LocalizedStringResource("health.import.progress.title", defaultValue: "Import Progress")
		static func importProgressStatus(_ percent: Int) -> LocalizedStringResource {
			LocalizedStringResource("health.import.progress.status", defaultValue: "Importing... \(percent)%")
		}
		static let recentImportTitle = LocalizedStringResource("health.import.recent.title", defaultValue: "Recent Import")
		static func recentImportStatus(_ count: Int) -> LocalizedStringResource {
			LocalizedStringResource("health.import.recent.status", defaultValue: "\(count) samples imported")
		}
		static let recentImportHint = LocalizedStringResource("health.import.recent.hint", defaultValue: "You can rerun imports at any time—duplicates stay hidden.")
		static let importRecentExplainer = LocalizedStringResource("health.import.recent.explainer", defaultValue: "Imports the last 30 days or since your last import—no date picking required.")
		static let importDateRangeExplainer = LocalizedStringResource("health.import.range.explainer", defaultValue: "Uses the start/end dates above to pull your exact range.")
		static let backgroundSyncTitle = LocalizedStringResource("health.sync.title", defaultValue: "Background Sync")
			static let backgroundSyncDescription = LocalizedStringResource("health.sync.description", defaultValue: "Let TrimTally watch for new Health weight samples and keep things tidy.")
		static let backgroundSyncToggle = LocalizedStringResource("health.sync.toggle", defaultValue: "Enable Background Sync")
		static let autoHideToggle = LocalizedStringResource("health.sync.autoHide", defaultValue: "Auto-hide Duplicates")
		static let writeToHealthToggle = LocalizedStringResource("health.sync.writeToHealth", defaultValue: "Write new entries to Health")
		static let syncedEntriesLabel = LocalizedStringResource("health.summary.syncedEntries", defaultValue: "Entries from Health")
		static func syncedRangeDescription(_ start: String, _ end: String) -> LocalizedStringResource {
			LocalizedStringResource("health.summary.range", defaultValue: "From \(start) to \(end)")
		}
		static func lastManualImport(_ date: String) -> LocalizedStringResource {
			LocalizedStringResource("health.summary.lastImport", defaultValue: "Last manual import: \(date)")
		}
		static let syncDirectionTitle = LocalizedStringResource("health.syncDirection.title", defaultValue: "How sync works")
		static let syncDirectionDescription = LocalizedStringResource("health.syncDirection.description", defaultValue: "TrimTally can read your weight from Health, and optionally write new manual entries back.")
		static let syncDirectionRead = LocalizedStringResource("health.syncDirection.read", defaultValue: "Reads weight entries from the Health app.")
		static let syncDirectionWrite = LocalizedStringResource("health.syncDirection.write", defaultValue: "When enabled, writes new manual entries to Health.")
		static func lastBackgroundSync(_ date: String) -> LocalizedStringResource {
			LocalizedStringResource("health.sync.lastBackground", defaultValue: "Last background sync: \(date)")
		}
		static let genericErrorMessage = LocalizedStringResource("health.error.generic", defaultValue: "An error occurred")
		static func authorizationFailed(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("health.error.authorization", defaultValue: "Failed to authorize HealthKit: \(message)")
		}
		static func sampleCountFailed(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("health.error.sampleCount", defaultValue: "Failed to load sample count: \(message)")
		}
		static func importFailed(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("health.error.import", defaultValue: "Failed to import data: \(message)")
		}
		static let writeFailedHint = LocalizedStringResource("health.error.writeFailedHint", defaultValue: "Saved in TrimTally, but couldn't write to Health. Check Health permissions if you want syncing.")
	}

	enum Timeline {
		static let navigationTitle = LocalizedStringResource("timeline.navigation.title", defaultValue: "Timeline")
		static let emptyTitle = LocalizedStringResource("timeline.empty.title", defaultValue: "No Entries Yet")
		static let emptyDescription = LocalizedStringResource("timeline.empty.description", defaultValue: "Add your first weight entry to get started")
		static func dailyValue(_ value: String) -> LocalizedStringResource {
			LocalizedStringResource("timeline.daily.value", defaultValue: "Daily: \(value)")
		}
		static let healthKitLabel = LocalizedStringResource("timeline.entry.healthKit", defaultValue: "HealthKit")
		static let deleteErrorTitle = LocalizedStringResource("timeline.alert.deleteError.title", defaultValue: "Couldn't delete entry")
		static func deleteErrorMessage(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("timeline.alert.deleteError.message", defaultValue: "We couldn't delete this entry: \(message)")
		}
		static let deleteErrorFallback = LocalizedStringResource("timeline.alert.deleteError.fallback", defaultValue: "Please try again.")
		static let lastEntryTitle = LocalizedStringResource("timeline.alert.lastEntry.title", defaultValue: "Keep at least one entry")
		static let lastEntryMessage = LocalizedStringResource("timeline.alert.lastEntry.message", defaultValue: "You need at least one weight entry. To start over, open Settings and choose Delete All Data.")
	}

	enum Settings {
		static let navigationTitle = LocalizedStringResource("settings.navigation.title", defaultValue: "Settings")
		static let personalizationTitle = LocalizedStringResource("settings.section.personalization.title", defaultValue: "Personalization")
		static let personalizationDescription = LocalizedStringResource("settings.section.personalization.description", defaultValue: "Fine-tune how TrimTally displays your weight, decimals, and appearance.")
		static let weightUnitTitle = LocalizedStringResource("settings.personalization.weightUnit.title", defaultValue: "Weight Unit")
		static let weightUnitSubtitle = LocalizedStringResource("settings.personalization.weightUnit.subtitle", defaultValue: "Display entries in your preferred unit.")
		static let decimalPrecisionTitle = LocalizedStringResource("settings.personalization.decimal.title", defaultValue: "Decimal Precision")
		static let decimalPrecisionSubtitle = LocalizedStringResource("settings.personalization.decimal.subtitle", defaultValue: "Control the number of decimal places you see.")
		static let decimalPrecisionOne = LocalizedStringResource("settings.personalization.decimal.one", defaultValue: "1 place")
		static let decimalPrecisionTwo = LocalizedStringResource("settings.personalization.decimal.two", defaultValue: "2 places")
		static let themeTitle = LocalizedStringResource("settings.personalization.theme.title", defaultValue: "Theme")
		static let themeSystem = LocalizedStringResource("settings.personalization.theme.option.system", defaultValue: "System")
		static let themeLight = LocalizedStringResource("settings.personalization.theme.option.light", defaultValue: "Light")
		static let themeDark = LocalizedStringResource("settings.personalization.theme.option.dark", defaultValue: "Dark")
		static let themeSubtitle = LocalizedStringResource("settings.personalization.theme.subtitle", defaultValue: "Choose TrimTally's appearance.")
		static let goalsTitle = LocalizedStringResource("settings.section.goals.title", defaultValue: "Goals")
		static let currentGoalTitle = LocalizedStringResource("settings.goals.current.title", defaultValue: "Current Goal")
		static func currentGoalSubtitle(_ target: String, _ start: String?) -> LocalizedStringResource {
			if let start {
				return LocalizedStringResource("settings.goals.current.subtitle", defaultValue: "Target: \(target) · Start: \(start)")
			} else {
				return LocalizedStringResource("settings.goals.current.subtitle.targetOnly", defaultValue: "Target: \(target)")
			}
		}
		static let goalHistoryTitle = LocalizedStringResource("settings.goals.history.title", defaultValue: "Goal History")
		static let goalHistorySubtitle = LocalizedStringResource("settings.goals.history.subtitle", defaultValue: "See past targets and outcomes.")
		static let setGoalTitle = LocalizedStringResource("settings.goals.set.title", defaultValue: "Set Goal")
		static let setGoalSubtitle = LocalizedStringResource("settings.goals.set.subtitle", defaultValue: "Track progress toward a target weight.")
		static let dailyValueTitle = LocalizedStringResource("settings.section.dailyValue.title", defaultValue: "Daily Value")
		static let dailyValueDescription = LocalizedStringResource("settings.section.dailyValue.description", defaultValue: "Choose how TrimTally treats multiple entries recorded in the same day.")
		static let dailyCalculationTitle = LocalizedStringResource("settings.dailyValue.calculation.title", defaultValue: "Daily Calculation")
		static let dailyCalculationSubtitle = LocalizedStringResource("settings.dailyValue.calculation.subtitle", defaultValue: "Latest entry or daily average.")
		static let dailyLatest = LocalizedStringResource("settings.dailyValue.option.latest", defaultValue: "Latest")
		static let dailyAverage = LocalizedStringResource("settings.dailyValue.option.average", defaultValue: "Average")
		static let habitsTitle = LocalizedStringResource("settings.section.habits.title", defaultValue: "Habits & Reminders")
		static let remindersSubtitleOn = LocalizedStringResource("settings.habits.reminders.subtitle.on", defaultValue: "Daily nudges to log your weight.")
		static let remindersSubtitleOff = LocalizedStringResource("settings.habits.reminders.subtitle.off", defaultValue: "Set a daily reminder to stay consistent.")
		static let remindersStatusOn = LocalizedStringResource("settings.habits.reminders.status.on", defaultValue: "On")
		static let remindersStatusOff = LocalizedStringResource("settings.habits.reminders.status.off", defaultValue: "Off")
		static let integrationsTitle = LocalizedStringResource("settings.section.integrations.title", defaultValue: "Integrations")
		static let healthTitle = LocalizedStringResource("settings.integrations.health.title", defaultValue: "Apple Health")
		static let healthSubtitle = LocalizedStringResource("settings.integrations.health.subtitle", defaultValue: "Import and sync weight data.")
		static let healthConnected = LocalizedStringResource("settings.integrations.health.connected", defaultValue: "Connected")

		static let dataPrivacyTitle = LocalizedStringResource("settings.section.dataPrivacy.title", defaultValue: "Data & Privacy")
		static let iCloudSyncTitle = LocalizedStringResource("settings.data.iCloudSync.title", defaultValue: "iCloud Sync")
		static let iCloudSyncSubtitle = LocalizedStringResource("settings.data.iCloudSync.subtitle", defaultValue: "Sync data across all your devices.")
		static let iCloudSyncEnabled = LocalizedStringResource("settings.data.iCloudSync.enabled", defaultValue: "On")
		static let iCloudSyncDisabled = LocalizedStringResource("settings.data.iCloudSync.disabled", defaultValue: "Off")
		static let iCloudSyncRestartTitle = LocalizedStringResource("settings.data.iCloudSync.restart.title", defaultValue: "Restart Required")
		static let iCloudSyncRestartMessage = LocalizedStringResource("settings.data.iCloudSync.restart.message", defaultValue: "Please restart TrimTally for this change to take effect. Your data is securely encrypted and only accessible from your devices.")
		static let exportTitle = LocalizedStringResource("settings.data.export.title", defaultValue: "Export Data")
		static let exportSubtitle = LocalizedStringResource("settings.data.export.subtitle", defaultValue: "Create a CSV copy of your entries.")
		static let deleteAllTitle = LocalizedStringResource("settings.data.delete.title", defaultValue: "Delete All Data")
		static let deleteAllSubtitle = LocalizedStringResource("settings.data.delete.subtitle", defaultValue: "Remove every entry from this device.")
		static let aboutTitle = LocalizedStringResource("settings.section.about.title", defaultValue: "About TrimTally")
		static let versionLabel = LocalizedStringResource("settings.about.version", defaultValue: "Version")
		static let privacyPolicy = LocalizedStringResource("settings.about.privacy", defaultValue: "Privacy Policy")
		static let termsOfService = LocalizedStringResource("settings.about.terms", defaultValue: "Terms of Service")
		static let deleteWarning = LocalizedStringResource("settings.data.delete.warning", defaultValue: "This will permanently delete all your weight entries and goals. This action cannot be undone.")
		static let restorePurchases = LocalizedStringResource("settings.about.restorePurchases", defaultValue: "Restore Purchases")
		static let restoreSuccessTitle = LocalizedStringResource("settings.restore.success.title", defaultValue: "Purchase Restored")
		static let restoreSuccessMessage = LocalizedStringResource("settings.restore.success.message", defaultValue: "Your TrimTally Pro purchase has been restored successfully.")
		static let restoreNotFoundTitle = LocalizedStringResource("settings.restore.notFound.title", defaultValue: "No Purchase Found")
		static let restoreNotFoundMessage = LocalizedStringResource("settings.restore.notFound.message", defaultValue: "We couldn't find a previous TrimTally Pro purchase associated with your account.")
		static let proStatus = LocalizedStringResource("settings.about.proStatus", defaultValue: "Pro")
		static let proDescription = LocalizedStringResource("settings.about.proDescription", defaultValue: "You have TrimTally Pro")
	}

	enum Goals {
		static let startTitle = LocalizedStringResource("goals.setup.start.title", defaultValue: "Starting Weight")
		static func startDescription(_ unitSymbol: String) -> LocalizedStringResource {
			LocalizedStringResource("goals.setup.start.description", defaultValue: "Set your baseline in \(unitSymbol).")
		}
		static let startPlaceholder = LocalizedStringResource("goals.setup.start.placeholder", defaultValue: "150")
		static let setupTitle = LocalizedStringResource("goals.setup.title", defaultValue: "Set Goal")
		static let targetTitle = LocalizedStringResource("goals.setup.target.title", defaultValue: "Target Weight")
		static func targetDescription(_ unitSymbol: String) -> LocalizedStringResource {
			LocalizedStringResource("goals.setup.target.description", defaultValue: "Enter a value in \(unitSymbol).")
		}
		static let targetPlaceholder = LocalizedStringResource("goals.setup.target.placeholder", defaultValue: "145")
		static let notesTitle = LocalizedStringResource("goals.setup.notes.title", defaultValue: "Notes")
		static let notesDescription = LocalizedStringResource("goals.setup.notes.description", defaultValue: "Optional context you'll revisit later.")
		static let notesPlaceholder = LocalizedStringResource("goals.setup.notes.placeholder", defaultValue: "Why this goal matters")
		static let unitHint = LocalizedStringResource("goals.setup.unitHint", defaultValue: "We use your preferred units and precision settings to track progress and estimate timelines.")
		static let actionsTitle = LocalizedStringResource("goals.actions.title", defaultValue: "Goal Options")
		static let actionEditCurrent = LocalizedStringResource("goals.actions.editCurrent", defaultValue: "Edit Current Goal")
		static let actionStartNew = LocalizedStringResource("goals.actions.startNew", defaultValue: "Start New Goal")
		static let historyTitle = LocalizedStringResource("goals.history.title", defaultValue: "Goal History")
		static func setOn(_ date: String) -> LocalizedStringResource {
			LocalizedStringResource("goals.history.setOn", defaultValue: "Set on \(date)")
		}
		static func completedOn(_ date: String) -> LocalizedStringResource {
			LocalizedStringResource("goals.history.completedOn", defaultValue: "Completed on \(date)")
		}
		static let noHistoryTitle = LocalizedStringResource("goals.history.empty.title", defaultValue: "No Goal History")
		static let noHistoryDescription = LocalizedStringResource("goals.history.empty.description", defaultValue: "Past goals will appear here")
		static let completionAchieved = LocalizedStringResource("goals.history.completion.achieved", defaultValue: "Achieved")
		static let completionChanged = LocalizedStringResource("goals.history.completion.changed", defaultValue: "Changed")
		static let completionAbandoned = LocalizedStringResource("goals.history.completion.abandoned", defaultValue: "Abandoned")
		static let errorNoActiveGoal = LocalizedStringResource("goals.error.noActiveGoal", defaultValue: "No active goal found")
		static let errorInvalidWeight = LocalizedStringResource("goals.setup.error.invalidWeight", defaultValue: "Please enter a valid weight")
		static let errorNonPositiveWeight = LocalizedStringResource("goals.setup.error.nonPositiveWeight", defaultValue: "Weight must be greater than zero")
		static let errorMissingSettings = LocalizedStringResource("goals.setup.error.missingSettings", defaultValue: "Settings not available")
		static let errorMissingStartingWeight = LocalizedStringResource("goals.setup.error.missingStartingWeight", defaultValue: "Enter a valid starting weight before saving")
		static func errorSaveFailure(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("goals.setup.error.saveFailure", defaultValue: "Failed to save goal: \(message)")
		}
	}

	enum Export {
		static let navigationTitle = LocalizedStringResource("export.navigation.title", defaultValue: "Export Data")
		static let hint = LocalizedStringResource("export.hint", defaultValue: "Copy or share your data export. Each row includes a timestamp, normalized date, and weight in kilograms.")
		static let emptyTitle = LocalizedStringResource("export.empty.title", defaultValue: "No data to export")
		static let emptyDescription = LocalizedStringResource("export.empty.description", defaultValue: "Add at least one weight entry, then try exporting again.")
	}

	enum Plateau {
		static func message(_ days: Int) -> LocalizedStringResource {
			LocalizedStringResource("plateau.message", defaultValue: "Weight stabilized for \(days) days—consider adjusting your routine if needed")
		}
		static let hintStable = LocalizedStringResource("plateau.hint.stable", defaultValue: "Your weight has remained stable. This is normal—bodies adapt. Consider reviewing your goals or routine.")
		static let hintFluctuation = LocalizedStringResource("plateau.hint.fluctuation", defaultValue: "Small fluctuations are normal. Keep up your consistent logging!")
	}

	enum Analytics {
		static let trendDecrease = LocalizedStringResource("analytics.trend.decrease", defaultValue: "Gradual decrease")
		static let trendIncrease = LocalizedStringResource("analytics.trend.increase", defaultValue: "Slight gain trend")
		static let trendStable = LocalizedStringResource("analytics.trend.stable", defaultValue: "Steady")
	}

		enum Achievements {
			static let navigationTitle = LocalizedStringResource("achievements.navigation.title", defaultValue: "Achievements")
			static let proBadge = LocalizedStringResource("achievements.pro.badge", defaultValue: "Pro")
			static let lockedBadge = LocalizedStringResource("achievements.locked.badge", defaultValue: "Locked")
			static let progressLabel = LocalizedStringResource("achievements.progress.label", defaultValue: "Progress")
			static let categoryLogging = LocalizedStringResource("achievements.category.logging", defaultValue: "Logging")
			static let categoryStreaks = LocalizedStringResource("achievements.category.streaks", defaultValue: "Streaks")
			static let categoryHabits = LocalizedStringResource("achievements.category.habits", defaultValue: "Habits")
			static let categoryGoals = LocalizedStringResource("achievements.category.goals", defaultValue: "Goals")
			static let categoryHealth = LocalizedStringResource("achievements.category.health", defaultValue: "Health")
			static let sectionPremiumHint = LocalizedStringResource("achievements.section.premiumHint", defaultValue: "Upgrade to TrimTally Pro to unlock premium achievements.")
			static let proUnlockLine = LocalizedStringResource("achievements.pro.unlockLine", defaultValue: "Unlock this achievement with TrimTally Pro.")
			static let loggingNewcomerTitle = LocalizedStringResource("achievements.logging.newcomer.title", defaultValue: "First Steps")
			static let loggingNewcomerDetail = LocalizedStringResource("achievements.logging.newcomer.detail", defaultValue: "Log 10 weight entries")
			static let loggingRegularTitle = LocalizedStringResource("achievements.logging.regular.title", defaultValue: "Routine Recorder")
			static let loggingRegularDetail = LocalizedStringResource("achievements.logging.regular.detail", defaultValue: "Log 50 weight entries")
			static let loggingLedgerTitle = LocalizedStringResource("achievements.logging.ledger.title", defaultValue: "Data Devotee")
			static let loggingLedgerDetail = LocalizedStringResource("achievements.logging.ledger.detail", defaultValue: "Log 365 weight entries")
			static let streakWeekTitle = LocalizedStringResource("achievements.streak.week.title", defaultValue: "One-Week Streak")
			static let streakWeekDetail = LocalizedStringResource("achievements.streak.week.detail", defaultValue: "Log 7 days in a row")
			static let streakMonthTitle = LocalizedStringResource("achievements.streak.month.title", defaultValue: "Momentum Builder")
			static let streakMonthDetail = LocalizedStringResource("achievements.streak.month.detail", defaultValue: "Log 30 days in a row")
			static let streakQuarterTitle = LocalizedStringResource("achievements.streak.quarter.title", defaultValue: "Unstoppable Quarter")
			static let streakQuarterDetail = LocalizedStringResource("achievements.streak.quarter.detail", defaultValue: "Log 90 days in a row")
			static let habitsMonthTitle = LocalizedStringResource("achievements.habits.month.title", defaultValue: "Month of Mindfulness")
			static let habitsMonthDetail = LocalizedStringResource("achievements.habits.month.detail", defaultValue: "Log on 30 unique days")
			static let habitsSeasonTitle = LocalizedStringResource("achievements.habits.season.title", defaultValue: "Season of Focus")
			static let habitsSeasonDetail = LocalizedStringResource("achievements.habits.season.detail", defaultValue: "Log on 90 unique days")
			static let habitsYearTitle = LocalizedStringResource("achievements.habits.year.title", defaultValue: "Year of You")
			static let habitsYearDetail = LocalizedStringResource("achievements.habits.year.detail", defaultValue: "Log on 365 unique days")
			static let consistencySolidTitle = LocalizedStringResource("achievements.consistency.solid.title", defaultValue: "Habit Builder")
			static let consistencySolidDetail = LocalizedStringResource("achievements.consistency.solid.detail", defaultValue: "Reach a 70% consistency score")
			static let consistencyExcellentTitle = LocalizedStringResource("achievements.consistency.excellent.title", defaultValue: "Consistency Icon")
			static let consistencyExcellentDetail = LocalizedStringResource("achievements.consistency.excellent.detail", defaultValue: "Reach a 90% consistency score")
			static let goalFirstTitle = LocalizedStringResource("achievements.goal.first.title", defaultValue: "Goal Finisher")
			static let goalFirstDetail = LocalizedStringResource("achievements.goal.first.detail", defaultValue: "Complete your first goal")
			static let goalTripleTitle = LocalizedStringResource("achievements.goal.triple.title", defaultValue: "Goal Hat Trick")
			static let goalTripleDetail = LocalizedStringResource("achievements.goal.triple.detail", defaultValue: "Complete three goals")
			static let goalMajorTitle = LocalizedStringResource("achievements.goal.major.title", defaultValue: "Goal Grandmaster")
			static let goalMajorDetail = LocalizedStringResource("achievements.goal.major.detail", defaultValue: "Complete five goals")
			static let remindersEnabledTitle = LocalizedStringResource("achievements.reminders.enabled.title", defaultValue: "Gentle Nudges")
			static let remindersEnabledDetail = LocalizedStringResource("achievements.reminders.enabled.detail", defaultValue: "Enable reminders")
			static let remindersRoutineTitle = LocalizedStringResource("achievements.reminders.routine.title", defaultValue: "Routine Keeper")
			static let remindersRoutineDetail = LocalizedStringResource("achievements.reminders.routine.detail", defaultValue: "Log on 85% of the last 21 days")
			static func celebrationUnlocked(_ title: String) -> LocalizedStringResource {
				LocalizedStringResource("achievements.celebration.unlocked", defaultValue: "\(title) unlocked!")
			}
			// Progress detail strings for achievement cards
			static func progressEntries(_ current: Int, _ target: Int) -> LocalizedStringResource {
				LocalizedStringResource("achievements.progress.entries", defaultValue: "\(current) of \(target) entries logged")
			}
			static func progressUniqueDays(_ current: Int, _ target: Int) -> LocalizedStringResource {
				LocalizedStringResource("achievements.progress.uniqueDays", defaultValue: "\(current) of \(target) unique days")
			}
			static func progressStreakDays(_ current: Int, _ target: Int) -> LocalizedStringResource {
				LocalizedStringResource("achievements.progress.streakDays", defaultValue: "Best streak: \(current) of \(target) days")
			}
			static func progressConsistency(_ currentPercent: Int, _ targetPercent: Int) -> LocalizedStringResource {
				LocalizedStringResource("achievements.progress.consistency", defaultValue: "Current: \(currentPercent)% of \(targetPercent)% needed")
			}
			static func progressConsistencyWithDays(_ currentPercent: Int, _ targetPercent: Int, _ currentDays: Int, _ requiredDays: Int) -> LocalizedStringResource {
				LocalizedStringResource("achievements.progress.consistencyWithDays", defaultValue: "\(currentPercent)% score · \(currentDays)/\(requiredDays) days needed to unlock")
			}
			static func progressGoals(_ current: Int, _ target: Int) -> LocalizedStringResource {
				LocalizedStringResource("achievements.progress.goals", defaultValue: "\(current) of \(target) goals achieved")
			}
			static let progressRemindersOn = LocalizedStringResource("achievements.progress.reminders.on", defaultValue: "Reminders enabled ✓")
			static let progressRemindersOff = LocalizedStringResource("achievements.progress.reminders.off", defaultValue: "Enable reminders in Settings to unlock")
			static func progressReminderConsistency(_ currentPercent: Int, _ targetPercent: Int) -> LocalizedStringResource {
				LocalizedStringResource("achievements.progress.reminderConsistency", defaultValue: "Logged \(currentPercent)% of last 21 days (\(targetPercent)% needed)")
			}
		}

	enum Celebrations {
		static let streak7 = LocalizedStringResource("celebrations.streak.7", defaultValue: "Nice streak forming—7 days of consistency!")
		static let streak30 = LocalizedStringResource("celebrations.streak.30", defaultValue: "30-day streak—phenomenal commitment!")
		static let entries10 = LocalizedStringResource("celebrations.entries.10", defaultValue: "Great progress—10 entries logged!")
		static let entries25 = LocalizedStringResource("celebrations.entries.25", defaultValue: "25 entries logged—momentum building!")
		static let entries50 = LocalizedStringResource("celebrations.entries.50", defaultValue: "50 entries logged—you're unstoppable!")
		static let entries100 = LocalizedStringResource("celebrations.entries.100", defaultValue: "100 entries logged—the century club!")
		static let goal25 = LocalizedStringResource("celebrations.goal.25", defaultValue: "Quarter way there—steady progress!")
		static let goal50 = LocalizedStringResource("celebrations.goal.50", defaultValue: "Halfway to your goal—keep it up!")
		static let goal75 = LocalizedStringResource("celebrations.goal.75", defaultValue: "Three quarters there—you're doing great!")
		static let goal100 = LocalizedStringResource("celebrations.goal.100", defaultValue: "Goal achieved—congratulations!")
			static let goalAchieved = LocalizedStringResource("celebrations.goal.achieved", defaultValue: "Goal reached—phenomenal effort!")
		static let consistency70 = LocalizedStringResource("celebrations.consistency.70", defaultValue: "70% consistency—building a solid habit!")
		static let consistency85 = LocalizedStringResource("celebrations.consistency.85", defaultValue: "85% consistency—excellent dedication!")
		static let consistencyPercentTemplate = LocalizedStringResource("celebrations.consistency.percent", defaultValue: "Consistency at %d%% — keep it going!")
	}

	enum Notifications {
		static let primaryTitle = LocalizedStringResource("notifications.primary.title", defaultValue: "Time to log your weight")
		static let primaryBody = LocalizedStringResource("notifications.primary.body", defaultValue: "Keep your streak going! Log today's weight.")
		static let secondaryTitle = LocalizedStringResource("notifications.secondary.title", defaultValue: "Evening check-in")
		static let secondaryBody = LocalizedStringResource("notifications.secondary.body", defaultValue: "Don't forget to log your weight for today.")
		static let actionQuickLog = LocalizedStringResource("notifications.action.quickLog", defaultValue: "Log Weight")
		static let actionDismiss = LocalizedStringResource("notifications.action.dismiss", defaultValue: "Dismiss")
		static let errorNotAuthorized = LocalizedStringResource("notifications.error.notAuthorized", defaultValue: "Notification permission not granted")
		static func schedulingFailed(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("notifications.error.schedulingFailed", defaultValue: "Failed to schedule notification: \(message)")
		}
	}

	enum Debug {
		static let toolsTitle = LocalizedStringResource("debug.tools.title", defaultValue: "Debug Utilities")
		static let toolsDescription = LocalizedStringResource("debug.tools.description", defaultValue: "Only available in development builds. Quickly populate your charts with mock data.")
		static let sampleDataTitle = LocalizedStringResource("debug.sampleData.title", defaultValue: "Generate Sample Data")
		static let sampleDataSubtitle = LocalizedStringResource("debug.sampleData.subtitle", defaultValue: "Replace existing entries with realistic test weights.")
		static let sampleDataAction = LocalizedStringResource("debug.sampleData.action", defaultValue: "Generate")
		static let sampleDataSuccess = LocalizedStringResource("debug.sampleData.success", defaultValue: "Sample data generated.")
		static func sampleDataFailure(_ message: String) -> LocalizedStringResource {
			LocalizedStringResource("debug.sampleData.failure", defaultValue: "Couldn't generate sample data: \(message)")
		}

		enum Achievements {
			static let sheetTitle = LocalizedStringResource("debug.achievements.sheet.title", defaultValue: "Achievement Diagnostics")
			static let metricSection = LocalizedStringResource("debug.achievements.section.metric", defaultValue: "Metric Inputs")
			static let contextSection = LocalizedStringResource("debug.achievements.section.context", defaultValue: "Evaluation Context")
			static let unlockStatus = LocalizedStringResource("debug.achievements.unlock.status", defaultValue: "Unlock status")
			static let requiresPro = LocalizedStringResource("debug.achievements.requiresPro", defaultValue: "Requires TrimTally Pro")
			static let totalEntries = LocalizedStringResource("debug.achievements.totalEntries", defaultValue: "Visible entries")
			static let uniqueDays = LocalizedStringResource("debug.achievements.uniqueDays", defaultValue: "Unique days logged")
			static let longestStreak = LocalizedStringResource("debug.achievements.longestStreak", defaultValue: "Longest streak")
			static let consistencyScore = LocalizedStringResource("debug.achievements.consistencyScore", defaultValue: "Consistency score")

			static let goalsAchieved = LocalizedStringResource("debug.achievements.goalsAchieved", defaultValue: "Goals achieved")
			static let remindersEnabled = LocalizedStringResource("debug.achievements.remindersEnabled", defaultValue: "Reminders enabled")
			static let reminderRatio = LocalizedStringResource("debug.achievements.reminderRatio", defaultValue: "Reminder completion (21 days)")
			static let evaluatedAt = LocalizedStringResource("debug.achievements.evaluatedAt", defaultValue: "Evaluated")
			static let noDiagnostics = LocalizedStringResource("debug.achievements.noData", defaultValue: "No diagnostics captured yet.")
			static let targetValue = LocalizedStringResource("debug.achievements.target.value", defaultValue: "Target value")
			static let targetUniqueDays = LocalizedStringResource("debug.achievements.target.uniqueDays", defaultValue: "Target unique days")
			static let targetStreakDays = LocalizedStringResource("debug.achievements.target.streakDays", defaultValue: "Target streak days")
			static let consistencyThreshold = LocalizedStringResource("debug.achievements.target.consistency", defaultValue: "Consistency threshold")
			static let targetGoals = LocalizedStringResource("debug.achievements.target.goals", defaultValue: "Target goals")
			static let remindersRequired = LocalizedStringResource("debug.achievements.target.reminders", defaultValue: "Reminders required")
			static let reminderRatioTarget = LocalizedStringResource("debug.achievements.target.reminderRatio", defaultValue: "Reminder ratio goal")
		}
	}

}
