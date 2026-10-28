import SwiftUI

/// Boots the desk, then shows the week rail once onboarding is done.
struct ContentView: View {
    @State private var desk: BoardDesk
    @State private var showWait = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _desk = State(initialValue: BoardDesk(store: AppSupport.store()))
    }

    var body: some View {
        root
            .background(DesignTokens.bg.ignoresSafeArea())
            .task {
                ReviewLaunch.disableAnimationsIfNeeded()
                guard !desk.isReady else { return }
                let wait = Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    if !desk.isReady {
                        showWait = true
                    }
                }
                await desk.prepare()
                wait.cancel()
                showWait = false
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .inactive || phase == .background {
                    desk.sceneBecameInactive()
                }
            }
    }

    @ViewBuilder
    private var root: some View {
        if !desk.isReady {
            HomeSkeleton(showWait: showWait)
        } else if !desk.onboardingComplete {
            OnboardingView(desk: desk)
        } else if let screen = desk.launchScreen {
            launched(screen)
        } else {
            BoardView(desk: desk)
        }
    }

    @ViewBuilder
    private func launched(_ screen: String) -> some View {
        switch screen {
        case "log", "fixtures":
            FixturesSheet(desk: desk, scoreEntry: false, showsClose: false)
        case "goals", "standings":
            StandingsSheet(desk: desk, showsClose: false)
        case "settings":
            SettingsSheet(desk: desk, editorFirst: false, showsClose: false)
        case "post":
            FixturesSheet(desk: desk, scoreEntry: true, showsClose: false)
        case "tipsters":
            SettingsSheet(desk: desk, editorFirst: true, showsClose: false)
        case "events", "twist":
            TwistScreen(desk: desk, showsClose: false)
        case "analytics", "tape":
            TapeScreen(desk: desk, showsClose: false)
        default:
            BoardView(desk: desk)
        }
    }
}

private enum AppSupport {
    static func store() -> CouponStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("Stakglow", isDirectory: true)
        return CouponStore(suiteName: "com.chadwick.coupon", directory: directory)
    }
}

private struct HomeSkeleton: View {
    var showWait: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = Spacing.s12

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            HStack(spacing: Spacing.s4) {
                Text("Matches")
                Text("Table")
                Text("Settings")
            }
            .font(TypeScale.body.weight(.semibold))
            Text("OPEN")
                .font(TypeScale.caption.weight(.semibold))
                .tracking(TypeScale.labelTracking)
            Text("Home club")
                .font(TypeScale.display(displaySize))
            Text("Away club")
                .font(TypeScale.title)
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(DesignTokens.surface)
                .frame(minHeight: Spacing.s12 * 4)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .stroke(DesignTokens.muted, lineWidth: Hairline.width)
                }
            if showWait {
                ProgressView()
                    .tint(DesignTokens.accent)
                    .frame(minHeight: HitTarget.min)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .redacted(reason: .placeholder)
        .background(DesignTokens.bg)
    }
}
