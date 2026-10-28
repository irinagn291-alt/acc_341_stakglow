import SwiftUI

/// The active match. One punch is the cursor. The other holes sit beside it when the width allows.
struct CouponCard: View {
    let coupon: Coupon
    let onPunch: (OutcomeRow.Side) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.s3) {
                if let cursor = cursorRow {
                    hole(cursor, offersPunch: offersPunch)
                        .frame(maxWidth: .infinity)
                }
                quietStack
                    .frame(maxWidth: .infinity)
            }
            .frame(minWidth: Spacing.s12 * 10)
            VStack(alignment: .leading, spacing: Spacing.s3) {
                if let cursor = cursorRow {
                    hole(cursor, offersPunch: offersPunch)
                }
                quietStack
            }
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }

    private var cursorRow: OutcomeRow? {
        coupon.rows.first { !$0.punched }
    }

    private var quietRows: [OutcomeRow] {
        coupon.rows.filter { $0.id != cursorRow?.id }
    }

    private var offersPunch: Bool {
        coupon.openCount > 1
    }

    private var quietStack: some View {
        let layout = AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s3))
        return layout {
            ForEach(quietRows) { row in
                hole(row, offersPunch: false)
            }
        }
    }

    private func hole(_ row: OutcomeRow, offersPunch: Bool) -> some View {
        PunchHoleView(
            side: row.side,
            punched: row.punched,
            isCursor: row.id == cursorRow?.id,
            offersPunch: offersPunch
        ) {
            onPunch(row.side)
        }
    }
}
