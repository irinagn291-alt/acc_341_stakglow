import Foundation

/// One posted coupon scores either a hit or a miss. Never both.
enum OutcomeMark: Codable, Equatable, Sendable {
    case hit(HitMark)
    case miss(MissMark)

    var couponID: Coupon.ID {
        switch self {
        case .hit(let mark):
            return mark.couponID
        case .miss(let mark):
            return mark.couponID
        }
    }

    var points: Int {
        switch self {
        case .hit(let mark):
            return mark.points
        case .miss(let mark):
            return mark.points
        }
    }
}
