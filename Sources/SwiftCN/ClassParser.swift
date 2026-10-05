import SwiftUI

public enum TWClassError: Error, Equatable, CustomStringConvertible {
    case unknownClass(String)
    case unknownVariant(String)
    case recursiveClass(String)
    case expansionLimit

    public var description: String {
        switch self {
        case .unknownClass(let name): "Unknown swiftcn class: \(name)"
        case .unknownVariant(let name): "Unknown swiftcn variant: \(name)"
        case .recursiveClass(let name): "Recursive swiftcn class: \(name)"
        case .expansionLimit: "swiftcn class expansion exceeds 32 levels"
        }
    }
}

enum TWClassParser {
    static func expand(_ style: TWStyle, rules: TWGlobalRules, theme: TWTheme,
                       stack: [String] = [], depth: Int = 0) throws -> TWStyle {
        guard depth < 32 else { throw TWClassError.expansionLimit }
        var result: [TWRule] = []
        for rule in style.rules {
            guard case .classes(let classes) = rule.property else {
                result.append(rule)
                continue
            }
            for token in classes.split(whereSeparator: { $0.isWhitespace }) {
                let parts = token.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
                let name = parts.last!
                var conditions = rule.conditions
                for variant in parts.dropLast() {
                    switch variant {
                    case "hover": conditions.insert(.hovered)
                    case "focus": conditions.insert(.focused)
                    case "active", "pressed": conditions.insert(.pressed)
                    case "disabled": conditions.insert(.disabled)
                    default: throw TWClassError.unknownVariant(variant)
                    }
                }
                let expanded: TWStyle
                if let named = rules.named[name] ?? TWStyle.defaultClasses[name] {
                    guard !stack.contains(name) else { throw TWClassError.recursiveClass(name) }
                    expanded = try expand(named, rules: rules, theme: theme, stack: stack + [name], depth: depth + 1)
                } else {
                    guard let utility = utility(name, theme: theme) else { throw TWClassError.unknownClass(name) }
                    expanded = utility
                }
                result += expanded.rules.map {
                    var value = $0
                    value.conditions.formUnion(conditions)
                    return value
                }
            }
        }
        return TWStyle(rules: result)
    }

    private static func utility(_ name: String, theme: TWTheme) -> TWStyle? {
        if name == "w-full" { return .fullWidth }
        if name == "border" { return .border(.border) }
        if name == "rounded" { return .rounded(.md) }
        if name == "shadow" { return .shadow(.sm) }
        let fonts: [String: TWText] = ["xs": .xs, "sm": .sm, "base": .base, "lg": .lg,
                                       "xl": .xl, "2xl": .xxl, "3xl": .xxxl]
        let weights: [String: Font.Weight] = ["regular": .regular, "normal": .regular, "medium": .medium,
                                              "semibold": .semibold, "bold": .bold, "light": .light]
        let radii: [String: TWRadius] = ["none": .none, "sm": .sm, "md": .md, "lg": .lg, "xl": .xl, "full": .full]
        let shadows: [String: TWShadow] = ["none": .none, "sm": .sm, "md": .md, "lg": .lg]
        let aliases: [String: TWColor] = ["primary-foreground": .onPrimary, "accent-foreground": .onAccent,
                                         "destructive-foreground": .onDestructive, "card": .surface,
                                         "card-foreground": .foreground, "muted-foreground": .mutedForeground]
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
}
