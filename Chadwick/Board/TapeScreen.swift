import SwiftUI

/// A chronological tape of punches. Distinct from the points table.
struct TapeScreen: View {
    @Bindable var desk: BoardDesk
    var showsClose: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = Spacing.s10

    var body: some View {
        SheetChrome(title: "Week tape", showsClose: showsClose, close: { desk.cover = nil }) {
            Group {
                if desk.board.coupons.isEmpty && desk.board.log.punches.isEmpty {
                    EmptyStateView(
                        imageName: "chw_EmptyBoard",
                        title: "No punches yet.",
                        line: "Add a match and punch the first hole.",
                        actionTitle: "Add a match"
                    ) {
                        desk.sheet = .settings(tipsterEditor: false)
                        desk.cover = nil
                    }
                } else {
                    tape
                }
            }
        }
    }

    private var tape: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                Text(WeekCopy.phaseLabel(desk.board.phase))
                    .font(TypeScale.caption.weight(.semibold))
                    .tracking(TypeScale.labelTracking)
                    .foregroundStyle(DesignTokens.muted)
                Text("What has been punched")
                    .font(TypeScale.display(displaySize))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(WeekCopy.nextStep(phase: desk.board.phase, coupon: desk.activeCoupon))
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    if desk.board.log.punches.isEmpty {
                        Text("No holes are punched yet.")
                            .font(TypeScale.body)
                            .foregroundStyle(DesignTokens.ink)
                    }
                    ForEach(desk.board.log.punches) { mark in
                        punchLine(mark)
                    }
                }
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .hairlineFill()
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text("Still open")
                        .font(TypeScale.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.ink)
                    ForEach(desk.board.coupons) { coupon in
                        openLine(coupon)
                    }
                }
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .hairlineFill()
            }
            .padding(Spacing.s6)
        }
    }

    private func punchLine(_ mark: PunchMark) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            Text(mark.at, format: .dateTime.hour().minute())
                .font(TypeScale.mono)
                .foregroundStyle(DesignTokens.accent)
                .layoutPriority(1)
            Text(sentence(for: mark))
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: HitTarget.min)
    }

    private func openLine(_ coupon: Coupon) -> some View {
        let fixture = desk.board.fixtures.first { $0.id == coupon.fixtureID }
        let person = desk.board.tipsters.first { $0.id == coupon.tipsterID }
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            Text(person?.name ?? "unknown")
                .lineLimit(1)
                .truncationMode(.tail)
            Text(fixture?.homeClub ?? "unknown")
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: Spacing.s3)
            Text(coupon.openCount, format: .number.precision(.fractionLength(0)))
                .font(TypeScale.mono)
                .foregroundStyle(DesignTokens.ink)
                .layoutPriority(1)
            Text("open")
                .font(TypeScale.caption)
                .foregroundStyle(DesignTokens.muted)
        }
        .font(TypeScale.body)
        .foregroundStyle(DesignTokens.ink)
        .frame(minHeight: HitTarget.min)
    }

    private func sentence(for mark: PunchMark) -> String {
        let person = desk.board.tipsters.first { $0.id == coupon(mark.couponID)?.tipsterID }?.name ?? "Someone"
        let fixture = desk.board.fixtures.first { $0.id == coupon(mark.couponID)?.fixtureID }
        let clubs = fixture.map { "\($0.homeClub) against \($0.awayClub)" } ?? "a match"
        let verb = mark.punched ? "punched" : "reopened"
        return "\(person) \(verb) \(WeekCopy.resultName(mark.side)) on \(clubs)."
    }

    private func coupon(_ id: Coupon.ID) -> Coupon? {
        desk.board.coupons.first { $0.id == id }
    }
}
