import SwiftUI

/// One outcome hole. The live punch is the cursor. The other holes stay quieter.
struct PunchHoleView: View {
    let side: OutcomeRow.Side
    let punched: Bool
    let isCursor: Bool
    var offersPunch: Bool
    let action: () -> Void

    var body: some View {
        Group {
            if offersPunch {
                Button(action: action) {
                    label
                        .frame(maxWidth: .infinity, minHeight: HitTarget.min, alignment: .leading)
                        .padding(Spacing.s4)
                        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(labelText)
            } else if isSurvivor {
                label
                    .frame(maxWidth: .infinity, minHeight: HitTarget.min, alignment: .leading)
                    .padding(Spacing.s3)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(labelText)
            } else {
                Button(action: action) {
                    label
                        .frame(maxWidth: .infinity, minHeight: HitTarget.min, alignment: .leading)
                        .padding(Spacing.s3)
                        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                }
                .buttonStyle(HoleButtonStyle())
                .accessibilityLabel(labelText)
            }
        }
    }

    @ViewBuilder
    private var label: some View {
        if offersPunch {
            HStack(alignment: .center, spacing: Spacing.s4) {
                holeMark
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(verb)
                        .font(TypeScale.monoRail)
                        .foregroundStyle(DesignTokens.accent)
                        .lineLimit(1)
                    Text(WeekCopy.resultName(side))
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.s2)
            }
        } else {
            HStack(alignment: .center, spacing: Spacing.s3) {
                holeMark
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(verb)
                        .font(TypeScale.mono)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                    Text(WeekCopy.resultName(side))
                        .font(TypeScale.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.s2)
            }
        }
    }

    private var holeMark: some View {
        Circle()
            .fill(punched ? DesignTokens.muted : DesignTokens.bg)
            .overlay {
                Circle()
                    .stroke(offersPunch ? DesignTokens.accent : DesignTokens.muted, lineWidth: Hairline.width)
            }
            .frame(width: offersPunch ? Spacing.s12 : Spacing.s8, height: offersPunch ? Spacing.s12 : Spacing.s8)
            .accessibilityHidden(true)
    }

    /// The last open row is the result that stays. It is a readout, not a punch.
    private var isSurvivor: Bool {
        isCursor && !punched && !offersPunch
    }

    private var verb: String {
        if punched {
            return "Out"
        }
        if offersPunch {
            return "Punch"
        }
        if isCursor {
            return "Keep"
        }
        return "Open"
    }

    private var labelText: String {
        if offersPunch {
            return "Punch \(WeekCopy.resultName(side))"
        }
        if isCursor, !punched {
            return "Keep \(WeekCopy.resultName(side))"
        }
        return punched
            ? "\(WeekCopy.resultName(side)), out"
            : "\(WeekCopy.resultName(side)), open"
    }
}

private struct HoleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(DesignTokens.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(DesignTokens.muted, lineWidth: Hairline.width)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(reduceMotion ? nil : Motion.stateChange, value: configuration.isPressed)
    }
}
