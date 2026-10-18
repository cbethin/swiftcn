import Foundation
import SwiftUI
@_spi(Tooling) import SwiftCN

public struct LintDiagnostic: Hashable, Sendable, Codable {
    public enum Severity: String, Sendable, Codable { case error, warning }

    public var path: String
    public var line: Int
    public var column: Int
    public var severity: Severity
    public var message: String
    /// The class as written, such as `hover:bg-surfce`.
    public var token: String
    /// A replacement for `token`, when a known class is close.
    public var suggestion: String?

    /// The form Xcode and SwiftPM show inline: `path:line:column: error: message`.
    public var xcodeFormatted: String {
        "\(path):\(line):\(column): \(severity.rawValue): \(message) [swiftcn-lint]"
    }
}

/// Names that an app registers at runtime, which the parser cannot see in source.
public struct LintConfiguration: Sendable, Codable, Equatable {
    /// Exact class names, such as named recipes and native modifier tags.
    public var classes: [String]
    /// Prefixes of custom argument utilities, such as `tilt` for `tilt-[8deg]`.
    public var prefixes: [String]
    /// Custom animation presets, used as `animate-{name}`.
    public var animations: [String]
    /// Custom theme colors, used as `text-{name}`, `bg-{name}`, and the other color prefixes.
    public var colors: [String]
    /// Report problems as warnings instead of errors.
    public var warningsOnly: Bool

    public init(classes: [String] = [], prefixes: [String] = [], animations: [String] = [], colors: [String] = [],
                warningsOnly: Bool = false) {
        self.classes = classes
        self.prefixes = prefixes
        self.animations = animations
        self.colors = colors
        self.warningsOnly = warningsOnly
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        classes = try container.decodeIfPresent([String].self, forKey: .classes) ?? []
        prefixes = try container.decodeIfPresent([String].self, forKey: .prefixes) ?? []
        animations = try container.decodeIfPresent([String].self, forKey: .animations) ?? []
        colors = try container.decodeIfPresent([String].self, forKey: .colors) ?? []
        warningsOnly = try container.decodeIfPresent(Bool.self, forKey: .warningsOnly) ?? false
    }
}

/// Finds swiftcn class strings in Swift source and validates each class with the swiftcn parser.
public struct SwiftCNLinter {
    public private(set) var configuration: LintConfiguration
    private var learnedNamed: Set<String> = []
    private var learnedPrefixes: Set<String> = []
    private var learnedAnimations: Set<String> = []
    private var learnedColors: Set<String> = []

    public init(configuration: LintConfiguration = LintConfiguration()) {
        self.configuration = configuration
    }

    /// Records the recipes, modifiers, utilities, and animations that these sources register,
    /// so classes that use them are not reported. Call it with every file before linting.
    public mutating func learn(from source: String) {
        let tokens = SwiftLexer(source).tokens
        for (index, token) in tokens.enumerated() {
            // `TWColor("brand")` and `TWColor(rawValue: "brand")` declare custom theme colors.
            if token.identifier == "TWColor", index + 2 < tokens.count, tokens[index + 1].isPunctuation("(") {
                let offset = tokens[index + 2].identifier == "rawValue" ? 4 : 2
                if index + offset < tokens.count, let literal = tokens[index + offset].literal, let name = plainText(literal) {
                    learnedColors.insert(name)
                }
            }
            guard let name = token.identifier, let kind = RuleKind(rawValue: name) else { continue }
            // `named: [...]` and the other initializer labels.
            if index + 2 < tokens.count, tokens[index + 1].isPunctuation(":"), tokens[index + 2].isPunctuation("[") {
                for key in dictionaryEntries(tokens, openingBracket: index + 2).map(\.key) { record(key, as: kind) }
            }
            // `rules.named["card"] = ...` and `$0.modifiers["tilt"] = ...`.
            if index > 0, tokens[index - 1].isPunctuation("."), index + 3 < tokens.count,
               tokens[index + 1].isPunctuation("["), let key = tokens[index + 2].literal, tokens[index + 3].isPunctuation("]"),
               let text = plainText(key) {
                record(text, as: kind)
            }
        }
    }

    /// Returns a diagnostic for each class that the swiftcn parser rejects.
    public func lint(source: String, path: String) -> [LintDiagnostic] {
        let lexer = SwiftLexer(source)
        let tokens = lexer.tokens
        var literals: [StringLiteral] = []
        for index in tokens.indices {
            literals += classLiterals(tokens, at: index)
        }
        var diagnostics: [LintDiagnostic] = []
        var seen: Set<SourcePosition> = []
        for literal in literals where seen.insert(literal.position).inserted {
            diagnostics += validate(literal, path: path)
        }
        return diagnostics
            .filter { !lexer.ignoredLines.contains($0.line) }
            .sorted { ($0.line, $0.column) < ($1.line, $1.column) }
    }

    /// The rules the linter validates against: swiftcn's defaults, component modifiers, and every
    /// name learned from source or listed in the configuration.
    public var rules: TWGlobalRules {
        var rules = TWClassCatalog.componentRules
        for name in learnedNamed.union(configuration.classes) where rules.named[name] == nil {
            rules.named[name] = TWStyle()
        }
        for prefix in learnedPrefixes.union(configuration.prefixes) where rules.utilities[prefix] == nil {
            rules.utilities[prefix] = TWUtility { _, _ in TWStyle() }
        }
        for name in learnedAnimations.union(configuration.animations) where rules.animations[name] == nil {
            rules.animations[name] = TWAnimation(.default)
        }
        return rules
    }

    /// The standard theme with every learned or configured color registered.
    public var theme: TWTheme {
        var theme = TWTheme.standard
        for name in learnedColors.union(configuration.colors) where theme.colors[TWColor(name)] == nil {
            theme.colors[TWColor(name)] = TWAdaptiveColor(.clear)
        }
        return theme
    }

    // MARK: - Finding class strings

    private enum RuleKind: String { case named, replacing, modifiers, utilities, animations }

    private mutating func record(_ name: String, as kind: RuleKind) {
        switch kind {
        case .named, .replacing: learnedNamed.insert(name)
        case .animations: learnedAnimations.insert(name)
        case .modifiers, .utilities:
            // Registrations can be exact tags, argument prefixes, or both.
            learnedNamed.insert(name)
            learnedPrefixes.insert(name)
        }
    }

    /// String literals that hold classes, starting at this token.
    private func classLiterals(_ tokens: [Token], at index: Int) -> [StringLiteral] {
        let token = tokens[index]
        func at(_ offset: Int) -> Token? { tokens.indices.contains(index + offset) ? tokens[index + offset] : nil }
        func isWholeArgument(_ offset: Int) -> Bool {
            guard let next = at(offset + 1) else { return false }
            return next.isPunctuation(",") || next.isPunctuation(")") || next.isPunctuation("]")
        }

        // Styled surfaces, containers, animation scopes, and named styles.
        if token.isPunctuation("."), let name = at(1)?.identifier, ["tw", "twAnimation", "classes"].contains(name),
           at(2)?.isPunctuation("(") == true, let literal = at(3)?.literal, isWholeArgument(3) {
            return [literal]
        }
        // `cn("…", condition ? "…" : nil)`: each argument that is a single literal.
        if token.identifier == "cn", index == 0 || !tokens[index - 1].isPunctuation("."), at(1)?.isPunctuation("(") == true {
            return callArguments(tokens, openingParenthesis: index + 1)
        }
        // `classes: "…"` arguments on components.
        if token.identifier == "classes", at(1)?.isPunctuation(":") == true, let literal = at(2)?.literal, isWholeArgument(2) {
            return [literal]
        }
        // `let style: TWClasses = "…"` and `TWStyle`.
        if let name = token.identifier, ["TWClasses", "TWStyle"].contains(name), index > 0, tokens[index - 1].isPunctuation(":"),
           at(1)?.isPunctuation("=") == true, let literal = at(2)?.literal {
            if let next = at(3), next.isPunctuation("+") { return [] }
            return [literal]
        }
        // Recipe values: `named: ["motion-card": "card animate-settle"]`.
        if ["named", "replacing"].contains(token.identifier ?? ""), at(1)?.isPunctuation(":") == true, at(2)?.isPunctuation("[") == true {
            return dictionaryEntries(tokens, openingBracket: index + 2).compactMap(\.value)
        }
        return []
    }

    /// Literal arguments of a call, skipping arguments that are expressions.
    private func callArguments(_ tokens: [Token], openingParenthesis: Int) -> [StringLiteral] {
        var result: [StringLiteral] = []
        var depth = 0, argumentStart = openingParenthesis + 1
        for index in openingParenthesis..<tokens.count {
            let token = tokens[index]
            if token.isPunctuation("(") || token.isPunctuation("[") || token.isPunctuation("{") { depth += 1 }
            let closes = token.isPunctuation(")") || token.isPunctuation("]") || token.isPunctuation("}")
            if closes { depth -= 1 }
            if depth == 1 && token.isPunctuation(",") || depth == 0 && closes {
                if index - argumentStart == 1, let literal = tokens[argumentStart].literal { result.append(literal) }
                argumentStart = index + 1
            }
            if depth == 0 { break }
        }
        return result
    }

    /// Keys of a dictionary literal, with values that are single literals.
    private func dictionaryEntries(_ tokens: [Token], openingBracket: Int) -> [(key: String, value: StringLiteral?)] {
        var entries: [(String, StringLiteral?)] = []
        var depth = 0
        var index = openingBracket
        while index < tokens.count {
            let token = tokens[index]
            if token.isPunctuation("(") || token.isPunctuation("[") || token.isPunctuation("{") { depth += 1 }
            if token.isPunctuation(")") || token.isPunctuation("]") || token.isPunctuation("}") {
                depth -= 1
                if depth == 0 { break }
            }
            if depth == 1, let key = token.literal, index + 1 < tokens.count, tokens[index + 1].isPunctuation(":"),
               let text = plainText(key) {
                var value: StringLiteral?
                if index + 3 < tokens.count, let literal = tokens[index + 2].literal,
                   tokens[index + 3].isPunctuation(",") || tokens[index + 3].isPunctuation("]") {
                    value = literal
                }
                entries.append((text, value))
            }
            index += 1
        }
        return entries
    }

    private func plainText(_ literal: StringLiteral) -> String? {
        var text = ""
        for piece in literal.pieces {
            guard case .character(let character, _) = piece else { return nil }
            text.append(character)
        }
        return text
    }

    // MARK: - Validation

    private struct ClassToken {
        var text = ""
        var position: SourcePosition?
        var hasInterpolation = false
        var interpolatedOutsideBrackets = false
        var bracketDepth = 0
    }

    private func validate(_ literal: StringLiteral, path: String) -> [LintDiagnostic] {
        var tokens: [ClassToken] = []
        var current = ClassToken()
        func finish() {
            if !current.text.isEmpty || current.hasInterpolation { tokens.append(current) }
            current = ClassToken()
        }
        for piece in literal.pieces {
            switch piece {
            case .character(let character, let position):
                if character.isWhitespace { finish(); continue }
                if current.position == nil { current.position = position }
                if character == "[" { current.bracketDepth += 1 }
                if character == "]" { current.bracketDepth -= 1 }
                current.text.append(character)
            case .interpolation(let position):
                if current.position == nil { current.position = position }
                current.hasInterpolation = true
                if current.bracketDepth <= 0 { current.interpolatedOutsideBrackets = true }
                // A placeholder keeps the token's shape for prefix checks.
                current.text.append("\u{FFFC}")
            }
        }
        finish()

        let rules = rules
        let theme = theme
        let severity: LintDiagnostic.Severity = configuration.warningsOnly ? .warning : .error
        var diagnostics: [LintDiagnostic] = []
        for token in tokens {
            // A runtime fragment outside brackets can hold any classes; it is checked at run time.
            guard !token.interpolatedOutsideBrackets, let position = token.position else { continue }
            let problem = token.hasInterpolation
                ? checkInterpolatedArgument(token.text, rules: rules)
                : checkClass(token.text, rules: rules, theme: theme)
            guard let problem else { continue }
            func readable(_ text: String) -> String { text.replacingOccurrences(of: "\u{FFFC}", with: "\\(…)") }
            diagnostics.append(LintDiagnostic(path: path, line: position.line, column: position.column,
                                              severity: severity, message: readable(problem.message),
                                              token: readable(token.text), suggestion: problem.suggestion.map(readable)))
        }
        return diagnostics
    }

    private struct Problem {
        var message: String
        var suggestion: String?
    }

    private var customNames: [String] {
        Array(learnedNamed.union(configuration.classes))
            + learnedAnimations.union(configuration.animations).map { "animate-\($0)" }
            + learnedColors.union(configuration.colors).flatMap { color in
                ["text-", "bg-", "border-", "tint-", "glass-tint-"].map { $0 + color }
            }
    }

    private func checkClass(_ text: String, rules: TWGlobalRules, theme: TWTheme) -> Problem? {
        do {
            _ = try TWStyle.parse(text, rules: rules, theme: theme)
            return nil
        } catch let error as TWClassError {
            let parts = splitVariants(text)
            let name = parts.last ?? text
            switch error {
            case .unknownVariant(let variant):
                let fixed = TWClassCatalog.variantSuggestion(for: variant)
                    .map { replacement in parts.map { $0 == variant ? replacement : $0 }.joined(separator: ":") }
                return Problem(message: "Unknown swiftcn variant '\(variant):' in '\(text)'." + didYouMean(fixed), suggestion: fixed)
            case .unknownClass(let unknown) where unknown == name || unknown == text:
                if let prefix = argumentPrefix(name), knownPrefixes(rules).contains(prefix) {
                    return Problem(message: "swiftcn can't use '\(name.dropFirst(prefix.count + 1))' as a value for \(prefix)-[…] in '\(text)'.")
                }
                let fixed = TWClassCatalog.suggestion(for: text, extraNames: customNames)
                return Problem(message: "Unknown swiftcn class '\(text)'." + didYouMean(fixed), suggestion: fixed)
            case .unknownClass(let unknown):
                return Problem(message: "Unknown swiftcn class '\(unknown)', used by '\(text)'.")
            default:
                return Problem(message: "\(error.description) in '\(text)'.")
            }
        } catch {
            return Problem(message: "swiftcn rejected '\(text)': \(error).")
        }
    }

    /// For a class with a typed interpolation inside brackets, only the variants and prefix can be checked.
    private func checkInterpolatedArgument(_ text: String, rules: TWGlobalRules) -> Problem? {
        let parts = splitVariants(text)
        for variant in parts.dropLast() where !isKnownVariant(variant) {
            let fixed = TWClassCatalog.variantSuggestion(for: variant)
                .map { replacement in parts.map { $0 == variant ? replacement : $0 }.joined(separator: ":") }
            return Problem(message: "Unknown swiftcn variant '\(variant):'." + didYouMean(fixed), suggestion: fixed)
        }
        guard let name = parts.last, let prefix = argumentPrefix(name) else {
            return Problem(message: "swiftcn interpolation belongs inside brackets, as in bg-[\\(color)].")
        }
        guard !knownPrefixes(rules).contains(prefix) else { return nil }
        let fixedPrefix = TWClassCatalog.closest(to: prefix, in: Array(knownPrefixes(rules)))
        let fixed = fixedPrefix.map { (parts.dropLast() + [$0 + name.dropFirst(prefix.count)]).joined(separator: ":") }
        return Problem(message: "Unknown swiftcn argument prefix '\(prefix)-[…]'." + didYouMean(fixedPrefix.map { "\($0)-[…]" }),
                       suggestion: fixed)
    }

    private func knownPrefixes(_ rules: TWGlobalRules) -> Set<String> {
        Set(TWClassCatalog.argumentPrefixes).union(rules.utilities.keys).union(rules.modifiers.keys)
    }

    private func isKnownVariant(_ variant: String) -> Bool {
        let pieces = variant.split(separator: "/", omittingEmptySubsequences: false)
        guard pieces.count <= 2, TWClassCatalog.variants.contains(String(pieces[0])) else { return false }
        return pieces.count == 1 || (pieces[0].hasPrefix("group-") && !pieces[1].isEmpty)
    }

    private func argumentPrefix(_ name: String) -> String? {
        guard let opening = name.range(of: "-["), name.hasSuffix("]") else { return nil }
        return String(name[..<opening.lowerBound])
    }

    private func splitVariants(_ text: String) -> [String] {
        var parts: [String] = [], part = "", depth = 0
        for character in text {
            if character == "[" { depth += 1 }
            if character == "]" { depth -= 1 }
            if character == ":", depth == 0 { parts.append(part); part = "" } else { part.append(character) }
        }
        parts.append(part)
        return parts
    }

    private func didYouMean(_ suggestion: String?) -> String {
        suggestion.map { " Did you mean '\($0)'?" } ?? ""
    }
}
