/// A 1-based line and column in a source file. Columns count characters.
public struct SourcePosition: Hashable, Sendable, Comparable {
    public var line: Int
    public var column: Int

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.line, lhs.column) < (rhs.line, rhs.column)
    }
}

/// One piece of a string literal's value: a character with its source position, or an interpolation.
enum LiteralPiece: Equatable {
    case character(Character, SourcePosition)
    case interpolation(SourcePosition)
}

struct StringLiteral: Equatable {
    var pieces: [LiteralPiece]
    var position: SourcePosition
}

enum TokenKind: Equatable {
    case identifier(String)
    case punctuation(Character)
    case string(StringLiteral)
    case other
}

struct Token: Equatable {
    var kind: TokenKind
    var position: SourcePosition

    var identifier: String? { if case .identifier(let name) = kind { name } else { nil } }
    var literal: StringLiteral? { if case .string(let literal) = kind { literal } else { nil } }
    func isPunctuation(_ character: Character) -> Bool { kind == .punctuation(character) }
}

/// Enough of Swift's lexical grammar to find string literals reliably: comments, escapes,
/// interpolation (including literals nested inside it), multiline strings, and raw strings.
struct SwiftLexer {
    private let characters: [Character]
    private var index = 0
    private var line = 1
    private var column = 1
    private(set) var tokens: [Token] = []
    /// Lines whose comments contain a suppression directive, and the lines they apply to.
    private(set) var ignoredLines: Set<Int> = []

    init(_ source: String) {
        characters = Array(source)
        lex()
    }

    private var position: SourcePosition { SourcePosition(line: line, column: column) }

    private func peek(_ offset: Int = 0) -> Character? {
        index + offset < characters.count ? characters[index + offset] : nil
    }

    private mutating func advance() {
        guard index < characters.count else { return }
        if characters[index].isNewline { line += 1; column = 1 } else { column += 1 }
        index += 1
    }

    private mutating func lex() {
        while let character = peek() {
            if character.isWhitespace { advance(); continue }
            if character == "/", peek(1) == "/" { lineComment(); continue }
            if character == "/", peek(1) == "*" { blockComment(); continue }
            if character == "#" || character == "\"", let literal = stringLiteral() {
                tokens.append(Token(kind: .string(literal), position: literal.position))
                continue
            }
            let start = position
            if character.isLetter || character == "_" || character == "$" {
                var name = ""
                while let next = peek(), next.isLetter || next.isNumber || next == "_" || next == "$" {
                    name.append(next); advance()
                }
                tokens.append(Token(kind: .identifier(name), position: start))
                continue
            }
            if character == "`" {
                advance()
                var name = ""
                while let next = peek(), next != "`", !next.isNewline { name.append(next); advance() }
                advance()
                tokens.append(Token(kind: .identifier(name), position: start))
                continue
            }
            if character.isNumber {
                while let next = peek(), next.isNumber || next.isLetter || next == "." || next == "_" { advance() }
                tokens.append(Token(kind: .other, position: start))
                continue
            }
            advance()
            tokens.append(Token(kind: .punctuation(character), position: start))
        }
    }

    private mutating func lineComment() {
        let commentLine = line
        var text = ""
        while let character = peek(), !character.isNewline { text.append(character); advance() }
        recordDirective(text, line: commentLine)
    }

    private mutating func blockComment() {
        let commentLine = line
        var depth = 0, text = ""
        repeat {
            if peek() == "/", peek(1) == "*" { depth += 1; advance(); advance(); continue }
            if peek() == "*", peek(1) == "/" { depth -= 1; advance(); advance(); continue }
            guard let character = peek() else { break }
            text.append(character)
            advance()
        } while depth > 0
        recordDirective(text, line: commentLine)
    }

    private mutating func recordDirective(_ comment: String, line commentLine: Int) {
        let text = comment.lowercased().replacingOccurrences(of: " ", with: "")
        if text.contains("swiftcn-lint:ignore-next-line") { ignoredLines.insert(commentLine + 1) }
        else if text.contains("swiftcn-lint:ignore") { ignoredLines.insert(commentLine) }
    }

    /// Lexes a string literal at the current position, or returns nil when `#` does not start one.
    private mutating func stringLiteral() -> StringLiteral? {
        var hashes = 0
        while peek(hashes) == "#" { hashes += 1 }
        guard peek(hashes) == "\"" else { return nil }
        let start = position
        for _ in 0..<hashes { advance() }
        let multiline = peek(1) == "\"" && peek(2) == "\""
        if multiline {
            advance(); advance(); advance()
        } else if peek(1) == "\"", peek(2) != "\"" {
            // An empty literal: "" (or #""#).
            advance(); advance()
            for _ in 0..<hashes where peek() == "#" { advance() }
            return StringLiteral(pieces: [], position: start)
        } else {
            advance()
        }
        var pieces: [LiteralPiece] = []
        while let character = peek() {
            if isClosingDelimiter(multiline: multiline, hashes: hashes) {
                for _ in 0..<(multiline ? 3 : 1) + hashes { advance() }
                break
            }
            if !multiline, character.isNewline { break }
            if character == "\\", (0..<hashes).allSatisfy({ peek(1 + $0) == "#" }) {
                let escapeStart = position
                for _ in 0...hashes { advance() }
                guard let escaped = peek() else { break }
                switch escaped {
                case "(":
                    pieces.append(.interpolation(escapeStart))
                    skipInterpolation()
                case "n": pieces.append(.character("\n", escapeStart)); advance()
                case "t": pieces.append(.character("\t", escapeStart)); advance()
                case "r": pieces.append(.character("\r", escapeStart)); advance()
                case "0": pieces.append(.character("\0", escapeStart)); advance()
                case "u":
                    advance()
                    var hex = ""
                    if peek() == "{" {
                        advance()
                        while let digit = peek(), digit != "}" { hex.append(digit); advance() }
                        advance()
                    }
                    if let value = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(value) {
                        pieces.append(.character(Character(scalar), escapeStart))
                    }
                default:
                    if escaped.isNewline { advance() } // Line continuation in a multiline literal.
                    else { pieces.append(.character(escaped, escapeStart)); advance() }
                }
                continue
            }
            pieces.append(.character(character, position))
            advance()
        }
        return StringLiteral(pieces: pieces, position: start)
    }

    private func isClosingDelimiter(multiline: Bool, hashes: Int) -> Bool {
        let quotes = multiline ? 3 : 1
        guard (0..<quotes).allSatisfy({ peek($0) == "\"" }) else { return false }
        return (0..<hashes).allSatisfy { peek(quotes + $0) == "#" }
    }

    /// Skips an interpolation's balanced parentheses, including nested literals and comments.
    private mutating func skipInterpolation() {
        advance() // "("
        var depth = 1
        while let character = peek(), depth > 0 {
            if character == "/", peek(1) == "/" { lineComment(); continue }
            if character == "/", peek(1) == "*" { blockComment(); continue }
            if character == "#" || character == "\"", stringLiteral() != nil { continue }
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
            advance()
        }
    }
}
