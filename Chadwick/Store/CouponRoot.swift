import Foundation

/// One persisted document. schemaVersion 1 is the only readable shape.
struct CouponRoot: Codable, Equatable, Sendable {
    static let currentSchema = 1

    var schemaVersion: Int
    var board: Board
    var onboardingComplete: Bool

    init(schemaVersion: Int = CouponRoot.currentSchema, board: Board, onboardingComplete: Bool) {
        self.schemaVersion = schemaVersion
        self.board = board
        self.onboardingComplete = onboardingComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = 1
            board = try container.decode(Board.self, forKey: .board)
            onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported coupon schema \(version)."
            )
        }
    }
}
