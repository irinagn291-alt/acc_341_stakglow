import Foundation

/// Append-only mark log. Standings are not a field here.
struct MarkLog: Codable, Equatable, Sendable {
    var punches: [PunchMark]
    var locks: [LockMark]
    var spars: [SparMark]
    var voids: [VoidMark]
    var hits: [HitMark]
    var misses: [MissMark]

    init(
        punches: [PunchMark] = [],
        locks: [LockMark] = [],
        spars: [SparMark] = [],
        voids: [VoidMark] = [],
        hits: [HitMark] = [],
        misses: [MissMark] = []
    ) {
        self.punches = punches
        self.locks = locks
        self.spars = spars
        self.voids = voids
        self.hits = hits
        self.misses = misses
    }
}
