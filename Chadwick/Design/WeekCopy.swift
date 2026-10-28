import Foundation

/// User-facing lines for the fold. The phase itself stays on `Board`.
enum WeekCopy {
    static func phaseLabel(_ phase: BoardPhase) -> String {
        switch phase {
        case .blank:
            "EMPTY"
        case .open:
            "OPEN"
        case .perforated:
            "READY"
        case .locked:
            "LOCKED"
        case .posted:
            "POSTED"
        case .void:
            "VOID"
        }
    }

    static func resultName(_ side: OutcomeRow.Side) -> String {
        switch side {
        case .home:
            "Home"
        case .draw:
            "Draw"
        case .away:
            "Away"
        }
    }

    static func nextStep(phase: BoardPhase, coupon: Coupon?) -> String {
        switch phase {
        case .blank:
            return "Add a match and punch the first hole."
        case .locked:
            return "The week is locked. Post a score after the match."
        case .posted:
            return "Scores are in. Open the table to compare friends."
        case .void:
            return "Kickoff passed before lock. This match is void."
        case .perforated:
            return "Every match has one result. Lock the week before kickoff."
        case .open:
            guard let coupon else {
                return "Punch a hole on this match."
            }
            if coupon.openCount == 1 {
                return "This match keeps one result. Punch a hole on the next match."
            }
            if coupon.openCount > 1, let side = coupon.rows.first(where: { !$0.punched })?.side {
                return "Punch \(Self.resultName(side).lowercased()) next. Leave one result open."
            }
            return "Leave one result open on every match, then lock."
        }
    }
}
