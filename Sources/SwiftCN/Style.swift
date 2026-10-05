import SwiftUI

/// Composable style values. Define your own named styles in ordinary Swift extensions.
public struct TWStyle: Sendable {
    let rules: [TWRule]

    public init(_ styles: TWStyle...) { self.init(styles) }
    public init(_ styles: [TWStyle]) { rules = styles.flatMap(\.rules) }
    init(rules: [TWRule]) { self.rules = rules }

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
    var priority: Int { conditions.map(\.rawValue).max() ?? 0 }
}

enum TWEdge: Sendable { case top, leading, bottom, trailing }
enum TWLength: Sendable { case units(CGFloat), points(CGFloat) }
enum TWColorSource: Sendable { case token(TWColor), color(Color) }
enum TWFontSource: Sendable { case token(TWText), font(Font) }
enum TWRadiusSource: Sendable { case token(TWRadius), points(CGFloat) }

enum TWProperty: Sendable {
    case padding(TWEdge, TWLength)
    case font(TWFontSource)
    case weight(Font.Weight)
    case foreground(TWColorSource)
    case background(TWColorSource)
    case radius(TWRadiusSource)
    case border(TWColorSource, CGFloat)
    case shadow(TWShadow)
    case opacity(Double)
    case width(CGFloat), height(CGFloat), minimumHeight(CGFloat), fullWidth
}
