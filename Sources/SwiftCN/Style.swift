import SwiftUI

/// Composable style values. Define your own named styles in ordinary Swift extensions.
public struct TWStyle: Sendable, ExpressibleByStringLiteral {
    let rules: [TWRule]

    public init(_ styles: TWStyle...) { self.init(styles) }
    public init(_ styles: [TWStyle]) { rules = styles.flatMap(\.rules) }
    init(rules: [TWRule]) { self.rules = rules }

    public init(stringLiteral value: String) { self = .classes(value) }

    /// Resolve class strings against the nearest theme and rules when the view renders.
    public static func classes(_ classes: String) -> Self {
        Self(rules: [TWRule(property: .classes(classes))])
    }

    /// Validate and expand classes ahead of time, for tooling and generated styles.
    public static func parse(_ classes: String, rules: TWGlobalRules = TWGlobalRules(),
                             theme: TWTheme = .standard) throws -> Self {
        try TWClassParser.expand(.classes(classes), rules: rules, theme: theme)
    }

    func conditioned(on condition: TWCondition) -> TWStyle {
        TWStyle(rules: rules.map { rule in
            var rule = rule
            rule.conditions.insert(condition)
            return rule
        })
    }
}

enum TWCondition: Int, Hashable, Sendable {
    case hovered = 1, focused, pressed, disabled

    func matches(_ state: TWState) -> Bool {
        switch self {
        case .hovered: state.isHovered
        case .focused: state.isFocused
        case .pressed: state.isPressed
        case .disabled: state.isDisabled
        }
    }
}

struct TWRule: Sendable {
    let property: TWProperty
    var conditions: Set<TWCondition> = []
    var groupConditions: Set<TWGroupCondition> = []
    var priority: Int { (conditions.map(\.rawValue) + groupConditions.map { $0.condition.rawValue }).max() ?? 0 }
    var conditionCount: Int { conditions.count + groupConditions.count }
}

struct TWGroupCondition: Hashable, Sendable {
    let name: String?
    let condition: TWCondition
}

enum TWSharedProperties: Sendable { case frame, position, size }

enum TWEdge: Sendable { case top, leading, bottom, trailing }
enum TWLength: Sendable { case units(CGFloat), points(CGFloat) }
enum TWColorSource: Sendable { case token(TWColor), color(Color) }
enum TWFontSource: Sendable { case token(TWText), font(Font) }
enum TWRadiusSource: Sendable { case token(TWRadius), points(CGFloat) }

enum TWProperty: Sendable {
    case classes(String)
    case padding(TWEdge, TWLength)
    case font(TWFontSource)
    case weight(Font.Weight)
    case foreground(TWColorSource)
    case background(TWColorSource)
    case radius(TWRadiusSource)
    case border(TWColorSource, CGFloat)
    case borderColor(TWColorSource), borderWidth(CGFloat)
    case shadow(TWShadow)
    case opacity(Double)
    case width(CGFloat), height(CGFloat), minimumHeight(CGFloat), fullWidth
    case animation(TWAnimation), animationDuration(TimeInterval), animationDelay(TimeInterval)
    case group(String), sharedID(String, group: String?)
    case sharedProperties(TWSharedProperties), sharedSource(Bool)
}
