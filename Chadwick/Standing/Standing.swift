import Foundation

/// Derived from posted coupons for one tipster. The table is never stored.
struct Standing: Equatable, Sendable {
    var tipsterID: Tipster.ID
    var points: Int
    var hits: Int
    var misses: Int
    var voids: Int

    static func derive(from coupons: [Coupon], tipster: Tipster.ID) -> Standing {
        let mine = coupons.filter { $0.tipsterID == tipster }
        var hits = 0
        var misses = 0
        var voids = 0
        var points = 0
        for coupon in mine {
            if coupon.voided {
                voids += 1
                continue
            }
            guard let posted = coupon.postedPoints else {
                continue
            }
            points += posted
            if posted == HitMark.points {
                hits += 1
            } else {
                misses += 1
            }
        }
        return Standing(
            tipsterID: tipster,
            points: points,
            hits: hits,
            misses: misses,
            voids: voids
        )
    }
}
