import Foundation

/// Three points for the one open row that matches the posted score.
struct HitMark: Codable, Equatable, Sendable, Identifiable {
    static let points = 3

    var id: UUID
    var couponID: Coupon.ID
    var points: Int
    var at: Date

    init(id: UUID = UUID(), couponID: Coupon.ID, at: Date) {
        self.id = id
        self.couponID = couponID
        self.points = Self.points
        self.at = at
    }
}
