import Foundation

/// One hole on a fixture coupon. Home, draw, and away are the only sides.
struct OutcomeRow: Codable, Equatable, Sendable, Identifiable {
    enum Side: String, Codable, Equatable, Sendable, CaseIterable {
        case home
        case draw
        case away
    }

    var id: UUID
    var side: Side
    var punched: Bool

    init(id: UUID = UUID(), side: Side, punched: Bool = false) {
        self.id = id
        self.side = side
        self.punched = punched
    }

    static func trio(punched: Set<Side> = []) -> [OutcomeRow] {
        Side.allCases.map { side in
            OutcomeRow(side: side, punched: punched.contains(side))
        }
    }
}
