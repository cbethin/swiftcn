import SwiftUI

/// A semantic color name. Extend this type with tokens from your own theme.
public struct TWColor: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ name: String) { self.rawValue = name }

    public static let foreground = Self("foreground")
    public static let mutedForeground = Self("mutedForeground")
    public static let background = Self("background")
    public static let surface = Self("surface")
    public static let primary = Self("primary")
    public static let onPrimary = Self("onPrimary")
    public static let accent = Self("accent")
    public static let onAccent = Self("onAccent")
    public static let border = Self("border")
    public static let destructive = Self("destructive")
    public static let onDestructive = Self("onDestructive")
}

public enum TWText: CaseIterable, Hashable, Sendable {
    case xs, sm, base, lg, xl, xxl, xxxl
}

public enum TWRadius: CaseIterable, Hashable, Sendable {
    case none, sm, md, lg, xl, full
}

public enum TWShadow: CaseIterable, Hashable, Sendable {
    case none, sm, md, lg
}

/// Explicit state supplied by the caller. General view styling never recognizes presses.
public struct TWState: Equatable, Sendable {
    public var isHovered: Bool
    public var isFocused: Bool
    public var isPressed: Bool
    public var isDisabled: Bool

    public init(
        isHovered: Bool = false,
        isFocused: Bool = false,
        isPressed: Bool = false,
        isDisabled: Bool = false
    ) {
        self.isHovered = isHovered
        self.isFocused = isFocused
        self.isPressed = isPressed
        self.isDisabled = isDisabled
    }
}
