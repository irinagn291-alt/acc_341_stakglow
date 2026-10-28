import SwiftUI

/// Lock fused to the active match. Accent only when every match has one open result.
struct PunchLockControl: View {
    let phase: BoardPhase
    let action: () -> Void

    var body: some View {
        Group {
            if phase == .perforated {
                Button(title, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(title, action: action)
                    .buttonStyle(QuietButtonStyle())
            }
        }
        .disabled(phase == .locked || phase == .posted || phase == .void || phase == .blank)
        .accessibilityHint(hint)
    }

    private var title: String {
        switch phase {
        case .perforated, .blank, .open:
            "Lock week"
        case .locked:
            "Week locked"
        case .posted:
            "Week posted"
        case .void:
            "Week void"
        }
    }

    private var hint: String {
        phase == .perforated
            ? "Freezes every remaining result before kickoff."
            : "Available after each match has one open result."
    }
}
