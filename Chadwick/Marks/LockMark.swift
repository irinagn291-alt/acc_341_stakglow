import Foundation

/// Written when Lock folds a perforated board to Locked before kickoff.
struct LockMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var at: Date
    var weekDaykey: Int

    init(id: UUID = UUID(), at: Date, weekDaykey: Int) {
        self.id = id
        self.at = at
        self.weekDaykey = weekDaykey
    }
}
