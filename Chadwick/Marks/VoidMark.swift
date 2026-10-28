import Foundation

/// Written on a coupon whose kickoff passed before any LockMark.
struct VoidMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var couponID: Coupon.ID
    var at: Date

    init(id: UUID = UUID(), couponID: Coupon.ID, at: Date) {
        self.id = id
        self.couponID = couponID
        self.at = at
    }
}
