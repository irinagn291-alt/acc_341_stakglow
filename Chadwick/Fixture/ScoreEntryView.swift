import SwiftUI

enum ScoreFocus: Hashable {
    case home(Fixture.ID)
    case away(Fixture.ID)
}

struct ScoreDraft: Identifiable, Equatable {
    let id: Fixture.ID
    var home: String
    var away: String
}

/// Final score for one match. Digits only. Post stays quiet until the week is locked.
struct ScoreEntryView: View {
    let fixtureID: Fixture.ID
    let homeClub: String
    let awayClub: String
    let kickoff: Date
    let finalHome: Int?
    let finalAway: Int?
    @Binding var homeText: String
    @Binding var awayText: String
    var canPost: Bool
    var isPosting: Bool
    var locked: Bool
    @FocusState.Binding var focus: ScoreFocus?
    let onPost: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                Text(homeClub)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("vs")
                    .foregroundStyle(DesignTokens.muted)
                Text(awayClub)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: Spacing.s3)
                Text(kickoff, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(TypeScale.mono)
                    .foregroundStyle(DesignTokens.ink)
                    .layoutPriority(1)
            }
            .font(TypeScale.body)
            .foregroundStyle(DesignTokens.ink)

            if let finalHome, let finalAway {
                HStack(spacing: Spacing.s2) {
                    Text("Final")
                        .font(TypeScale.caption)
                        .foregroundStyle(DesignTokens.muted)
                    Text(finalHome, format: .number.precision(.fractionLength(0)))
                    Text("to")
                    Text(finalAway, format: .number.precision(.fractionLength(0)))
                }
                .font(TypeScale.mono)
                .foregroundStyle(DesignTokens.ink)
            } else {
                HStack(spacing: Spacing.s3) {
                    scoreField(
                        text: $homeText,
                        prompt: "Home",
                        target: .home(fixtureID),
                        next: .away(fixtureID)
                    )
                    scoreField(
                        text: $awayText,
                        prompt: "Away",
                        target: .away(fixtureID),
                        next: nil
                    )
                }
                Group {
                    if locked {
                        Button(isPosting ? "Posting" : "Post score", action: onPost)
                            .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button(isPosting ? "Posting" : "Post score", action: onPost)
                            .buttonStyle(QuietButtonStyle())
                    }
                }
                .disabled(!canPost)
                Text(locked ? "Type the real final score. A hit is three points." : "Lock the week before you post a score.")
                    .font(TypeScale.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scoreField(
        text: Binding<String>,
        prompt: String,
        target: ScoreFocus,
        next: ScoreFocus?
    ) -> some View {
        TextField("", text: text, prompt: Text(prompt).foregroundStyle(DesignTokens.muted))
            .font(TypeScale.mono)
            .foregroundStyle(DesignTokens.ink)
            .keyboardType(.numberPad)
            .focused($focus, equals: target)
            .submitLabel(next == nil ? .done : .next)
            .onSubmit {
                focus = next
            }
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: HitTarget.min)
            .frame(maxWidth: .infinity)
            .hairlineFill(radius: Radius.chip)
            .onChange(of: text.wrappedValue) { _, newValue in
                let digits = String(newValue.filter(\.isNumber))
                if digits != newValue {
                    text.wrappedValue = digits
                }
            }
    }
}
