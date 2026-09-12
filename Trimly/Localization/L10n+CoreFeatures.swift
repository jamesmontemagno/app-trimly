import Foundation

extension L10n {
    enum CoreFeatures {
        static let achievementDetails = LocalizedStringResource("achievement.details", defaultValue: "Achievement details", table: "CoreFeatures")
        static let achievementExplanation = LocalizedStringResource("achievement.explanation", defaultValue: "Progress uses visible entries. Hiding or correcting a measurement updates progress, but achievements already earned stay unlocked.", table: "CoreFeatures")
        static let firstDayTitle = LocalizedStringResource("achievement.firstDay.title", defaultValue: "A fresh start", table: "CoreFeatures")
        static let firstDayDetail = LocalizedStringResource("achievement.firstDay.detail", defaultValue: "Log on your first day. Every journey starts with one check-in.", table: "CoreFeatures")
        static let sevenDaysTitle = LocalizedStringResource("achievement.sevenDays.title", defaultValue: "Finding your rhythm", table: "CoreFeatures")
        static let sevenDaysDetail = LocalizedStringResource("achievement.sevenDays.detail", defaultValue: "Log on seven different days, at your own pace. They do not need to be consecutive.", table: "CoreFeatures")
    }
}
