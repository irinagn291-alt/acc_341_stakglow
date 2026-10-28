import SwiftUI

/// People, next matches, the introduction, reset, and contact.
struct SettingsSheet: View {
    @Bindable var desk: BoardDesk
    var editorFirst: Bool
    var showsClose: Bool

    @State private var newName = ""
    @State private var homeClub = ""
    @State private var awayClub = ""
    @State private var kickoff = Date().addingTimeInterval(60 * 60 * 24)
    @State private var confirmReset = false
    @State private var confirmDiscard = false
    @FocusState private var focus: PeopleFocus?

    var body: some View {
        SheetChrome(title: "Settings", showsClose: showsClose, close: requestClose) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s8) {
                        if let notice = desk.notice {
                            NoticeBanner(message: notice) {
                                Task { await desk.retry() }
                            }
                        }
                        if desk.board.tipsters.isEmpty && desk.board.fixtures.isEmpty {
                            Text("Nothing is saved on this phone yet. Add a person and a match.")
                                .font(TypeScale.body)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        TipsterEditor(desk: desk, newName: $newName, focus: $focus)
                        matchEditor
                        phoneSection
                        if let refusal = desk.refusal {
                            Text(refusal)
                                .font(TypeScale.body)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(Spacing.s6)
                }
                .scrollDismissesKeyboard(.interactively)
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { focus = nil }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Next") { advance() }
                        Spacer()
                        Button("Done") { focus = nil }
                    }
                }
                .onAppear {
                    guard editorFirst else { return }
                    proxy.scrollTo("people", anchor: .top)
                    focus = .newName
                }
            }
        }
        .confirmationDialog(
            "Reset all data?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                desk.resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every match, person, and point on this phone.")
        }
        .confirmationDialog(
            "Discard this match?",
            isPresented: $confirmDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard match", role: .destructive) {
                desk.sheet = nil
            }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("The clubs you typed will not be added.")
        }
        .interactiveDismissDisabled(isDirty)
    }

    private var matchEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Matches this week")
                .font(TypeScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.ink)
            if desk.board.fixtures.isEmpty {
                Text("No matches yet. Add the first one below.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(desk.board.fixtures) { fixture in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                        Text(fixture.homeClub)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text("vs")
                            .foregroundStyle(DesignTokens.muted)
                        Text(fixture.awayClub)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: Spacing.s3)
                        Text(fixture.kickoff, format: .dateTime.weekday(.abbreviated).hour().minute())
                            .font(TypeScale.mono)
                            .foregroundStyle(DesignTokens.ink)
                            .layoutPriority(1)
                    }
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .frame(minHeight: HitTarget.min)
                }
            }
            field("Home club", text: $homeClub, focus: .homeClub, next: .awayClub)
            field("Away club", text: $awayClub, focus: .awayClub, next: nil)
            DatePicker("Kickoff", selection: $kickoff, displayedComponents: [.date, .hourAndMinute])
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .tint(DesignTokens.accent)
            Button("Add match") {
                desk.addFixture(home: homeClub, away: awayClub, kickoff: kickoff)
                if desk.refusal == nil {
                    homeClub = ""
                    awayClub = ""
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(homeClub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || awayClub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var phoneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("This phone")
                .font(TypeScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.ink)
            Button("Show the introduction again") {
                desk.replayOnboarding()
            }
            .buttonStyle(QuietButtonStyle())
            Button("Reset all data") {
                confirmReset = true
            }
            .buttonStyle(QuietButtonStyle())
            if let url = ContactPage.url {
                Link(destination: url) {
                    Text("Contact")
                        .font(TypeScale.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: .infinity, minHeight: HitTarget.min)
                        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                }
                .hairlineFill()
            } else {
                Text("Contact page is unavailable.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                Button("Retry") {}
                    .buttonStyle(QuietButtonStyle())
                    .disabled(true)
            }
        }
    }

    private var isDirty: Bool {
        !homeClub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !awayClub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func requestClose() {
        if isDirty {
            confirmDiscard = true
        } else {
            desk.sheet = nil
        }
    }

    private func advance() {
        switch focus {
        case .newName:
            focus = .homeClub
        case .homeClub:
            focus = .awayClub
        case .awayClub, nil:
            focus = nil
        }
    }

    private func field(_ prompt: String, text: Binding<String>, focus target: PeopleFocus, next: PeopleFocus?) -> some View {
        TextField("", text: text, prompt: Text(prompt).foregroundStyle(DesignTokens.muted))
            .font(TypeScale.body)
            .foregroundStyle(DesignTokens.ink)
            .textInputAutocapitalization(.words)
            .focused($focus, equals: target)
            .submitLabel(next == nil ? .done : .next)
            .onSubmit { self.focus = next }
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: HitTarget.min)
            .hairlineFill(radius: Radius.chip)
    }
}
