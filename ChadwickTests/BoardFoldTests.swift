import XCTest
@testable import Chadwick

enum BoardFixtures {
    static func slate(now: Date) -> Board {
        let week = WeekDaykey.monday(containing: now)
        let jules = Tipster(id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA") ?? UUID(), name: "Jules")
        let fixture = Fixture(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB") ?? UUID(),
            homeClub: "North End",
            awayClub: "Harbor",
            kickoff: now.addingTimeInterval(3600),
            weekDaykey: week
        )
        let second = Fixture(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC") ?? UUID(),
            homeClub: "Red Line",
            awayClub: "Civic",
            kickoff: now.addingTimeInterval(7200),
            weekDaykey: week
        )
        let coupons = [fixture, second].map { item in
            Coupon(fixtureID: item.id, tipsterID: jules.id)
        }
        return Board(fixtures: [fixture, second], tipsters: [jules], coupons: coupons)
    }

    static func perforate(_ board: inout Board, at: Date) {
        for coupon in board.coupons {
            _ = board.punch(couponID: coupon.id, row: .home, at: at)
            _ = board.punch(couponID: coupon.id, row: .draw, at: at)
        }
    }
}

final class BoardFoldTests: XCTestCase {
    func testEmptyBoardIsBlank() {
        let board = Board()
        XCTAssertEqual(board.phase, .blank)
        XCTAssertTrue(board.coupons.isEmpty)
    }

    func testPunchFoldsOpenToPerforatedWhenEachCouponHasOneOpenRow() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(board.phase, .open)
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: at)
        XCTAssertEqual(board.phase, .perforated)
        XCTAssertTrue(board.coupons.allSatisfy { $0.openCount == 1 && $0.survivingSide == .away })
        XCTAssertEqual(board.log.punches.count, 4)
    }

    func testOpenCopyPunchesOnlyWhileTwoRowsRemain() {
        let twoOpen = Coupon(
            fixtureID: UUID(),
            tipsterID: UUID(),
            rows: OutcomeRow.trio(punched: [.home])
        )
        XCTAssertEqual(
            WeekCopy.nextStep(phase: .open, coupon: twoOpen),
            "Punch draw next. Leave one result open."
        )
        let oneOpen = Coupon(
            fixtureID: UUID(),
            tipsterID: UUID(),
            rows: OutcomeRow.trio(punched: [.home, .draw])
        )
        let line = WeekCopy.nextStep(phase: .open, coupon: oneOpen)
        XCTAssertEqual(oneOpen.openCount, 1)
        XCTAssertFalse(line.contains("Punch away"))
        XCTAssertFalse(line.contains("punch away"))
        XCTAssertEqual(line, "This match keeps one result. Punch a hole on the next match.")
    }

    func testToggleReopensAndFoldsBackToOpen() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: at)
        let first = board.coupons[0].id
        let reopened = board.punch(couponID: first, row: .home, at: at)
        XCTAssertNotNil(try? reopened.get())
        XCTAssertEqual(board.phase, .open)
        XCTAssertEqual(board.coupons[0].openCount, 2)
    }

    func testArchitectureFoldIsTheBoardNotAStoredTotal() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: at)
        let locked = board.lock(at: at)
        XCTAssertNotNil(try? locked.get())
        XCTAssertEqual(board.phase, .locked)
        XCTAssertEqual(board.log.locks.count, 1)
        let standing = Standing.derive(from: board.coupons, tipster: board.tipsters[0].id)
        XCTAssertEqual(standing.points, 0)
    }
}

final class LockRefusalTests: XCTestCase {
    func testLockWhileACouponHasTwoOpenRowsWritesSparMark() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        let first = board.coupons[0]
        _ = board.punch(couponID: first.id, row: .home, at: at)
        XCTAssertGreaterThanOrEqual(board.coupons[0].openCount, 2)
        let refused = board.lock(at: at)
        guard case .failure(.spar(let spar)) = refused else {
            return XCTFail("Expected SparMark")
        }
        XCTAssertEqual(board.phase, .open)
        XCTAssertTrue(board.log.locks.isEmpty)
        XCTAssertEqual(board.log.spars.count, 1)
        XCTAssertEqual(spar.openCouponIDs.count, board.coupons.count)
    }

    func testLockAfterKickoffWritesVoidMark() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let early = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: early)
        let late = Date(timeIntervalSince1970: 1_700_010_000)
        let refused = board.lock(at: late)
        guard case .failure(.voided(let marks)) = refused else {
            return XCTFail("Expected VoidMark")
        }
        XCTAssertEqual(marks.count, board.coupons.count)
        XCTAssertEqual(board.phase, .void)
        XCTAssertTrue(board.log.locks.isEmpty)
        XCTAssertTrue(board.coupons.allSatisfy(\.voided))
    }

    func testPunchOnLockedIsRefused() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: at)
        _ = board.lock(at: at)
        let punch = board.punch(couponID: board.coupons[0].id, row: .away, at: at)
        XCTAssertEqual(punch, .failure(.locked))
        XCTAssertEqual(board.phase, .locked)
        XCTAssertEqual(board.coupons[0].survivingSide, .away)
    }

    func testLockBeforeKickoffWritesLockMark() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: at)
        let locked = board.lock(at: at)
        XCTAssertEqual(board.phase, .locked)
        XCTAssertEqual(try? locked.get().weekDaykey, board.fixtures[0].weekDaykey)
    }
}

final class PostScoringTests: XCTestCase {
    func testHitIsThreeAndMissIsZeroFromTheTypedScore() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: at)
        _ = board.lock(at: at)
        let homeWin = board.post(fixtureID: board.fixtures[0].id, home: 2, away: 0, at: at)
        let marks = try? homeWin.get()
        XCTAssertEqual(marks?.count, 1)
        XCTAssertEqual(marks?.first?.points, MissMark.points)
        XCTAssertEqual(board.coupons[0].postedPoints, 0)
        let awayWin = board.post(fixtureID: board.fixtures[1].id, home: 0, away: 1, at: at)
        XCTAssertEqual(try? awayWin.get().first?.points, HitMark.points)
        XCTAssertEqual(board.phase, .posted)
        XCTAssertEqual(HitMark.points, 3)
        XCTAssertEqual(MissMark.points, 0)
        // Typed finals only. Points are never drawn from RNG.
        XCTAssertNotEqual(board.coupons[0].postedPoints, board.coupons[1].postedPoints)
    }

    func testPostBeforeLockIsRefusedAndNegativeScoresAreInvalid() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        let early = board.post(fixtureID: board.fixtures[0].id, home: 1, away: 0, at: at)
        XCTAssertEqual(early, .failure(.notLocked))
        BoardFixtures.perforate(&board, at: at)
        _ = board.lock(at: at)
        let negative = board.post(fixtureID: board.fixtures[0].id, home: -1, away: 0, at: at)
        XCTAssertEqual(negative, .failure(.invalidScore))
        XCTAssertNil(board.fixtures[0].finalHome)
    }

    func testOnePickLocksBeforeResolveAndScoresTheRealOutcome() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let at = Date(timeIntervalSince1970: 1_700_000_100)
        XCTAssertEqual(board.coupons[0].openCount, 3)
        BoardFixtures.perforate(&board, at: at)
        XCTAssertEqual(board.coupons[0].openCount, 1)
        XCTAssertLessThan(at, board.fixtures[0].kickoff)
        _ = board.lock(at: at)
        _ = board.post(fixtureID: board.fixtures[0].id, home: 1, away: 1, at: at)
        XCTAssertEqual(board.coupons[0].postedPoints, MissMark.points)
        _ = board.post(fixtureID: board.fixtures[1].id, home: 0, away: 3, at: at)
        let standing = Standing.derive(from: board.coupons, tipster: board.tipsters[0].id)
        XCTAssertEqual(standing.hits, 1)
        XCTAssertEqual(standing.misses, 1)
        XCTAssertEqual(standing.points, HitMark.points)
        XCTAssertEqual(standing.voids, 0)
    }
}

final class StandingTests: XCTestCase {
    func testVoidsAreCountedAndNotStoredAsATotal() {
        var board = BoardFixtures.slate(now: Date(timeIntervalSince1970: 1_700_000_000))
        let early = Date(timeIntervalSince1970: 1_700_000_100)
        BoardFixtures.perforate(&board, at: early)
        _ = board.lock(at: Date(timeIntervalSince1970: 1_700_010_000))
        let standing = Standing.derive(from: board.coupons, tipster: board.tipsters[0].id)
        XCTAssertEqual(standing.voids, 2)
        XCTAssertEqual(standing.points, 0)
        XCTAssertEqual(standing.hits, 0)
    }
}

final class PersistenceTests: XCTestCase {
    func testWriteReloadRoundTrip() async throws {
        let suite = "chw.test.\(UUID().uuidString)"
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(suite, isDirectory: true)
        let store = CouponStore(suiteName: suite, directory: directory)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var board = BoardFixtures.slate(now: now)
        BoardFixtures.perforate(&board, at: now)
        _ = board.lock(at: now)
        let root = CouponRoot(board: board, onboardingComplete: true)
        await store.scheduleSave(root)
        await store.flush()
        let reloaded = CouponStore(suiteName: suite, directory: directory)
        let loaded = await reloaded.load()
        XCTAssertEqual(loaded.root.board.phase, .locked)
        XCTAssertEqual(loaded.root.board.coupons.map(\.id), board.coupons.map(\.id))
        XCTAssertEqual(loaded.root.board.log.locks.count, 1)
        XCTAssertEqual(loaded.root.board.log.punches.count, board.log.punches.count)
        XCTAssertTrue(loaded.root.onboardingComplete)
        XCTAssertNil(loaded.notice)
        await reloaded.resetAllData()
        let emptied = await reloaded.load()
        XCTAssertEqual(emptied.root.board.phase, .blank)
    }

    func testCorruptFileFallsBackToBackup() async throws {
        let suite = "chw.backup.\(UUID().uuidString)"
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(suite, isDirectory: true)
        let store = CouponStore(suiteName: suite, directory: directory)
        let root = DemoSeed.root(now: Date(timeIntervalSince1970: 1_700_000_000))
        await store.scheduleSave(root)
        await store.flush()
        let file = directory.appendingPathComponent("coupon-root.json")
        let backup = directory.appendingPathComponent("coupon-root.json.backup")
        let good = try Data(contentsOf: file)
        try good.write(to: backup, options: .atomic)
        try Data("not-json".utf8).write(to: file, options: .atomic)
        let loaded = await store.load()
        XCTAssertEqual(loaded.root.board.coupons.count, 6)
        XCTAssertEqual(loaded.root.board.log.punches.count, 1)
        XCTAssertEqual(loaded.root.board.phase, .open)
        XCTAssertNotNil(loaded.notice)
        await store.resetAllData()
    }
}

final class ReviewLaunchParserTests: XCTestCase {
    func testReviewScreenKeys() {
        XCTAssertEqual(ReviewLaunch.screen(from: ["Chadwick", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Chadwick", "-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Chadwick", "-ReviewScreen", "goals"]), "goals")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Chadwick", "-ReviewScreen", "settings"]), "settings")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Chadwick", "-ReviewScreen", "post"]), "post")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Chadwick", "-ReviewScreen", "tipsters"]), "tipsters")
        XCTAssertNil(ReviewLaunch.screen(from: ["Chadwick"]))
        XCTAssertNil(ReviewLaunch.screen(from: ["Chadwick", "-ReviewScreen"]))
        XCTAssertEqual(ReviewRoute.parse("log")?.sheet, .fixtures(scoreEntry: false))
        XCTAssertEqual(ReviewRoute.parse("goals")?.sheet, .standings)
        XCTAssertEqual(ReviewRoute.parse("post")?.sheet, .fixtures(scoreEntry: true))
        XCTAssertNil(ReviewRoute.parse("today")?.sheet)
    }
}
