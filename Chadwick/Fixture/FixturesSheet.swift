import SwiftUI

/// The week's matches, kickoff clocks, and a typed final score for each one.
struct FixturesSheet: View {
    @Bindable var desk: BoardDesk
    var scoreEntry: Bool
    var showsClose: Bool

    @State private var drafts: [ScoreDraft] = []
    @State private var confirmDiscard = false
    @FocusState private var focus: ScoreFocus?

    var body: some View {
        SheetChrome(title: "Matches", showsClose: showsClose, close: requestClose) {
            Group {
                if desk.board.fixtures.isEmpty {
                    EmptyStateView(
                        imageName: "chw_EmptyBoard",
                        title: "No matches yet.",
                        line: "Add a match and lock a pick before kickoff.",
                        actionTitle: "Add a match"
                    ) {
                        desk.sheet = .settings(tipsterEditor: false)
                    }
                } else {
                    matchList
                }
            }
        }
        .confirmationDialog(
            "Discard these scores?",
            isPresented: $confirmDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard scores", role: .destructive) {
                desk.sheet = nil
            }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("The numbers you typed will not be posted.")
        }
        .interactiveDismissDisabled(isDirty)
        .onAppear {
            syncDrafts()
            if scoreEntry {
                let target = desk.scoreFixtureID ?? desk.board.fixtures.first?.id
                if let target {
                    focus = .home(target)
                }
            }
        }
        .onChange(of: fixtureIDs) { _, _ in
            syncDrafts()
        }
    }

    private var matchList: some View {
        ScrollViewReader { proxy in
            List {
                if scoreEntry {
                    Text("Type the final score for each match.")
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .listRowBackground(DesignTokens.bg)
                        .listRowSeparator(.hidden)
                }
                if let notice = desk.notice {
                    NoticeBanner(message: notice) {
                        Task { await desk.retry() }
                    }
                    .listRowBackground(DesignTokens.bg)
                    .listRowSeparator(.hidden)
                }
                ForEach($drafts) { $draft in
                    if let fixture = desk.board.fixtures.first(where: { $0.id == draft.id }) {
                        ScoreEntryView(
                            fixtureID: fixture.id,
                            homeClub: fixture.homeClub,
                            awayClub: fixture.awayClub,
                            kickoff: fixture.kickoff,
                            finalHome: fixture.finalHome,
                            finalAway: fixture.finalAway,
                            homeText: $draft.home,
                            awayText: $draft.away,
                            canPost: canPost(draft, fixture: fixture),
                            isPosting: desk.isPosting,
                            locked: desk.board.phase == .locked,
                            focus: $focus,
                            onPost: { post(draft) }
                        )
                        .id(fixture.id)
                        .listRowBackground(DesignTokens.bg)
                        .listRowSeparatorTint(DesignTokens.muted)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(DesignTokens.bg)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Next") { advanceFocus() }
                    Spacer()
                    Button("Done") { focus = nil }
                }
            }
            .onAppear {
                guard scoreEntry, let id = desk.scoreFixtureID ?? desk.board.fixtures.first?.id else {
                    return
                }
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }

    private var fixtureIDs: [Fixture.ID] {
        desk.board.fixtures.map(\.id)
    }

    private var isDirty: Bool {
        drafts.contains { !$0.home.isEmpty || !$0.away.isEmpty }
    }

    private func syncDrafts() {
        let ids = fixtureIDs
        guard drafts.map(\.id) != ids else { return }
        drafts = ids.map { ScoreDraft(id: $0, home: "", away: "") }
    }

    private func canPost(_ draft: ScoreDraft, fixture: Fixture) -> Bool {
        desk.board.phase == .locked
            && !desk.isPosting
            && fixture.finalHome == nil
            && !draft.home.isEmpty
            && !draft.away.isEmpty
    }

    private func post(_ draft: ScoreDraft) {
        guard let home = Int(draft.home), let away = Int(draft.away) else {
            return
        }
        desk.post(fixtureID: draft.id, home: home, away: away)
    }

    private func requestClose() {
        if isDirty {
            confirmDiscard = true
        } else {
            desk.sheet = nil
        }
    }

    private func advanceFocus() {
        guard let focus else { return }
        switch focus {
        case .home(let id):
            self.focus = .away(id)
        case .away(let id):
            if let index = drafts.firstIndex(where: { $0.id == id }), index + 1 < drafts.count {
                self.focus = .home(drafts[index + 1].id)
            } else {
                self.focus = nil
            }
        }
    }
}
