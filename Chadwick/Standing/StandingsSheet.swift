import SwiftUI

/// Weekly points, derived from posted matches. Nothing here is stored as a total.
struct StandingsSheet: View {
    @Bindable var desk: BoardDesk
    var showsClose: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = Spacing.s12

    var body: some View {
        SheetChrome(title: "Table", showsClose: showsClose, close: { desk.sheet = nil }) {
            Group {
                if desk.board.tipsters.isEmpty {
                    EmptyStateView(
                        imageName: "chw_EmptyBoard",
                        title: "No one is here yet.",
                        line: "Add a person, then punch a match before kickoff.",
                        actionTitle: "Add a person"
                    ) {
                        desk.sheet = .settings(tipsterEditor: true)
                    }
                } else {
                    table
                }
            }
        }
    }

    private var rows: [(tipster: Tipster, standing: Standing)] {
        desk.board.tipsters.map { person in
            (person, Standing.derive(from: desk.board.coupons, tipster: person.id))
        }
        .sorted { lhs, rhs in
            if lhs.standing.points == rhs.standing.points {
                return lhs.tipster.name < rhs.tipster.name
            }
            return lhs.standing.points > rhs.standing.points
        }
    }

    private var table: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let notice = desk.notice {
                    NoticeBanner(message: notice) {
                        Task { await desk.retry() }
                    }
                }
                if let leader = rows.first {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text("Leader")
                            .font(TypeScale.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.muted)
                        Text(leader.tipster.name)
                            .font(TypeScale.display(displaySize))
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(leader.standing.points, format: .number.precision(.fractionLength(0)))
                            .font(TypeScale.monoRail)
                            .foregroundStyle(DesignTokens.accent)
                            .contentTransition(.numericText(value: Double(leader.standing.points)))
                        Text("points this week")
                            .font(TypeScale.body)
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    statRow(leader.standing)
                        .padding(Spacing.s4)
                        .hairlineFill()
                }
                if rows.count > 1 {
                    VStack(alignment: .leading, spacing: Spacing.s4) {
                        Text("Everyone else")
                            .font(TypeScale.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.ink)
                        ForEach(rows.dropFirst(), id: \.tipster.id) { row in
                            HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
                                Text(row.tipster.name)
                                    .font(TypeScale.body)
                                    .foregroundStyle(DesignTokens.ink)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: Spacing.s3)
                                Text(row.standing.points, format: .number.precision(.fractionLength(0)))
                                    .font(TypeScale.mono)
                                    .foregroundStyle(DesignTokens.ink)
                                    .layoutPriority(1)
                            }
                            .frame(minHeight: HitTarget.min)
                            statRow(row.standing)
                        }
                    }
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hairlineFill()
                }
                Text("A hit is worth three points. A miss is worth none. A void stays off the total.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.s6)
        }
    }

    private func statRow(_ standing: Standing) -> some View {
        HStack(spacing: Spacing.s4) {
            stat("Hits", standing.hits)
            stat("Misses", standing.misses)
            stat("Voids", standing.voids)
        }
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(value, format: .number.precision(.fractionLength(0)))
                .font(TypeScale.mono)
                .foregroundStyle(DesignTokens.ink)
            Text(label)
                .font(TypeScale.caption)
                .foregroundStyle(DesignTokens.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
