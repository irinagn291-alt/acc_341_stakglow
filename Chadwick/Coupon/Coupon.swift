import Foundation

/// Three outcome rows for one fixture and one tipster. Punch toggles a hole.
struct Coupon: Codable, Equatable, Sendable, Identifiable {
    typealias ID = UUID

    var id: ID
    var fixtureID: Fixture.ID
    var tipsterID: Tipster.ID
    var rows: [OutcomeRow]
    var voided: Bool
    /// Nil until Post. Then HitMark.points or MissMark.points. Never a running total.
    var postedPoints: Int?

    init(
        id: ID = UUID(),
        fixtureID: Fixture.ID,
        tipsterID: Tipster.ID,
        rows: [OutcomeRow] = OutcomeRow.trio(),
        voided: Bool = false,
        postedPoints: Int? = nil
    ) {
        self.id = id
        self.fixtureID = fixtureID
        self.tipsterID = tipsterID
        self.rows = rows
        self.voided = voided
        self.postedPoints = postedPoints
    }

    var openRows: [OutcomeRow] {
        rows.filter { !$0.punched }
    }

    var openCount: Int {
        openRows.count
    }

    var survivingSide: OutcomeRow.Side? {
        guard openRows.count == 1 else {
            return nil
        }
        return openRows[0].side
    }

    /// Toggle the hole for `row`. The caller decides whether the board phase allows it.
    func punch(row: OutcomeRow.Side, at: Date) -> Result<(Coupon, PunchMark), PunchRefusal> {
        guard let index = rows.firstIndex(where: { $0.side == row }) else {
            return .failure(.missingRow)
        }
        var copy = self
        copy.rows[index].punched.toggle()
        let mark = PunchMark(
            couponID: id,
            side: row,
            punched: copy.rows[index].punched,
            at: at
        )
        return .success((copy, mark))
    }
}

enum PunchRefusal: Equatable, Sendable, Error {
    case locked
    case posted
    case voided
    case missingCoupon
    case missingRow
}
