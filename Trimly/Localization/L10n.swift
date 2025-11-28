import SwiftUI

enum L10n {
	enum Common {
		static let getStartedButton = LocalizedStringResource("common.button.getStarted", defaultValue: "Get Started")
		static let continueButton = LocalizedStringResource("common.button.continue", defaultValue: "Continue")
		static let skipButton = LocalizedStringResource("common.button.skip", defaultValue: "Skip for now")
		static let acceptButton = LocalizedStringResource("common.button.accept", defaultValue: "Accept & Continue")
	}
	
	enum Onboarding {
		static let stepWelcome = LocalizedStringResource("onboarding.step.welcome", defaultValue: "Welcome")
		static let stepUnits = LocalizedStringResource("onboarding.step.units", defaultValue: "Units")
		static let stepStart = LocalizedStringResource("onboarding.step.start", defaultValue: "Start")
		static let stepGoal = LocalizedStringResource("onboarding.step.goal", defaultValue: "Goal")
		static let stepReminders = LocalizedStringResource("onboarding.step.reminders", defaultValue: "Reminders")
		static let stepFinish = LocalizedStringResource("onboarding.step.finish", defaultValue: "Finish")
		
		static let welcomeTitle = LocalizedStringResource("onboarding.welcome.title", defaultValue: "Welcome to Trimly")
		static let welcomeSubtitle = LocalizedStringResource("onboarding.welcome.subtitle", defaultValue: "Your supportive companion for mindful weight tracking")
		
		static let unitTitle = LocalizedStringResource("onboarding.unit.title", defaultValue: "Choose Your Unit")
		static let unitSubtitle = LocalizedStringResource("onboarding.unit.subtitle", defaultValue: "Select your preferred weight unit")
		static let unitOptionPounds = LocalizedStringResource("onboarding.unit.option.pounds", defaultValue: "Pounds (lb)")
		static let unitOptionKilograms = LocalizedStringResource("onboarding.unit.option.kilograms", defaultValue: "Kilograms (kg)")
		static let unitPickerLabel = LocalizedStringResource("onboarding.unit.pickerLabel", defaultValue: "Preferred unit")
		
		static let startTitle = LocalizedStringResource("onboarding.start.title", defaultValue: "Starting Weight")
		static let startSubtitle = LocalizedStringResource("onboarding.start.subtitle", defaultValue: "What's your current weight?")
		static let startPlaceholder = LocalizedStringResource("onboarding.start.placeholder", defaultValue: "Weight")
		static let startFieldLabel = LocalizedStringResource("onboarding.start.fieldLabel", defaultValue: "Starting weight entry")
		
		static let goalTitle = LocalizedStringResource("onboarding.goal.title", defaultValue: "Set Your Goal")
		static let goalSubtitle = LocalizedStringResource("onboarding.goal.subtitle", defaultValue: "What's your target weight?")
		static let goalPlaceholder = LocalizedStringResource("onboarding.goal.placeholder", defaultValue: "Goal")
		static let goalFieldLabel = LocalizedStringResource("onboarding.goal.fieldLabel", defaultValue: "Goal weight entry")
		
		static let remindersTitle = LocalizedStringResource("onboarding.reminder.title", defaultValue: "Daily Reminders")
		static let remindersSubtitle = LocalizedStringResource("onboarding.reminder.subtitle", defaultValue: "Stay consistent with gentle reminders")
		static let reminderToggle = LocalizedStringResource("onboarding.reminder.toggle", defaultValue: "Enable Daily Reminder")
		static let reminderHint = LocalizedStringResource("onboarding.reminder.hint", defaultValue: "We'll remind you at 9:00 AM each day")
		
		static let eulaTitle = LocalizedStringResource("onboarding.eula.title", defaultValue: "Terms & Privacy")
		static let eulaSubtitle = LocalizedStringResource("onboarding.eula.subtitle", defaultValue: "By continuing, you agree to our Terms of Service and Privacy Policy")
		static let eulaTerms = LocalizedStringResource("onboarding.eula.terms", defaultValue: "Read Terms of Service")
		static let eulaPrivacy = LocalizedStringResource("onboarding.eula.privacy", defaultValue: "Read Privacy Policy")
	}
}
