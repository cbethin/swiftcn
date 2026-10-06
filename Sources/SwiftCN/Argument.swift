import SwiftUI

/// A bracket argument. Numeric helpers reject invalid, nonfinite, and unsupported unit values.
public struct TWArgument: Sendable, Equatable {
    let parts: [TWClassPart]

    /// Text for legacy factories. Native payloads have a type label instead of a serialized value.
    public var rawValue: String {
        parts.map { part in
            switch part {
            case .literal(let value): return value
            case .value(let box):
                if let value = box.value as? String { return value }
                return "<\(String(reflecting: type(of: box.value)))>"
            }
        }.joined()
    }

    public init(_ rawValue: String) { self.init(parts: [.literal(rawValue)]) }
    init(parts: [TWClassPart]) {
        var normalized: [TWClassPart] = []
        for part in parts {
            if case .literal(let text) = part {
                guard !text.isEmpty else { continue }
                if case .literal(let previous) = normalized.last {
                    normalized[normalized.count - 1] = .literal(previous + text)
                } else { normalized.append(part) }
            } else { normalized.append(part) }
        }
        self.parts = normalized
    }

    /// Read an exact native value, or decode the standard scalar types from literal text.
    public func value<Value: Sendable>(as type: Value.Type = Value.self) -> Value? {
        if parts.count == 1, case .value(let box) = parts[0], let value = box.value as? Value {
            if let number = value as? any BinaryFloatingPoint, !Double(number).isFinite { return nil }
            if let angle = value as? Angle, !angle.degrees.isFinite { return nil }
            return value
        }
        if type == String.self { return literalText as? Value }
        if type == Double.self { return number as? Value }
        if type == CGFloat.self { return points as? Value }
        if type == Float.self, let number, Float(number).isFinite { return Float(number) as? Value }
        if type == Int.self {
            if let text = literalText { return Int(text) as? Value }
            return number.flatMap(Int.init(exactly:)) as? Value
        }
        if type == Angle.self { return degrees.map(Angle.degrees) as? Value }
        if type == Color.self { return hexColor as? Value }
        return nil
    }

    private var literalText: String? {
        var text = ""
        for part in parts {
            switch part {
            case .literal(let value): text += value
            case .value(let box):
                guard let value = box.value as? String else { return nil }
                text += value
            }
        }
        return text
    }

    private func scalar(units: [String: Double]) -> Double? {
        if let text = literalText {
            let text = text.trimmingCharacters(in: .whitespaces)
            let unit = units.keys.filter { !($0.isEmpty) }.sorted { $0.count > $1.count }.first { text.hasSuffix($0) } ?? ""
            guard let multiplier = units[unit] else { return nil }
            let digits = unit.isEmpty ? text : String(text.dropLast(unit.count))
            let unsigned = digits.first == "-" || digits.first == "+" ? String(digits.dropFirst()) : digits
            guard !unsigned.isEmpty, unsigned.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }),
                  let number = Double(digits), (number * multiplier).isFinite else { return nil }
            return number * multiplier
        }
        var value: Double?, prefix = "", suffix = ""
        for part in parts {
            switch part {
            case .literal(let text):
                if value == nil { prefix += text } else { suffix += text }
            case .value(let box):
                guard value == nil else { return nil }
                if let number = box.value as? any BinaryInteger { value = Double(number) }
                else if let number = box.value as? any BinaryFloatingPoint { value = Double(number) }
                else { return nil }
            }
        }
        guard prefix.trimmingCharacters(in: .whitespaces).isEmpty, let value,
              let multiplier = units[suffix.trimmingCharacters(in: .whitespaces)], (value * multiplier).isFinite else { return nil }
        return value * multiplier
    }

    public var number: Double? { scalar(units: ["": 1]) }
    /// Bare numbers, pt, and px represent native points, independent of the theme scale.
    public var points: CGFloat? { scalar(units: ["": 1, "pt": 1, "px": 1]).map { CGFloat($0) } }
    /// Bare numbers are milliseconds. Explicit ms and s suffixes are supported.
    public var seconds: TimeInterval? { scalar(units: ["": 0.001, "ms": 0.001, "s": 1]) }
    public var degrees: Double? {
        if parts.count == 1, case .value(let box) = parts[0], let angle = box.value as? Angle {
            return angle.degrees.isFinite ? angle.degrees : nil
        }
        return scalar(units: ["": 1, "deg": 1, "rad": 180 / .pi])
    }

    /// Comma-separated arguments preserve each interpolation payload independently.
    public var components: [TWArgument] {
        if parts.count == 1, case .value(let box) = parts[0] {
            if let point = box.value as? CGPoint {
                return [TWArgument(parts: [.value(TWInterpolationValue(point.x))]), TWArgument(parts: [.value(TWInterpolationValue(point.y))])]
            }
            if let size = box.value as? CGSize {
                return [TWArgument(parts: [.value(TWInterpolationValue(size.width))]), TWArgument(parts: [.value(TWInterpolationValue(size.height))])]
            }
        }
        var components: [[TWClassPart]] = [[]]
        for part in parts {
            let text: String?
            switch part {
            case .literal(let value): text = value
            case .value(let box): text = box.value as? String
            }
            if let text {
                for (index, piece) in text.split(separator: ",", omittingEmptySubsequences: false).enumerated() {
                    if index > 0 { components.append([]) }
                    components[components.count - 1].append(.literal(String(piece)))
                }
            } else { components[components.count - 1].append(part) }
        }
        return components.map { TWArgument(parts: $0) }
    }

    var hinted: (String?, TWArgument) {
        guard case .literal(let text) = parts.first, let colon = text.firstIndex(of: ":") else { return (nil, self) }
        let hint = String(text[..<colon])
        let remainder = String(text[text.index(after: colon)...])
        return (hint, TWArgument(parts: [.literal(remainder)] + parts.dropFirst()))
    }

    /// Decode RGB/RGBA hex text, or preserve an interpolated native Color.
    public var hexColor: Color? {
        if parts.count == 1, case .value(let box) = parts[0], let color = box.value as? Color { return color }
        guard let text = literalText, text.hasPrefix("#") else { return nil }
        let hex = String(text.dropFirst())
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
