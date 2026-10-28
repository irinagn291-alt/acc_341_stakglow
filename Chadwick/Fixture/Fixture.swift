import Foundation

/// One match on the week slate. The final score is typed in. It is never drawn.
struct Fixture: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var homeClub: String
    var awayClub: String
    var kickoff: Date
    var weekDaykey: Int
    var finalHome: Int?
    var finalAway: Int?

    init(
        id: UUID = UUID(),
        homeClub: String,
        awayClub: String,
        kickoff: Date,
        weekDaykey: Int,
        finalHome: Int? = nil,
        finalAway: Int? = nil
    ) {
        self.id = id
        self.homeClub = homeClub
        self.awayClub = awayClub
        self.kickoff = kickoff
        self.weekDaykey = weekDaykey
        self.finalHome = finalHome
        self.finalAway = finalAway
    }

    /// The side the typed score actually produced.
    static func survivingSide(home: Int, away: Int) -> OutcomeRow.Side {
        if home > away {
            return .home
        }
        if away > home {
            return .away
        }
        return .draw
    }
}
