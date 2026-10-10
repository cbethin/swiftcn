import SwiftUI

public enum TWClassError: Error, Equatable, CustomStringConvertible {
    case unknownClass(String)
    case unknownVariant(String)
    case recursiveClass(String)
    case expansionLimit
    case invalidInterpolation(String)
    case unsupportedTarget(String, expected: TWTarget)

    public var description: String {
        switch self {
        case .unknownClass(let name): "Unknown swiftcn class: \(name)"
        case .unknownVariant(let name): "Unknown swiftcn variant: \(name)"
        case .recursiveClass(let name): "Recursive swiftcn class: \(name)"
        case .expansionLimit: "swiftcn class expansion exceeds 32 levels"
        case .unsupportedTarget(let name, let target): "swiftcn class \(name) requires .tw directly on a native \(target.rawValue)"
        case .invalidInterpolation(let type): "Unsupported swiftcn interpolation: \(type)"
        }
    }
}

enum TWClassParser {
    // These tables do not depend on the theme, registry, or interpolated values.
    private static let fonts: [String: TWText] = ["xs": .xs, "sm": .sm, "base": .base, "lg": .lg,
                                                 "xl": .xl, "2xl": .xxl, "3xl": .xxxl]
    private static let weights: [String: Font.Weight] = ["regular": .regular, "normal": .regular, "medium": .medium,
                                                       "semibold": .semibold, "bold": .bold, "light": .light]
    private static let radii: [String: TWRadius] = ["none": .none, "sm": .sm, "md": .md, "lg": .lg, "xl": .xl, "full": .full]
    private static let shadows: [String: TWShadow] = ["none": .none, "sm": .sm, "md": .md, "lg": .lg]
    private static let aliases: [String: TWColor] = ["primary-foreground": .onPrimary, "accent-foreground": .onAccent,
                                                   "destructive-foreground": .onDestructive, "card": .surface,
                                                   "card-foreground": .foreground, "muted-foreground": .mutedForeground]

    static func expand(_ style: TWStyle, rules: TWGlobalRules, theme: TWTheme,
                       stack: [String] = [], depth: Int = 0, target: TWTarget? = nil) throws -> TWStyle {
        guard depth < 32 else { throw TWClassError.expansionLimit }
        var result: [TWRule] = []
        for rule in style.rules {
            let tokens: [TWClassToken]
            switch rule.property {
            case .classes(let classes):
                tokens = classes.split(whereSeparator: { $0.isWhitespace }).map { TWClassToken(text: String($0), argument: nil) }
            case .interpolated(let classes): tokens = try classes.tokens()
            default:
                if case .native(let name, let argument) = rule.property {
                    guard let utility = rules.modifiers[name], utility.validate(argument, theme: theme) else {
                        throw TWClassError.unknownClass(name)
                    }
                    if let target, utility.target != .view && utility.target != target {
                        throw TWClassError.unsupportedTarget(name, expected: utility.target)
                    }
                }
                result.append(rule)
                continue
            }
            for token in tokens {
                let tokenRules: [TWRule]
                // Top-level literal tokens depend only on their text, target, rules, and theme.
                if stack.isEmpty, depth == 0, token.argument == nil {
                    let key = TWExpansionCache.Key(token: token.text, target: target,
                                                   rules: rules.revision, theme: theme.revision)
                    if let cached = TWExpansionCache.shared.rules(for: key) {
                        tokenRules = cached
                    } else {
                        tokenRules = try expandToken(token, rules: rules, theme: theme, stack: stack, depth: depth, target: target)
                        TWExpansionCache.shared.insert(tokenRules, for: key)
                    }
                } else {
                    tokenRules = try expandToken(token, rules: rules, theme: theme, stack: stack, depth: depth, target: target)
                }
                if rule.conditions.isEmpty, rule.groupConditions.isEmpty {
                    result += tokenRules
                } else {
                    result += tokenRules.map {
                        var value = $0
                        value.conditions.formUnion(rule.conditions)
                        value.groupConditions.formUnion(rule.groupConditions)
                        return value
                    }
                }
            }
        }
        return TWStyle(rules: result)
    }

    /// Expand one class token, applying only the variants written on the token itself.
    private static func expandToken(_ token: TWClassToken, rules: TWGlobalRules, theme: TWTheme,
                                    stack: [String], depth: Int, target: TWTarget?) throws -> [TWRule] {
        let parts = try variants(token.text)
        let name = parts.last!
        var conditions: Set<TWCondition> = []
        var groupConditions: Set<TWGroupCondition> = []
        for variant in parts.dropLast() {
            if variant.hasPrefix("group-") {
                let pieces = variant.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
                guard pieces.count <= 2, pieces.count == 1 || identifier(pieces[1]),
                      let condition = groupCondition(pieces[0]) else {
                    throw TWClassError.unknownVariant(variant)
                }
                groupConditions.insert(TWGroupCondition(name: pieces.count == 2 ? pieces[1] : nil, condition: condition))
                continue
            }
            switch variant {
            case "hover": conditions.insert(.hovered)
            case "focus": conditions.insert(.focused)
            case "active", "pressed": conditions.insert(.pressed)
            case "disabled": conditions.insert(.disabled)
            default: throw TWClassError.unknownVariant(variant)
            }
        }
        let expanded: TWStyle
        if token.argument == nil, let named = rules.named[name] ?? TWStyle.defaultClasses[name] {
            guard !stack.contains(name) else { throw TWClassError.recursiveClass(name) }
            expanded = try expand(named, rules: rules, theme: theme, stack: stack + [name], depth: depth + 1, target: target)
        } else {
            guard let utility = utility(name, suppliedArgument: token.argument, theme: theme, rules: rules) else { throw TWClassError.unknownClass(name) }
            guard !stack.contains(name) else { throw TWClassError.recursiveClass(name) }
            expanded = try expand(utility, rules: rules, theme: theme, stack: stack + [name], depth: depth + 1, target: target)
        }
        guard !conditions.isEmpty || !groupConditions.isEmpty else { return expanded.rules }
        return expanded.rules.map {
            var value = $0
            value.conditions.formUnion(conditions)
            value.groupConditions.formUnion(groupConditions)
            return value
        }
    }

    private static func utility(_ name: String, suppliedArgument: TWArgument?, theme: TWTheme, rules: TWGlobalRules) -> TWStyle? {
        if let native = rules.modifiers[name] {
            guard native.validate(nil, theme: theme) else { return nil }
            return TWStyle(rules: [TWRule(property: .native(name, nil))])
        }
        if name == "group" { return TWStyle(rules: [TWRule(property: .group(""))]) }
        if name.hasPrefix("group/"), identifier(String(name.dropFirst(6))) {
            return TWStyle(rules: [TWRule(property: .group(String(name.dropFirst(6))))])
        }
        if name.hasPrefix("shared-[") {
            let pieces = name.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
            guard pieces.count <= 2, pieces[0].hasSuffix("]"),
                  pieces.count == 1 || identifier(pieces[1]) else { return nil }
            let id: String
            if let suppliedArgument {
                guard let value = suppliedArgument.value(as: String.self) else { return nil }
                id = value
            } else { id = String(pieces[0].dropFirst(8).dropLast()) }
            guard identifier(id) else { return nil }
            return TWStyle(rules: [TWRule(property: .sharedID(id, group: pieces.count == 2 ? pieces[1] : nil))])
        }
        switch name {
        case "shared-frame": return TWStyle(rules: [TWRule(property: .sharedProperties(.frame))])
        case "shared-position": return TWStyle(rules: [TWRule(property: .sharedProperties(.position))])
        case "shared-size": return TWStyle(rules: [TWRule(property: .sharedProperties(.size))])
        case "shared-source": return TWStyle(rules: [TWRule(property: .sharedSource(true))])
        case "shared-follower": return TWStyle(rules: [TWRule(property: .sharedSource(false))])
        default: break
        }
        if let (prefix, decoded) = argument(name) {
            let argument = suppliedArgument ?? decoded
            if let native = rules.modifiers[prefix] {
                guard native.validate(argument, theme: theme) else { return nil }
                return TWStyle(rules: [TWRule(property: .native(prefix, argument))])
            }
            if let custom = rules.utilities[prefix] { return custom.resolve(argument, theme: theme) }
            return TWArgumentUtilities.resolve(prefix, argument: argument, theme: theme)
        }
        switch name {
        case "text-center": return .textAlignment(.center)
        case "text-start": return .textAlignment(.leading)
        case "text-end": return .textAlignment(.trailing)
        case "line-clamp-none": return .lineLimit(nil)
        default: break
        }
        if name.hasPrefix("line-clamp-"), let count = Int(name.dropFirst(11)), count > 0 { return .lineLimit(count) }
        if name.hasPrefix("animate-") {
            guard let preset = rules.animations[String(name.dropFirst("animate-".count))] else { return nil }
            return .animation(preset)
        }
        for prefix in ["duration-", "delay-"] where name.hasPrefix(prefix) {
            guard let milliseconds = nonnegative(String(name.dropFirst(prefix.count))) else { return nil }
            let seconds = Double(milliseconds) / 1000
            return prefix == "duration-" ? .duration(seconds) : .delay(seconds)
        }
        if name == "w-full" { return .fullWidth }
        if name == "border" { return .border(.border) }
        if name == "rounded" { return .rounded(.md) }
        if name == "shadow" { return .shadow(.sm) }
        func color(_ value: String) -> TWColor? {
            let token = aliases[value] ?? TWColor(value)
            return theme.colors[token] == nil ? nil : token
        }
        for prefix in ["text-", "bg-", "border-", "rounded-", "shadow-", "font-"] where name.hasPrefix(prefix) {
            let value = String(name.dropFirst(prefix.count))
            switch prefix {
            case "text-":
                if let font = fonts[value] { return .text(font) }
                if let token = color(value) { return .fg(token) }
            case "bg-": if let token = color(value) { return .bg(token) }
            case "border-":
                if let number = nonnegative(value) { return TWStyle(rules: [TWRule(property: .borderWidth(number))]) }
                if let token = color(value) { return TWStyle(rules: [TWRule(property: .borderColor(.token(token)))]) }
            case "rounded-": if let radius = radii[value] { return .rounded(radius) }
            case "shadow-": if let shadow = shadows[value] { return .shadow(shadow) }
            case "font-": if let weight = weights[value] { return .weight(weight) }
            default: break
            }
            return nil
        }
        for prefix in ["min-h-", "opacity-", "px-", "py-", "pt-", "pb-", "ps-", "pe-", "pl-", "pr-", "p-", "w-", "h-"] {
            guard name.hasPrefix(prefix), let number = nonnegative(String(name.dropFirst(prefix.count))) else { continue }
            guard theme.space(number).isFinite else { return nil }
            switch prefix {
            case "p-": return .p(number)
            case "px-": return .px(number)
            case "py-": return .py(number)
            case "pt-": return .pt(number)
            case "pb-": return .pb(number)
            case "ps-", "pl-": return .ps(number)
            case "pe-", "pr-": return .pe(number)
            case "w-": return .w(theme.space(number))
            case "h-": return .h(theme.space(number))
            case "min-h-": return .minH(theme.space(number))
            case "opacity-": return number <= 100 ? .opacity(Double(number / 100)) : nil
            default: break
            }
        }
        return nil
    }

    private static func nonnegative(_ text: String) -> CGFloat? {
        // Restrict the grammar to decimal digits and one optional decimal point.
        guard !text.isEmpty, text.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }),
              let value = Double(text), value.isFinite, value >= 0 else { return nil }
        return CGFloat(value)
    }

    private static func identifier(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0)) }
    }

    private static func variants(_ token: String) throws -> [String] {
        var parts: [String] = [], part = "", depth = 0, escaped = false
        for character in token {
            if escaped { part.append(character); escaped = false; continue }
            if character == "\\" { part.append(character); escaped = true; continue }
            if character == "[" { depth += 1 }
            if character == "]" {
                depth -= 1
                guard depth >= 0 else { throw TWClassError.unknownClass(token) }
            }
            if character == ":", depth == 0 { parts.append(part); part = "" }
            else { part.append(character) }
        }
        guard depth == 0, !escaped else { throw TWClassError.unknownClass(token) }
        parts.append(part)
        return parts
    }

    private static func argument(_ token: String) -> (String, TWArgument)? {
        guard let opening = token.range(of: "-["), token.hasSuffix("]") else { return nil }
        let prefix = String(token[..<opening.lowerBound])
        guard identifier(prefix) else { return nil }
        let body = token[opening.upperBound..<token.index(before: token.endIndex)]
        guard !body.isEmpty else { return nil }
        var decoded = "", escaped = false, depth = 1
        for character in body {
            if escaped { decoded.append(character); escaped = false }
            else if character == "\\" { escaped = true }
            else {
                if character == "[" { depth += 1 }
                if character == "]" { depth -= 1; if depth == 0 { return nil } }
                decoded.append(character == "_" ? " " : character)
            }
        }
        guard !escaped, depth == 1 else { return nil }
        return (prefix, TWArgument(decoded))
    }

    private static func groupCondition(_ value: String) -> TWCondition? {
        switch value {
        case "group-hover": .hovered
        case "group-focus": .focused
        case "group-active", "group-pressed": .pressed
        case "group-disabled": .disabled
        default: nil
        }
    }
}
