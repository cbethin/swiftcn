import SwiftUI

/// A bracket argument. Numeric helpers reject invalid, nonfinite, and unsupported unit values.
public struct TWArgument: Sendable, Equatable {
    public let rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue }

    public var number: Double? {
        let text = rawValue.trimmingCharacters(in: .whitespaces)
        let digits = text.first == "-" || text.first == "+" ? String(text.dropFirst()) : text
        guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }),
              let value = Double(text), value.isFinite else { return nil }
        return value
    }

    /// Bare numbers, pt, and px all represent native points, independent of the theme scale.
    public var points: CGFloat? {
        let text = rawValue.trimmingCharacters(in: .whitespaces)
        let value = text.hasSuffix("pt") || text.hasSuffix("px") ? String(text.dropLast(2)) : text
        return TWArgument(value).number.map { CGFloat($0) }
    }

    /// Bare numbers represent milliseconds. Explicit ms and s suffixes are also supported.
    public var seconds: TimeInterval? {
        let text = rawValue.trimmingCharacters(in: .whitespaces)
        if text.hasSuffix("ms") { return TWArgument(String(text.dropLast(2))).number.map { $0 / 1000 } }
        if text.hasSuffix("s") { return TWArgument(String(text.dropLast())).number }
        return number.map { $0 / 1000 }
    }

    /// Bare numbers and deg represent degrees; rad values are converted to degrees.
    public var degrees: Double? {
        let text = rawValue.trimmingCharacters(in: .whitespaces)
        let value: Double?
        if text.hasSuffix("deg") { value = TWArgument(String(text.dropLast(3))).number }
        else if text.hasSuffix("rad") { value = TWArgument(String(text.dropLast(3))).number.map { $0 * 180 / .pi } }
        else { value = number }
        return value.flatMap { $0.isFinite ? $0 : nil }
    }

    /// Comma-separated scalar arguments, for utilities such as offset-[12,-4].
    public var components: [TWArgument] {
        rawValue.split(separator: ",", omittingEmptySubsequences: false).map { TWArgument(String($0)) }
    }

    /// Resolve a CSS-order RGB/RGBA hex value. Theme colors use typed TWColor tokens instead.
    public var hexColor: Color? {
        guard rawValue.hasPrefix("#") else { return nil }
        let hex = String(rawValue.dropFirst())
        guard [3, 4, 6, 8].contains(hex.count), hex.allSatisfy({ $0.isASCII && $0.isHexDigit }) else { return nil }
        let expanded = hex.count <= 4 ? hex.map { "\($0)\($0)" }.joined() : hex
        guard let value = UInt64(expanded, radix: 16) else { return nil }
        let rgba = expanded.count == 8 ? value : (value << 8) | 255
        return Color(.sRGB, red: Double((rgba >> 24) & 255) / 255,
                     green: Double((rgba >> 16) & 255) / 255,
                     blue: Double((rgba >> 8) & 255) / 255, opacity: Double(rgba & 255) / 255)
    }
}

/// An application-defined argument utility. Return nil to reject an unsupported argument.
public struct TWUtility: Sendable {
    private let makeStyle: @Sendable (TWArgument, TWTheme) -> TWStyle?

    public init(_ makeStyle: @escaping @Sendable (TWArgument, TWTheme) -> TWStyle?) { self.makeStyle = makeStyle }

    func resolve(_ argument: TWArgument, theme: TWTheme) -> TWStyle? { makeStyle(argument, theme) }
}
