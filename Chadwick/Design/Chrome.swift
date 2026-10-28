import SwiftUI

/// Section 7.4. Cards and sheets use `card`. Chips and small controls use `chip`.
enum Radius {
    static let card: CGFloat = 14
    static let chip: CGFloat = 6
}

/// Hairline plus flat fill. The only elevation.
enum Hairline {
    static let width: CGFloat = 1
}

enum Motion {
    static let stateChange = Animation.spring(.snappy)
    static let crossfade = Animation.easeOut(duration: 0.18)
}

struct HairlineFill: ViewModifier {
    var radius: CGFloat = Radius.card

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DesignTokens.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DesignTokens.muted, lineWidth: Hairline.width)
            }
    }
}

extension View {
    func hairlineFill(radius: CGFloat = Radius.card) -> some View {
        modifier(HairlineFill(radius: radius))
    }
}

/// Tinted glass for the live verb. Material stays in this style, not on every surface.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.body.weight(.semibold))
            .modifier(GlassChrome(isPressed: configuration.isPressed))
    }
}

private struct GlassChrome: ViewModifier {
    var isPressed: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isEnabled ? DesignTokens.ink : DesignTokens.muted)
            .frame(maxWidth: .infinity, minHeight: HitTarget.min)
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .background {
                if isEnabled {
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(.regularMaterial)
                } else {
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(DesignTokens.surface)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(DesignTokens.accent.opacity(isEnabled ? 0.22 : 0))
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(isEnabled ? DesignTokens.accent : DesignTokens.muted, lineWidth: Hairline.width)
            }
            .scaleEffect(isPressed && isEnabled && !reduceMotion ? 0.98 : 1)
            .opacity(isPressed && isEnabled ? 0.8 : 1)
            .animation(reduceMotion ? nil : Motion.stateChange, value: isPressed)
    }
}

/// Same radius and hairline, without the accent. Reset and quiet actions use this.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.body.weight(.semibold))
            .modifier(QuietChrome(isPressed: configuration.isPressed))
    }
}

private struct QuietChrome: ViewModifier {
    var isPressed: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isEnabled ? DesignTokens.ink : DesignTokens.muted)
            .frame(maxWidth: .infinity, minHeight: HitTarget.min)
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(DesignTokens.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(DesignTokens.muted, lineWidth: Hairline.width)
            }
            .scaleEffect(isPressed && isEnabled && !reduceMotion ? 0.98 : 1)
            .opacity(!isEnabled ? 0.55 : (isPressed ? 0.75 : 1))
            .animation(reduceMotion ? nil : Motion.stateChange, value: isPressed)
    }
}

struct PressOpacityStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.55 : 1)
            .frame(minWidth: HitTarget.min, minHeight: HitTarget.min)
    }
}

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(TypeScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.ink)
                .frame(width: HitTarget.min, height: HitTarget.min)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
        .accessibilityLabel("Close")
    }
}

struct SheetChrome<Content: View>: View {
    let title: String
    var showsClose: Bool
    let close: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(DesignTokens.bg)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(DesignTokens.bg, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(TypeScale.title)
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if showsClose {
                        ToolbarItem(placement: .cancellationAction) {
                            CloseButton(action: close)
                        }
                    }
                }
        }
        .tint(DesignTokens.accent)
    }
}

enum ContactPage {
    static let address = "https://chadwick-coupon.pro/contact-us"
    static var url: URL? { URL(string: address) }
}
