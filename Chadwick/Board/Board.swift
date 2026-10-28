import Foundation

/// The week coupon aggregate. Phase is a fold over coupons, not a stored score.
struct Board: Codable, Equatable, Sendable {
    var fixtures: [Fixture]
    var tipsters: [Tipster]
    var coupons: [Coupon]
    var phase: BoardPhase
    var log: MarkLog

    init(
        fixtures: [Fixture] = [],
        tipsters: [Tipster] = [],
        coupons: [Coupon] = [],
        phase: BoardPhase? = nil,
        log: MarkLog = MarkLog()
    ) {
        self.fixtures = fixtures
        self.tipsters = tipsters
        self.coupons = coupons
        self.log = log
        self.phase = phase ?? Self.foldedPhase(coupons: coupons, locked: false)
    }

    static func foldedPhase(coupons: [Coupon], locked: Bool) -> BoardPhase {
        if coupons.isEmpty {
            return .blank
        }
        if locked {
            return .locked
        }
        if coupons.allSatisfy({ $0.openCount == 1 && !$0.voided }) {
            return .perforated
        }
        return .open
    }

    /// Toggle a hole. When every coupon has exactly one open row, Open folds to Perforated.
    mutating func punch(couponID: Coupon.ID, row: OutcomeRow.Side, at: Date) -> Result<PunchMark, PunchRefusal> {
        if phase == .locked {
            return .failure(.locked)
        }
        if phase == .posted {
            return .failure(.posted)
        }
        guard let index = coupons.firstIndex(where: { $0.id == couponID }) else {
            return .failure(.missingCoupon)
        }
        if coupons[index].voided || phase == .void && coupons[index].voided {
            return .failure(.voided)
        }
        if phase == .void {
            return .failure(.voided)
        }
        let punched = coupons[index].punch(row: row, at: at)
        switch punched {
        case .failure(let reason):
            return .failure(reason)
        case .success(let pair):
            coupons[index] = pair.0
            log.punches.append(pair.1)
            if phase == .open || phase == .perforated || phase == .blank {
                phase = Self.foldedPhase(coupons: coupons, locked: false)
            }
            return .success(pair.1)
        }
    }

    /// Lock before the earliest kickoff folds Perforated to Locked.
    /// Two or more open rows on any coupon writes SparMark and leaves the phase.
    /// A kickoff that has already passed writes VoidMark on that coupon.
    mutating func lock(at: Date) -> Result<LockMark, LockRefusal> {
        if phase == .locked, let existing = log.locks.last {
            return .success(existing)
        }
        let loose = coupons.filter { $0.openCount != 1 || $0.voided }.map(\.id)
        let multiOpen = coupons.filter { $0.openCount >= 2 }.map(\.id)
        if phase != .perforated || !multiOpen.isEmpty || !loose.isEmpty {
            let spar = SparMark(at: at, openCouponIDs: multiOpen.isEmpty ? loose : multiOpen)
            log.spars.append(spar)
            return .failure(.spar(spar))
        }
        let started = coupons.filter { coupon in
            guard let fixture = fixtures.first(where: { $0.id == coupon.fixtureID }) else {
                return false
            }
            return at >= fixture.kickoff
        }
        if !started.isEmpty {
            let marks = started.map { VoidMark(couponID: $0.id, at: at) }
            for mark in marks {
                if let index = coupons.firstIndex(where: { $0.id == mark.couponID }) {
                    coupons[index].voided = true
                }
                log.voids.append(mark)
            }
            phase = .void
            return .failure(.voided(marks))
        }
        let week = fixtures.map(\.weekDaykey).min() ?? WeekDaykey.monday(containing: at)
        let mark = LockMark(at: at, weekDaykey: week)
        log.locks.append(mark)
        phase = .locked
        return .success(mark)
    }

    /// Enter a real final score for one fixture. Locked folds to Posted once every coupon is marked.
    mutating func post(fixtureID: Fixture.ID, home: Int, away: Int, at: Date) -> Result<[OutcomeMark], PostRefusal> {
        guard phase == .locked else {
            return .failure(.notLocked)
        }
        guard home >= 0, away >= 0 else {
            return .failure(.invalidScore)
        }
        guard let fixtureIndex = fixtures.firstIndex(where: { $0.id == fixtureID }) else {
            return .failure(.missingFixture)
        }
        let side = Fixture.survivingSide(home: home, away: away)
        var written: [OutcomeMark] = []
        for index in coupons.indices where coupons[index].fixtureID == fixtureID {
            if coupons[index].voided {
                continue
            }
            if coupons[index].postedPoints != nil {
                continue
            }
            let mark: OutcomeMark
            if coupons[index].survivingSide == side {
                let hit = HitMark(couponID: coupons[index].id, at: at)
                log.hits.append(hit)
                coupons[index].postedPoints = hit.points
                mark = .hit(hit)
            } else {
                let miss = MissMark(couponID: coupons[index].id, at: at)
                log.misses.append(miss)
                coupons[index].postedPoints = miss.points
                mark = .miss(miss)
            }
            written.append(mark)
        }
        fixtures[fixtureIndex].finalHome = home
        fixtures[fixtureIndex].finalAway = away
        let waiting = coupons.contains { !$0.voided && $0.postedPoints == nil }
        if !waiting {
            phase = .posted
        }
        return .success(written)
    }

    func standings() -> [Standing] {
        tipsters.map { Standing.derive(from: coupons, tipster: $0.id) }
    }
}

enum LockRefusal: Equatable, Sendable, Error {
    case spar(SparMark)
    case voided([VoidMark])
}

enum PostRefusal: Equatable, Sendable, Error {
    case notLocked
    case invalidScore
    case missingFixture
}
