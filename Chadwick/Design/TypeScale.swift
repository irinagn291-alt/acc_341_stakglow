import SwiftUI

/// Six steps. Superclarendon for short headers. SF Pro for sentences. SF Mono for numerals.
enum TypeScale {
    static let labelTracking: CGFloat = 0.8

    static func display(_ size: CGFloat) -> Font {
        Font.custom(DesignTokens.fontFamily, size: size, relativeTo: .largeTitle)
    }

    static let title = Font.custom(DesignTokens.fontFamily, size: 28, relativeTo: .title2)
    static let body = Font.system(.body)
    static let caption = Font.system(.caption)
    static let mono = Font.system(.body, design: .monospaced).monospacedDigit()
    static let monoRail = Font.system(.title2, design: .monospaced).monospacedDigit()
}
