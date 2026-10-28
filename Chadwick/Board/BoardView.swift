import SwiftUI

/// Home is the punch rail. Matches, the table, and Settings arrive as sheets.
struct BoardView: View {
    @Bindable var desk: BoardDesk

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var drag: CGFloat = 0
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = Spacing.s12

    var body: some View {
        Group {
            if desk.board.fixtures.isEmpty {
                EmptyStateView(
                    imageName: "chw_EmptyHome",
                    title: "No matches yet.",
                    line: "Add a match and lock a pick before kickoff.",
                    actionTitle: "Add a match"
                ) {
                    desk.sheet = .settings(tipsterEditor: false)
                }
            } else {
                rail
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
        .sheet(item: $desk.sheet) { item in
            switch item {
            case .fixtures(let scoreEntry):
                FixturesSheet(desk: desk, scoreEntry: scoreEntry, showsClose: true)
            case .standings:
                StandingsSheet(desk: desk, showsClose: true)
            case .settings(let editor):
                SettingsSheet(desk: desk, editorFirst: editor, showsClose: true)
            }
        }
        .sheet(item: $desk.cover) { cover in
            switch cover {
            case .twist:
                TwistScreen(desk: desk, showsClose: true)
            case .tape:
                TapeScreen(desk: desk, showsClose: true)
            }
        }
        .sensoryFeedback(.success, trigger: desk.lockGeneration)
    }

    private var rail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                topBar
                statusRail
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s6) {
                        titleBlock
                        Spacer(minLength: Spacing.s4)
                        pointsBlock
                    }
                    VStack(alignment: .leading, spacing: Spacing.s4) {
                        titleBlock
                        pointsBlock
                    }
                }
                holes
                    .opacity(holeFade)
                    .animation(reduceMotion ? nil : Motion.crossfade, value: previewCoupon?.id)
                people
                FixtureCarousel(
                    fixtures: desk.board.fixtures,
                    previewIndex: previewIndex,
                    onSelect: { index in
                        desk.focusFixture(at: index)
                    }
                )
                .simultaneousGesture(carouselDrag)
                kickoffStrip
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.top, Spacing.s4)
            .padding(.bottom, Spacing.s6)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                if let refusal = desk.refusal {
                    Text(refusal)
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let notice = desk.notice {
                    NoticeBanner(message: notice) {
                        Task { await desk.retry() }
                    }
                }
                PunchLockControl(phase: desk.board.phase) {
                    desk.focusFixture(at: previewIndex)
                    desk.lock()
                }
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.top, Spacing.s3)
            .padding(.bottom, Spacing.s4)
            .background(DesignTokens.bg)
        }
    }

    private var topBar: some View {
        HStack(spacing: Spacing.s2) {
            RailWord(title: "Matches") {
                desk.sheet = .fixtures(scoreEntry: false)
            }
            RailWord(title: "Table") {
                desk.sheet = .standings
            }
            RailWord(title: "Settings") {
                desk.sheet = .settings(tipsterEditor: false)
            }
            Spacer(minLength: Spacing.s2)
        }
    }

    private var statusRail: some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(DesignTokens.accent)
                .frame(width: Spacing.s1, height: Spacing.s6)
                .accessibilityHidden(true)
            Text(WeekCopy.phaseLabel(desk.board.phase))
                .font(TypeScale.caption.weight(.semibold))
                .tracking(TypeScale.labelTracking)
                .foregroundStyle(DesignTokens.ink)
            Spacer(minLength: Spacing.s3)
            if let count = previewCoupon?.openCount {
                Text(count, format: .number.precision(.fractionLength(0)))
                    .font(TypeScale.mono)
                    .foregroundStyle(DesignTokens.accent)
                    .contentTransition(.numericText(value: Double(count)))
                    .animation(reduceMotion ? nil : Motion.stateChange, value: count)
                Text("open")
                    .font(TypeScale.caption)
                    .foregroundStyle(DesignTokens.muted)
            }
        }
        .frame(minHeight: HitTarget.min)
        .accessibilityElement(children: .combine)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("Punch the wrong result.")
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(previewFixture?.homeClub ?? "unknown")
                .font(TypeScale.display(displaySize))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(previewFixture?.awayClub ?? "unknown")
                .font(TypeScale.title)
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text(WeekCopy.nextStep(phase: desk.board.phase, coupon: previewCoupon))
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pointsBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            if let points = activePoints {
                Text(points, format: .number.precision(.fractionLength(0)))
                    .font(TypeScale.monoRail)
                    .foregroundStyle(DesignTokens.ink)
                    .contentTransition(.numericText(value: Double(points)))
                    .animation(reduceMotion ? nil : Motion.stateChange, value: points)
            } else {
                Text("unknown")
                    .font(TypeScale.monoRail)
                    .foregroundStyle(DesignTokens.muted)
            }
            Text("points")
                .font(TypeScale.caption)
                .foregroundStyle(DesignTokens.muted)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var holes: some View {
        if let coupon = previewCoupon {
            CouponCard(coupon: coupon) { side in
                desk.focusFixture(at: previewIndex)
                desk.punch(row: side)
            }
            .frame(maxWidth: .infinity, minHeight: Spacing.s12 * 4, alignment: .top)
        }
    }

    private var people: some View {
        HStack(alignment: .center, spacing: Spacing.s2) {
            Text("With")
                .font(TypeScale.caption)
                .foregroundStyle(DesignTokens.muted)
            ForEach(desk.board.tipsters) { person in
                Button {
                    guard let fixtureID = previewFixture?.id else { return }
                    desk.focus(fixtureID: fixtureID, tipsterID: person.id)
                }                 label: {
                    HStack(spacing: Spacing.s2) {
                        if person.id == desk.activeTipsterID {
                            Image(systemName: "checkmark")
                                .font(TypeScale.caption.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                        Text(person.name)
                            .font(TypeScale.body.weight(person.id == desk.activeTipsterID ? .semibold : .regular))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(person.id == desk.activeTipsterID ? DesignTokens.accent : DesignTokens.ink)
                    .padding(.horizontal, Spacing.s2)
                    .frame(minHeight: HitTarget.min)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressOpacityStyle())
                .accessibilityAddTraits(person.id == desk.activeTipsterID ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    private var kickoffStrip: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if let kickoff = previewFixture?.kickoff {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    KickoffLine(kickoff: kickoff, now: context.date)
                }
            }
            Button("See how lock works") {
                desk.cover = .twist
            }
            .buttonStyle(QuietButtonStyle())
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private var carouselDrag: some Gesture {
        DragGesture(minimumDistance: Spacing.s8)
            .updating($drag) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let projected = value.predictedEndTranslation.width
                if projected < -Spacing.s12 {
                    desk.shiftFixture(by: 1)
                } else if projected > Spacing.s12 {
                    desk.shiftFixture(by: -1)
                }
            }
    }

    private var committedIndex: Int {
        let fixtures = desk.board.fixtures
        guard !fixtures.isEmpty else { return 0 }
        let current = desk.activeCoupon?.fixtureID
        return fixtures.firstIndex { $0.id == current } ?? 0
    }

    private var previewIndex: Int {
        let count = desk.board.fixtures.count
        guard count > 0 else { return 0 }
        if reduceMotion {
            return committedIndex
        }
        if drag < -Spacing.s12 {
            return min(committedIndex + 1, count - 1)
        }
        if drag > Spacing.s12 {
            return max(committedIndex - 1, 0)
        }
        return committedIndex
    }

    private var previewFixture: Fixture? {
        let fixtures = desk.board.fixtures
        guard fixtures.indices.contains(previewIndex) else { return nil }
        return fixtures[previewIndex]
    }

    private var previewCoupon: Coupon? {
        guard let fixture = previewFixture, let tipsterID = desk.activeTipsterID else {
            return desk.activeCoupon
        }
        return desk.board.coupons.first { $0.fixtureID == fixture.id && $0.tipsterID == tipsterID }
    }

    private var activePoints: Int? {
        guard let tipsterID = desk.activeTipsterID else { return nil }
        return desk.standings().first { $0.tipsterID == tipsterID }?.points
    }

    private var holeFade: Double {
        if reduceMotion { return 1 }
        let travel = min(abs(drag) / (Spacing.s12 * 2 + Spacing.s6), 1)
        return 1 - travel * 0.35
    }
}

private struct RailWord: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TypeScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.ink)
                .padding(.horizontal, Spacing.s3)
                .frame(minHeight: HitTarget.min)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

private struct KickoffLine: View {
    let kickoff: Date
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if kickoff <= now {
                Text("Kickoff has passed.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                    Text("Kickoff in")
                    Text(hours, format: .number.precision(.fractionLength(0)))
                        .font(TypeScale.mono)
                        .foregroundStyle(DesignTokens.accent)
                        .contentTransition(.numericText(value: hours))
                    Text(wholeHours == 1 ? "hour." : "hours.")
                }
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
            }
            HStack(spacing: Spacing.s2) {
                if Calendar.current.startOfDay(for: kickoff) == Calendar.current.startOfDay(for: now) {
                    Text("Today")
                        .font(TypeScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.ink)
                }
                Text(kickoff, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(TypeScale.mono)
                    .foregroundStyle(DesignTokens.muted)
            }
        }
    }

    private var hours: Double {
        max(0, kickoff.timeIntervalSince(now) / 3600)
    }

    private var wholeHours: Int {
        Int(hours.rounded(.toNearestOrAwayFromZero))
    }
}

struct NoticeBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text("Something failed.")
                .font(TypeScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.ink)
            Text(message)
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("Retry", action: retry)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }
}
