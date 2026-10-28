import SwiftUI

/// The punch-then-lock rule, on its own page and one tap from home.
struct TwistScreen: View {
    @Bindable var desk: BoardDesk
    var showsClose: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = Spacing.s12
    @ScaledMetric(relativeTo: .largeTitle) private var artHeight = Spacing.s12 * 5

    var body: some View {
        SheetChrome(title: "Lock rule", showsClose: showsClose, close: { desk.cover = nil }) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    Image("chw_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: artHeight)
                        .clipped()
                        .accessibilityHidden(true)
                    Text("Punch, then lock.")
                        .font(TypeScale.display(displaySize))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Close two holes on every match until one result remains. Lock the week only then, and only before kickoff.")
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .center, spacing: Spacing.s4) {
                        Image("chw_LockedCoupon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: Spacing.s12 * 2, height: Spacing.s12 * 2)
                            .clipped()
                            .accessibilityHidden(true)
                        pointsLine
                    }
                    .padding(Spacing.s4)
                    .hairlineFill()
                    Text("If kickoff passes before lock, that match is void and scores nothing. You type the final score yourself.")
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.s6)
            }
        }
    }

    private var pointsLine: some View {
        let hit = HitMark.points
        let miss = MissMark.points
        return Text("A hit is worth \(hit, format: .number.precision(.fractionLength(0))) points. A miss is worth \(miss, format: .number.precision(.fractionLength(0))).")
            .font(TypeScale.body)
            .foregroundStyle(DesignTokens.ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}
