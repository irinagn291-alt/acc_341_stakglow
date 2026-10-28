import SwiftUI

/// Full-page empty. Art, one headline, one line, one action at the bottom.
struct EmptyStateView: View {
    let imageName: String
    let title: String
    let line: String
    let actionTitle: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = Spacing.s10
    @ScaledMetric(relativeTo: .largeTitle) private var artHeight = Spacing.s12 * 5

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: artHeight)
                .clipped()
                .accessibilityHidden(true)
            Text(title)
                .font(TypeScale.display(displaySize))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s8)
            Button(actionTitle, action: action)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Spacing.s6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }
}
