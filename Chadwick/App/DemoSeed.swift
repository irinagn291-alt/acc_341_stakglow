import Foundation

/// Simulator seed. Three fixtures, two tipsters, one punch on the first coupon.
enum DemoSeed {
    static let defaultsKey = "chw.demo.v1"

    static func root(now: Date) -> CouponRoot {
        let week = WeekDaykey.monday(containing: now)
        let jules = Tipster(name: "Jules")
        let maren = Tipster(name: "Maren")
        let fixtures = [
            Fixture(
                homeClub: "North End",
                awayClub: "Harbor",
                kickoff: now.addingTimeInterval(60 * 60 * 30),
                weekDaykey: week
            ),
            Fixture(
                homeClub: "Red Line",
                awayClub: "Civic",
                kickoff: now.addingTimeInterval(60 * 60 * 50),
                weekDaykey: week
            ),
            Fixture(
                homeClub: "West Yard",
                awayClub: "Kiln",
                kickoff: now.addingTimeInterval(60 * 60 * 74),
                weekDaykey: week
            ),
        ]
        var coupons: [Coupon] = []
        for fixture in fixtures {
            coupons.append(Coupon(fixtureID: fixture.id, tipsterID: jules.id))
            coupons.append(Coupon(fixtureID: fixture.id, tipsterID: maren.id))
        }
        var board = Board(fixtures: fixtures, tipsters: [jules, maren], coupons: coupons)
        if let first = board.coupons.first {
            _ = board.punch(couponID: first.id, row: .home, at: now)
        }
        return CouponRoot(board: board, onboardingComplete: true)
    }
}
