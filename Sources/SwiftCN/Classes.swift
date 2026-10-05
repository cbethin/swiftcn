import Foundation

/// Class syntax with typed interpolation payloads. Runtime Strings use the text parser.
public struct TWClasses: Sendable, ExpressibleByStringInterpolation, Equatable {
    var parts: [TWClassPart]

    public init(_ string: String) { parts = string.isEmpty ? [] : [.literal(string)] }
    public init(stringLiteral value: String) { self.init(value) }
    public init(stringInterpolation: StringInterpolation) { parts = stringInterpolation.parts }
    init(parts: [TWClassPart]) { self.parts = parts }

    public struct StringInterpolation: StringInterpolationProtocol {
        var parts: [TWClassPart] = []
        public init(literalCapacity: Int, interpolationCount: Int) { parts.reserveCapacity(interpolationCount * 2 + 1) }
        public mutating func appendLiteral(_ literal: String) { if !literal.isEmpty { parts.append(.literal(literal)) } }
        public mutating func appendInterpolation<Value: Sendable>(_ value: Value) {
            parts.append(.value(TWInterpolationValue(value)))
        }
        public mutating func appendInterpolation<Value: Sendable>(_ value: Value?) {
            parts.append(.value(TWInterpolationValue(value)))
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        if let left = try? lhs.tokens(), let right = try? rhs.tokens() { return left == right }
        return lhs.parts == rhs.parts
    }

    func tokens() throws -> [TWClassToken] {
        var compiler = TWClassCompiler()
        try compiler.append(parts)
        compiler.finish()
        return compiler.tokens
    }
}

enum TWClassPart: Sendable, Equatable {
    case literal(String)
    case value(TWInterpolationValue)
}

final class TWInterpolationValue: Sendable, Equatable {
    let value: any Sendable
    init<Value: Sendable>(_ value: Value) { self.value = value }
    static func == (lhs: TWInterpolationValue, rhs: TWInterpolationValue) -> Bool {
        if let equatable = lhs.value as? any Equatable { return equal(equatable, rhs.value) }
        return lhs === rhs
    }
    private static func equal<Value: Equatable>(_ lhs: Value, _ rhs: any Sendable) -> Bool {
        guard let rhs = rhs as? Value else { return false }
        return lhs == rhs
    }
}

struct TWClassToken: Equatable {
    let text: String
    let argument: TWArgument?
}

private struct TWClassCompiler {
    var tokens: [TWClassToken] = []
    private var text = ""
    private var argumentParts: [TWClassPart] = []
    private var depth = 0
    private var escaped = false
    private var typed = false

    mutating func append(_ parts: [TWClassPart]) throws {
        for part in parts {
            switch part {
            case .literal(let literal):
                for character in literal { append(character) }
            case .value(let box):
                if depth > 0 {
                    guard !escaped else { throw TWClassError.invalidInterpolation("an escaped argument") }
                    text += "<value>"
                    argumentParts.append(.value(box))
                    typed = true
                } else {
                    try fragment(box.value)
                }
            }
        }
    }

    private mutating func fragment(_ value: any Sendable) throws {
        switch value {
        case let value as TWClasses: try append(value.parts)
        case let value as String: try append([.literal(value)])
        case let value as any BinaryInteger: try append([.literal(String(describing: value))])
        case let value as any BinaryFloatingPoint: try append([.literal(String(describing: value))])
        case let value as [TWClasses?]:
            for (index, fragment) in value.compactMap({ $0 }).enumerated() {
                if index > 0 { append(" ") }
                try append(fragment.parts)
            }
        case let value as [String?]:
            for (index, fragment) in value.compactMap({ $0 }).enumerated() {
                if index > 0 { append(" ") }
                try append([.literal(fragment)])
            }
        case let value as TWClasses?: if let value { try append(value.parts) }
        case let value as String?: if let value { try append([.literal(value)]) }
        default: throw TWClassError.invalidInterpolation(String(reflecting: type(of: value)))
        }
    }

    private mutating func append(_ character: Character) {
        if character.isWhitespace {
            finish()
            return
        }
        text.append(character)
        if escaped {
            if depth > 0 { argumentParts.append(.literal(String(character))) }
            escaped = false
            return
        }
        if character == "\\" { escaped = true; return }
        if character == "[" {
            if depth > 0 { argumentParts.append(.literal("[")) }
            depth += 1
        } else if character == "]" {
            depth -= 1
            if depth > 0 { argumentParts.append(.literal("]")) }
        } else if depth > 0 {
            argumentParts.append(.literal(character == "_" ? " " : String(character)))
        }
    }

    mutating func finish() {
        if !text.isEmpty { tokens.append(TWClassToken(text: text, argument: typed ? TWArgument(parts: argumentParts) : nil)) }
        text = ""
        argumentParts = []
        depth = 0
        escaped = false
        typed = false
    }
}
