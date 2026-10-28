import Foundation

/// Zero points when the open row does not match the posted score.
struct MissMark: Codable, Equatable, Sendable, Identifiable {
    static let points = 0

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
