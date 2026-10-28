import Foundation

/// Fold phase of a week board. Blank is the empty fold. Void is the late-lock branch.
enum BoardPhase: String, Codable, Equatable, Sendable {
    case blank
    case open
    case perforated
    case locked
    case posted
    case void
}
