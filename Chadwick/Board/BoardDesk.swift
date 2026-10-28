import Foundation
import Observation

/// In-memory board the screens will read. Views do not touch the store.
@MainActor
@Observable
final class BoardDesk {
    private(set) var board: Board
    private(set) var onboardingComplete: Bool
    private(set) var notice: String?
    private(set) var refusal: String?
    var activeCouponID: Coupon.ID?
    var activeTipsterID: Tipster.ID?
    var sheet: ReviewRoute.Sheet?
    var cover: BoardCover?
    var scoreFixtureID: Fixture.ID?
    private(set) var isReady = false
    private(set) var isPosting = false
    private(set) var lockGeneration = 0
    private(set) var launchScreen: String?
    private var didApplyLaunch = false

    private let store: CouponStore
    private var saveTask: Task<Void, Never>?

    init(store: CouponStore, root: CouponRoot = CouponRoot(board: Board(), onboardingComplete: false)) {
        self.store = store
        self.board = root.board
        self.onboardingComplete = root.onboardingComplete
        self.activeCouponID = root.board.coupons.first?.id
        self.activeTipsterID = root.board.tipsters.first?.id
    }

    var activeCoupon: Coupon? {
        board.coupons.first { $0.id == activeCouponID }
    }

    var activePoints: Int? {
        guard let tipsterID = activeTipsterID else {
            return nil
        }
        return standings().first { $0.tipsterID == tipsterID }?.points
    }

    /// Await the store before the first frame so onboarding cannot flash over a seeded week.
    func prepare(now: Date = Date()) async {
        let loaded = await store.loadSeededIfNeeded(now: now)
        apply(loaded)
        applyReviewLaunch()
        isReady = true
    }

    func retry(now: Date = Date()) async {
        let loaded = await store.load()
        apply(loaded)
        isReady = true
    }

    func load(now: Date = Date()) {
        saveTask?.cancel()
        saveTask = Task {
            let loaded = await store.loadSeededIfNeeded(now: now)
            if Task.isCancelled {
                return
            }
            apply(loaded)
        }
    }

    func applyReviewLaunch() {
        guard onboardingComplete, !didApplyLaunch else {
            return
        }
        didApplyLaunch = true
        let raw = ReviewLaunch.screen
        launchScreen = raw
        let route = ReviewRoute.parse(raw)
        sheet = route?.sheet
        cover = nil
        if route == .post {
            scoreFixtureID = board.fixtures.first?.id
        }
        switch raw {
        case "events", "twist":
            sheet = nil
            cover = .twist
        case "analytics", "tape":
            sheet = nil
            cover = .tape
        default:
            break
        }
    }

    func finishOnboarding() {
        onboardingComplete = true
        persist(immediate: true)
        applyReviewLaunch()
    }

    func replayOnboarding() {
        onboardingComplete = false
        sheet = nil
        cover = nil
        persist(immediate: true)
    }

    func focus(fixtureID: Fixture.ID, tipsterID: Tipster.ID) {
        activeTipsterID = tipsterID
        activeCouponID = board.coupons.first {
            $0.fixtureID == fixtureID && $0.tipsterID == tipsterID
        }?.id
    }

    func focusFixture(at index: Int) {
        guard board.fixtures.indices.contains(index) else {
            return
        }
        guard let tipsterID = activeTipsterID ?? board.tipsters.first?.id else {
            return
        }
        focus(fixtureID: board.fixtures[index].id, tipsterID: tipsterID)
    }

    func shiftFixture(by delta: Int) {
        guard delta != 0, !board.fixtures.isEmpty else {
            return
        }
        let currentID = activeCoupon?.fixtureID ?? board.fixtures[0].id
        let current = board.fixtures.firstIndex { $0.id == currentID } ?? 0
        let next = min(max(current + delta, 0), board.fixtures.count - 1)
        guard next != current else {
            return
        }
        focusFixture(at: next)
    }

    func punch(row: OutcomeRow.Side, at: Date = Date()) {
        guard let couponID = activeCouponID else {
            refusal = "Add a match, then punch a hole."
            return
        }
        switch board.punch(couponID: couponID, row: row, at: at) {
        case .success:
            refusal = nil
            persist()
        case .failure(.locked):
            refusal = "This week is locked. Post the score after the match."
        case .failure(.posted):
            refusal = "This week is already posted."
        case .failure(.voided):
            refusal = "Kickoff passed before lock. This match is void."
        case .failure(.missingCoupon), .failure(.missingRow):
            refusal = "That hole is not on this match."
        }
    }

    func lock(at: Date = Date()) {
        let locksBefore = board.log.locks.count
        switch board.lock(at: at) {
        case .success:
            if board.log.locks.count > locksBefore {
                lockGeneration += 1
            }
            refusal = nil
            persist(immediate: true)
        case .failure(.voided):
            refusal = "Kickoff passed. Those matches are void."
            persist(immediate: true)
        case .failure(.spar):
            refusal = "Punch until every match has one open result, then lock."
            persist()
        }
    }

    func post(fixtureID: Fixture.ID, home: Int, away: Int, at: Date = Date()) {
        guard !isPosting else {
            return
        }
        isPosting = true
        switch board.post(fixtureID: fixtureID, home: home, away: away, at: at) {
        case .success:
            refusal = nil
            persist(immediate: true)
        case .failure(.notLocked):
            refusal = "Lock the week before you post a score."
        case .failure(.invalidScore):
            refusal = "Enter the final score as two numbers."
        case .failure(.missingFixture):
            refusal = "That match is not on this week."
        }
        isPosting = false
    }

    func renameTipster(id: Tipster.ID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            refusal = "Enter a name before saving."
            return
        }
        guard let index = board.tipsters.firstIndex(where: { $0.id == id }) else {
            refusal = "That person is not on this week."
            return
        }
        board.tipsters[index].name = trimmed
        refusal = nil
        persist()
    }

    func addTipster(name: String) {
        guard board.phase == .blank || board.phase == .open || board.phase == .perforated else {
            refusal = "The week is already locked."
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            refusal = "Enter a name before adding a person."
            return
        }
        let person = Tipster(name: trimmed)
        board.tipsters.append(person)
        for fixture in board.fixtures {
            board.coupons.append(Coupon(fixtureID: fixture.id, tipsterID: person.id))
        }
        if activeTipsterID == nil {
            activeTipsterID = person.id
        }
        recomputeOpenPhase()
        refusal = nil
        persist(immediate: true)
    }

    func addFixture(home: String, away: String, kickoff: Date) {
        guard board.phase == .blank || board.phase == .open || board.phase == .perforated else {
            refusal = "The week is already locked."
            return
        }
        let homeName = home.trimmingCharacters(in: .whitespacesAndNewlines)
        let awayName = away.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !homeName.isEmpty, !awayName.isEmpty else {
            refusal = "Enter both clubs before adding a match."
            return
        }
        if board.tipsters.isEmpty {
            board.tipsters = [Tipster(name: "You"), Tipster(name: "Friend")]
        }
        let fixture = Fixture(
            homeClub: homeName,
            awayClub: awayName,
            kickoff: kickoff,
            weekDaykey: WeekDaykey.monday(containing: kickoff)
        )
        board.fixtures.append(fixture)
        for person in board.tipsters {
            board.coupons.append(Coupon(fixtureID: fixture.id, tipsterID: person.id))
        }
        if activeTipsterID == nil {
            activeTipsterID = board.tipsters.first?.id
        }
        if activeCouponID == nil, let tipsterID = activeTipsterID {
            focus(fixtureID: fixture.id, tipsterID: tipsterID)
        }
        recomputeOpenPhase()
        refusal = nil
        persist(immediate: true)
    }

    func clearRefusal() {
        refusal = nil
    }

    func standings() -> [Standing] {
        board.standings()
    }

    func sceneBecameInactive() {
        saveTask?.cancel()
        let snapshot = currentRoot()
        saveTask = Task {
            await store.scheduleSave(snapshot)
            await store.flush()
        }
    }

    func resetAllData() {
        saveTask?.cancel()
        saveTask = Task {
            await store.resetAllData()
            board = Board()
            onboardingComplete = false
            notice = nil
            refusal = nil
            activeCouponID = nil
            activeTipsterID = nil
            sheet = nil
            cover = nil
            scoreFixtureID = nil
            isPosting = false
        }
    }

    private func apply(_ loaded: LoadedCoupon) {
        board = loaded.root.board
        onboardingComplete = loaded.root.onboardingComplete
        notice = loaded.notice
        activeCouponID = loaded.root.board.coupons.first?.id
        activeTipsterID = loaded.root.board.tipsters.first?.id
    }

    private func recomputeOpenPhase() {
        guard board.phase == .blank || board.phase == .open || board.phase == .perforated else {
            return
        }
        board.phase = Board.foldedPhase(coupons: board.coupons, locked: false)
    }

    private func persist(immediate: Bool = false) {
        let snapshot = currentRoot()
        saveTask?.cancel()
        saveTask = Task {
            if immediate {
                await store.scheduleSave(snapshot)
                await store.flush()
            } else {
                await store.scheduleSave(snapshot)
            }
        }
    }

    private func currentRoot() -> CouponRoot {
        CouponRoot(board: board, onboardingComplete: onboardingComplete)
    }
}

/// Full-page destinations the launch argument opens besides the week rail.
enum BoardCover: String, Identifiable, Equatable, Sendable {
    case twist
    case tape

    var id: String { rawValue }
}

extension ReviewRoute.Sheet: Identifiable {
    var id: String {
        switch self {
        case .fixtures(let scoreEntry):
            return scoreEntry ? "matches-score" : "matches"
        case .standings:
            return "table"
        case .settings(let tipsterEditor):
            return tipsterEditor ? "people" : "settings"
        }
    }
}
