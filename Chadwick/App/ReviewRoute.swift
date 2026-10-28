import Foundation

/// Where `-ReviewScreen` sends the board after onboarding. Launch keys, not tabs.
enum ReviewRoute: String, Equatable, Sendable {
    case today
    case log
    case goals
    case settings
    case post
    case tipsters

    enum Sheet: Equatable, Sendable {
        case fixtures(scoreEntry: Bool)
        case standings
        case settings(tipsterEditor: Bool)
    }

    var sheet: Sheet? {
        switch self {
        case .today:
            return nil
        case .log:
            return .fixtures(scoreEntry: false)
        case .goals:
            return .standings
        case .settings:
            return .settings(tipsterEditor: false)
        case .post:
            return .fixtures(scoreEntry: true)
        case .tipsters:
            return .settings(tipsterEditor: true)
        }
    }

    static func parse(_ screen: String?) -> ReviewRoute? {
        guard let screen else {
            return nil
        }
        return ReviewRoute(rawValue: screen)
    }
}
