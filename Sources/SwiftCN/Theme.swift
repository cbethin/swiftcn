import SwiftUI

public struct TWAdaptiveColor: Sendable {
    public var light: Color
    public var dark: Color

    public init(light: Color, dark: Color) {
        self.light = light
        self.dark = dark
    }

    public init(_ color: Color) { self.init(light: color, dark: color) }

    public func resolve(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? dark : light
    }
}

public struct TWShadowValue: Sendable {
    public var color: TWAdaptiveColor
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    public init(color: TWAdaptiveColor, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// Value-type design tokens. Changing this environment value updates its descendants.
public struct TWTheme: Sendable {
    public var spacingUnit: CGFloat { didSet { revision = TWRevision.next() } }
    public var colors: [TWColor: TWAdaptiveColor] { didSet { revision = TWRevision.next() } }
    public var typography: [TWText: Font] { didSet { revision = TWRevision.next() } }
    public var radii: [TWRadius: CGFloat] { didSet { revision = TWRevision.next() } }
    public var shadows: [TWShadow: TWShadowValue] { didSet { revision = TWRevision.next() } }
    /// Identifies this theme's content for cached class expansion. Copies share it.
    private(set) var revision: UInt64

    public init(
        spacingUnit: CGFloat = 4,
        colors: [TWColor: TWAdaptiveColor] = [:],
        typography: [TWText: Font] = [:],
        radii: [TWRadius: CGFloat] = [:],
        shadows: [TWShadow: TWShadowValue] = [:]
    ) {
        precondition(spacingUnit.isFinite && spacingUnit >= 0, "Spacing must be finite and nonnegative.")
        self.spacingUnit = spacingUnit
        self.colors = Self.defaultColors.merging(colors) { _, override in override }
        self.typography = Self.defaultTypography.merging(typography) { _, override in override }
        self.radii = Self.defaultRadii.merging(radii) { _, override in override }
        self.shadows = Self.defaultShadows.merging(shadows) { _, override in override }
        let isStandard = spacingUnit == 4 && colors.isEmpty && typography.isEmpty && radii.isEmpty && shadows.isEmpty
        self.revision = isStandard ? TWRevision.standard : TWRevision.next()
    }

    public static let standard = TWTheme()

    public func space(_ units: CGFloat) -> CGFloat { units * spacingUnit }

    /// Unregistered custom tokens fall back to SwiftUI's semantic primary foreground.
    public func color(_ token: TWColor, scheme: ColorScheme) -> Color {
        colors[token]?.resolve(scheme) ?? .primary
    }

    public func font(_ token: TWText) -> Font { typography[token] ?? .body }
    public func radius(_ token: TWRadius) -> CGFloat { radii[token] ?? 0 }
    public func shadow(_ token: TWShadow) -> TWShadowValue {
        shadows[token] ?? TWShadowValue(color: .init(.clear), radius: 0)
    }

    private static let defaultColors: [TWColor: TWAdaptiveColor] = [
        .foreground: .init(light: neutral(0.16), dark: neutral(0.91)),
        .mutedForeground: .init(light: neutral(0.42), dark: neutral(0.68)),
        .background: .init(light: neutral(0.98), dark: neutral(0.075)),
        .surface: .init(light: .white, dark: neutral(0.115)),
        .muted: .init(light: neutral(0.96), dark: neutral(0.145)),
        .primary: .init(light: neutral(0.18), dark: neutral(0.88)),
        .onPrimary: .init(light: .white, dark: neutral(0.115)),
        .accent: .init(light: neutral(0.935), dark: neutral(0.19)),
        .onAccent: .init(light: neutral(0.16), dark: neutral(0.91)),
        .border: .init(light: neutral(0.90), dark: neutral(0.22)),
        .input: .init(light: neutral(0.80), dark: neutral(0.34)),
        .ring: .init(.accentColor),
        .tint: .init(.accentColor),
        .destructive: .init(light: Color(red: 0.78, green: 0.12, blue: 0.15), dark: Color(red: 1, green: 0.42, blue: 0.44)),
        .onDestructive: .init(light: .white, dark: Color(white: 0.06))
    ]
    /// A restrained cool neutral keeps nested surfaces distinct without pure gray slabs.
    private static func neutral(_ value: Double) -> Color {
        Color(.sRGB, red: value, green: value, blue: min(1, value + 0.012), opacity: 1)
    }
    private static let defaultTypography: [TWText: Font] = [
        .xs: .caption, .sm: .subheadline, .base: .body,
        .lg: .title3, .xl: .title2, .xxl: .title, .xxxl: .largeTitle
    ]
    private static let defaultRadii: [TWRadius: CGFloat] = [
        .none: 0, .sm: 4, .md: 8, .lg: 12, .xl: 16, .full: 10_000
    ]
    private static let defaultShadows: [TWShadow: TWShadowValue] = [
        .none: .init(color: .init(.clear), radius: 0),
        .sm: .init(color: .init(light: .black.opacity(0.04), dark: .black.opacity(0.18)), radius: 3, y: 1),
        .md: .init(color: .init(light: .black.opacity(0.10), dark: .black.opacity(0.28)), radius: 12, y: 4),
        .lg: .init(color: .init(light: .black.opacity(0.14), dark: .black.opacity(0.36)), radius: 24, y: 8)
    ]
}

extension EnvironmentValues {
    @Entry public var twTheme: TWTheme = .standard
}

extension View {
    public func twTheme(_ theme: TWTheme) -> some View {
        environment(\.twTheme, theme)
    }
}
