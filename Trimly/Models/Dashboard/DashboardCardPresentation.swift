import Foundation

extension DashboardCard {
    var title: LocalizedStringResource {
        switch self {
        case .today: L10n.Dashboard.currentWeight
        case .progress: L10n.Dashboard.progress
        case .sparkline: L10n.Dashboard.lastSevenDays
        case .consistency: L10n.Dashboard.consistencyScore
        case .trend: L10n.Dashboard.trendTitle
        case .calendar: L10n.Dashboard.monthlyCalendar
        case .plateau: L10n.Dashboard.plateauDetected
        case .projection: L10n.Insights.paceTitle
        case .recap: L10n.Insights.recapTitle
        }
    }
}
