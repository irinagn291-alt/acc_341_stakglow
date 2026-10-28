import Foundation
#if os(iOS)
import UIKit
#endif

/// Live screenshot driver: `-ReviewScreen today|log|goals` (plus extra cover keys).
/// Read `ReviewLaunch.screen` once, after onboarding is done, and open that
/// screen. Keep this file; the navigation it drives belongs to the app.
enum ReviewLaunch {
    static let argument = "-ReviewScreen"

    /// The key after `-ReviewScreen`, or nil on a normal launch.
    static var screen: String? {
        screen(from: ProcessInfo.processInfo.arguments)
    }

    /// Pure parse so tests can cover the launch keys without a view.
    static func screen(from arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: argument), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    /// Cover launches pass `-ReviewScreen`. Freeze UIKit transitions so the
    /// screenshot is the destination, not a mid-animation. Call from the main actor.
    @MainActor
    static func disableAnimationsIfNeeded() {
        #if os(iOS)
        if ProcessInfo.processInfo.arguments.contains(argument) {
            UIView.setAnimationsEnabled(false)
        }
        #endif
    }
}
