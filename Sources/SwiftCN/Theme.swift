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
    public var spacingUnit: CGFloat
    public var colors: [TWColor: TWAdaptiveColor]
    public var typography: [TWText: Font]
    public var radii: [TWRadius: CGFloat]
    public var shadows: [TWShadow: TWShadowValue]

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
        .foreground: .init(light: Color(white: 0.09), dark: Color(white: 0.96)),
        .mutedForeground: .init(light: Color(white: 0.43), dark: Color(white: 0.65)),
        .background: .init(light: Color(white: 0.98), dark: Color(white: 0.06)),
        .surface: .init(light: .white, dark: Color(white: 0.10)),
        .primary: .init(light: Color(white: 0.09), dark: Color(white: 0.96)),
        .onPrimary: .init(light: .white, dark: Color(white: 0.09)),
        .accent: .init(light: Color(white: 0.94), dark: Color(white: 0.17)),
        .onAccent: .init(light: Color(white: 0.09), dark: Color(white: 0.96)),
        .border: .init(light: Color(white: 0.88), dark: Color(white: 0.24)),
        .destructive: .init(light: Color(red: 0.78, green: 0.12, blue: 0.15), dark: Color(red: 1, green: 0.42, blue: 0.44)),
        .onDestructive: .init(light: .white, dark: Color(white: 0.06))
    ]
    private static let defaultTypography: [TWText: Font] = [
        .xs: .caption, .sm: .subheadline, .base: .body,
        .lg: .title3, .xl: .title2, .xxl: .title, .xxxl: .largeTitle
    ]
    private static let defaultRadii: [TWRadius: CGFloat] = [
        .none: 0, .sm: 4, .md: 8, .lg: 12, .xl: 16, .full: 10_000
    ]
    private static let defaultShadows: [TWShadow: TWShadowValue] = [
        .none: .init(color: .init(.clear), radius: 0),
        .sm: .init(color: .init(.black.opacity(0.08)), radius: 3, y: 1),
        .md: .init(color: .init(.black.opacity(0.12)), radius: 8, y: 3),
        .lg: .init(color: .init(.black.opacity(0.16)), radius: 16, y: 6)
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
