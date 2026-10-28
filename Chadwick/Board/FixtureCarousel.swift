import SwiftUI

/// Horizontal match rail. Each name is a button. The selected match wears the cursor.
struct FixtureCarousel: View {
    let fixtures: [Fixture]
    let previewIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: Spacing.s3) {
                ForEach(Array(fixtures.enumerated()), id: \.element.id) { index, fixture in
                    Button {
                        onSelect(index)
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            if index == previewIndex {
                                Image(systemName: "smallcircle.filled.circle")
                                    .font(TypeScale.caption)
                                    .foregroundStyle(DesignTokens.accent)
                                    .accessibilityHidden(true)
                            }
                            Text(fixture.homeClub)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text("vs")
                                .foregroundStyle(DesignTokens.muted)
                            Text(fixture.awayClub)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .font(TypeScale.mono)
                        .foregroundStyle(index == previewIndex ? DesignTokens.ink : DesignTokens.muted)
                        .padding(.horizontal, Spacing.s4)
                        .frame(minHeight: HitTarget.min)
                        .contentShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
                    }
                    .buttonStyle(MatchChipStyle(selected: index == previewIndex))
                    .accessibilityLabel("\(fixture.homeClub) against \(fixture.awayClub)")
                    .accessibilityAddTraits(index == previewIndex ? .isSelected : [])
                }
            }
            .padding(.vertical, Spacing.s1)
        }
        .scrollIndicators(.hidden)
    }
}

private struct MatchChipStyle: ButtonStyle {
    var selected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .fill(DesignTokens.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                    .stroke(selected ? DesignTokens.accent : DesignTokens.muted, lineWidth: Hairline.width)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(reduceMotion ? nil : Motion.stateChange, value: configuration.isPressed)
    }
}
