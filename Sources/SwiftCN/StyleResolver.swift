import SwiftUI

struct TWResolvedStyle {
    var padding = EdgeInsets()
    var font: Font?
    var weight: Font.Weight?
    var foreground: Color?
    var background: Color?
    var radius: CGFloat = 0
    var border: Color?
    var borderWidth: CGFloat = 0
    var shadow: TWShadowValue?
    var opacity: Double = 1
    var width: CGFloat?
    var height: CGFloat?
    var minimumHeight: CGFloat?
    var expandsWidth = false
}

enum TWStyleResolver {
    static func resolve(_ style: TWStyle, theme: TWTheme, scheme: ColorScheme, state: TWState) -> TWResolvedStyle {
        let rules = style.rules.enumerated()
            .filter { $0.element.conditions.allSatisfy { $0.matches(state) } }
            .sorted { lhs, rhs in
                if lhs.element.priority != rhs.element.priority {
                    return lhs.element.priority < rhs.element.priority
                }
                if lhs.element.conditions.count != rhs.element.conditions.count {
                    return lhs.element.conditions.count < rhs.element.conditions.count
                }
                return lhs.offset < rhs.offset
            }
        var result = TWResolvedStyle()
        for entry in rules {
            switch entry.element.property {
            case .padding(let edge, let length):
                let value: CGFloat
                switch length {
                case .units(let units): value = theme.space(units)
                case .points(let points): value = points
                }
                switch edge {
                case .top: result.padding.top = value
                case .leading: result.padding.leading = value
                case .bottom: result.padding.bottom = value
                case .trailing: result.padding.trailing = value
                }
            case .font(let source):
                switch source {
                case .token(let token): result.font = theme.font(token)
                case .font(let font): result.font = font
                }
            case .weight(let weight): result.weight = weight
            case .foreground(let source): result.foreground = color(source, theme: theme, scheme: scheme)
            case .background(let source): result.background = color(source, theme: theme, scheme: scheme)
            case .radius(let source):
                switch source {
                case .token(let token): result.radius = theme.radius(token)
                case .points(let points): result.radius = points
                }
            case .border(let source, let width):
                result.border = color(source, theme: theme, scheme: scheme)
                result.borderWidth = width
            case .shadow(let token): result.shadow = theme.shadow(token)
            case .opacity(let opacity): result.opacity = opacity
            case .width(let width): result.width = width; result.expandsWidth = false
            case .height(let height): result.height = height
            case .minimumHeight(let height): result.minimumHeight = height
            case .fullWidth: result.width = nil; result.expandsWidth = true
            }
        }
        return result
    }

    private static func color(_ source: TWColorSource, theme: TWTheme, scheme: ColorScheme) -> Color {
        switch source {
        case .token(let token): theme.color(token, scheme: scheme)
        case .color(let color): color
        }
    }
}
