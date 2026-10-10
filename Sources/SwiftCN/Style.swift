import SwiftUI

/// Composable style values. Define your own named styles in ordinary Swift extensions.
public struct TWStyle: Sendable, ExpressibleByStringInterpolation {
    let rules: [TWRule]

    public init(_ styles: TWStyle...) { self.init(styles) }
    public init(_ styles: [TWStyle]) { rules = styles.flatMap(\.rules) }
    init(rules: [TWRule]) { self.rules = rules }

    public init(stringLiteral value: String) { self = .classes(value) }
    public init(stringInterpolation: TWClasses.StringInterpolation) {
        self = .classes(TWClasses(stringInterpolation: stringInterpolation))
    }

    /// Resolve class strings against the nearest theme and rules when the view renders.
    @_disfavoredOverload public static func classes(_ classes: String) -> Self {
        Self(rules: [TWRule(property: .classes(classes))])
    }
    public static func classes(_ classes: TWClasses) -> Self {
        Self(rules: [TWRule(property: .interpolated(classes))])
    }

    /// Validate and expand classes ahead of time, for tooling and generated styles.
    @_disfavoredOverload public static func parse(_ classes: String, rules: TWGlobalRules = TWGlobalRules(),
                             theme: TWTheme = .standard, target: TWTarget? = nil) throws -> Self {
        try TWClassParser.expand(.classes(classes), rules: rules, theme: theme, target: target)
    }
    public static func parse(_ classes: TWClasses, rules: TWGlobalRules = TWGlobalRules(),
                             theme: TWTheme = .standard, target: TWTarget? = nil) throws -> Self {
        try TWClassParser.expand(.classes(classes), rules: rules, theme: theme, target: target)
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
    case interpolated(TWClasses)
    case native(String, TWArgument?)
    case padding(TWEdge, TWLength)
    case font(TWFontSource)
    case weight(Font.Weight)
    case foreground(TWColorSource)
    case background(TWColorSource)
    case radius(TWRadiusSource)
    case border(TWColorSource, CGFloat)
    case borderColor(TWColorSource), borderWidth(CGFloat)
    case shadow(TWShadow)
    case surface(TWSurfaceRole), glassInteractive(Bool), glassTint(TWColorSource), prominent(Bool)
    case opacity(Double)
    case tracking(CGFloat), lineSpacing(CGFloat), textAlignment(TextAlignment), lineLimit(Int?)
    case offset(CGSize), scale(CGSize), rotation(Double), blur(CGFloat)
    case width(CGFloat), height(CGFloat), minimumHeight(CGFloat), minimumWidth(CGFloat), maximumWidth(CGFloat), maximumHeight(CGFloat), fullWidth
    case animation(TWAnimation), animationDuration(TimeInterval), animationDelay(TimeInterval)
    case group(String), sharedID(String, group: String?)
    case sharedProperties(TWSharedProperties), sharedSource(Bool)
}
