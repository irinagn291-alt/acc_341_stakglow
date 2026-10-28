import SwiftUI

/// Three pages. Continue sits full width at the bottom. Skip still finishes setup.
struct OnboardingView: View {
    var desk: BoardDesk

    @State private var page = 0
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = Spacing.s10
    @ScaledMetric(relativeTo: .largeTitle) private var artHeight = Spacing.s12 * 5

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(spacing: Spacing.s2) {
                Text(page + 1, format: .number.precision(.fractionLength(0)))
                Text("of")
                Text(pages.count, format: .number.precision(.fractionLength(0)))
            }
            .font(TypeScale.mono)
            .foregroundStyle(DesignTokens.muted)
            .padding(.horizontal, Spacing.s6)
            .padding(.top, Spacing.s4)
            .accessibilityElement(children: .combine)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    pageBody(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: Spacing.s3) {
                Button("Continue") { advance() }
                    .buttonStyle(PrimaryButtonStyle())
                Button("Skip") { desk.finishOnboarding() }
                    .buttonStyle(QuietButtonStyle())
            }
            .padding(.horizontal, Spacing.s6)
            .padding(.bottom, Spacing.s4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg)
    }

    private var pages: [(image: String, title: String, line: String)] {
        [
            (
                "chw_Onboarding1",
                "One phone for the week.",
                "Friends knock out the wrong results, then lock those picks before kickoff."
            ),
            (
                "chw_Onboarding2",
                "Punch the wrong results.",
                "Each tap closes one hole. Stop when a single result remains on every match."
            ),
            (
                "chw_Onboarding3",
                "Lock, then post the score.",
                "A typed final score gives \(HitMark.points) points for a hit and \(MissMark.points) for a miss."
            ),
        ]
    }

    private func pageBody(_ item: (image: String, title: String, line: String)) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Image(item.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: artHeight)
                .clipped()
                .accessibilityHidden(true)
            Text(item.title)
                .font(TypeScale.display(displaySize))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.line)
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s4)
        }
        .padding(.horizontal, Spacing.s6)
        .padding(.top, Spacing.s4)
    }

    private func advance() {
        if page + 1 < pages.count {
            page += 1
        } else {
            desk.finishOnboarding()
        }
    }
}
