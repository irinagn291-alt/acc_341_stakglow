import Foundation

/// Append-only record that a Punch toggled one OutcomeRow hole.
struct PunchMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var couponID: Coupon.ID
    var side: OutcomeRow.Side
    var punched: Bool
    var at: Date

    init(
        id: UUID = UUID(),
        couponID: Coupon.ID,
        side: OutcomeRow.Side,
        punched: Bool,
        at: Date
    ) {
        self.id = id
        self.couponID = couponID
        self.side = side
        self.punched = punched
        self.at = at
    }
}
