import SwiftUI

/// SPEC section 7. The only place these hex values live. Reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #18191B
    static let bg = Color(red: 0.094118, green: 0.098039, blue: 0.105882)
    static let bgHex = "#18191B"
    /// #222325
    static let surface = Color(red: 0.133333, green: 0.137255, blue: 0.145098)
    static let surfaceHex = "#222325"
    /// #EDEFF2
    static let ink = Color(red: 0.929412, green: 0.937255, blue: 0.949020)
    static let inkHex = "#EDEFF2"
    /// #5C88E0
    static let accent = Color(red: 0.360784, green: 0.533333, blue: 0.878431)
    static let accentHex = "#5C88E0"
    /// #9B9DA1
    static let muted = Color(red: 0.607843, green: 0.615686, blue: 0.631373)
    static let mutedHex = "#9B9DA1"
    static let fontFamily = "Superclarendon"
}
