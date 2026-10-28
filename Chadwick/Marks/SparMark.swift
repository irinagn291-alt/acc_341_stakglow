import Foundation

/// Written when Lock is refused because a coupon still has two or more open rows.
struct SparMark: Codable, Equatable, Sendable, Identifiable, Error {
    var id: UUID
    var at: Date
    var openCouponIDs: [Coupon.ID]

    init(id: UUID = UUID(), at: Date, openCouponIDs: [Coupon.ID]) {
        self.id = id
        self.at = at
        self.openCouponIDs = openCouponIDs
    }
}
