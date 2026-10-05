import SwiftUI

extension TWStyle {
    public static func p(_ units: CGFloat) -> Self { padding([.top, .leading, .bottom, .trailing], .units(units)) }
    public static func px(_ units: CGFloat) -> Self { padding([.leading, .trailing], .units(units)) }
    public static func py(_ units: CGFloat) -> Self { padding([.top, .bottom], .units(units)) }
    public static func pt(_ units: CGFloat) -> Self { padding([.top], .units(units)) }
    public static func pb(_ units: CGFloat) -> Self { padding([.bottom], .units(units)) }
    public static func ps(_ units: CGFloat) -> Self { padding([.leading], .units(units)) }
    public static func pe(_ units: CGFloat) -> Self { padding([.trailing], .units(units)) }

    public static func paddingPoints(_ points: CGFloat) -> Self {
        padding([.top, .leading, .bottom, .trailing], .points(points))
    }
    public static func text(_ token: TWText) -> Self { property(.font(.token(token))) }
    public static func font(_ font: Font) -> Self { property(.font(.font(font))) }
    public static func weight(_ weight: Font.Weight) -> Self { property(.weight(weight)) }
    public static func fg(_ token: TWColor) -> Self { property(.foreground(.token(token))) }
    public static func bg(_ token: TWColor) -> Self { property(.background(.token(token))) }
    public static func fgColor(_ color: Color) -> Self { property(.foreground(.color(color))) }
    public static func bgColor(_ color: Color) -> Self { property(.background(.color(color))) }
    public static func rounded(_ token: TWRadius) -> Self { property(.radius(.token(token))) }
    public static func radius(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.radius(.points(points)))
    }
    public static func border(_ token: TWColor, width: CGFloat = 1) -> Self {
        precondition(width.isFinite && width >= 0)
        return property(.border(.token(token), width))
    }
    public static func borderColor(_ color: Color, width: CGFloat = 1) -> Self {
        precondition(width.isFinite && width >= 0)
        return property(.border(.color(color), width))
    }
    public static func shadow(_ token: TWShadow) -> Self { property(.shadow(token)) }
    public static func opacity(_ value: Double) -> Self {
        precondition(value.isFinite && (0...1).contains(value))
        return property(.opacity(value))
    }
    public static func w(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.width(points))
    }
    public static func h(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.height(points))
    }
    public static func minH(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.minimumHeight(points))
    }
    public static var fullWidth: Self { property(.fullWidth) }

    public static func hover(_ styles: TWStyle...) -> Self { Self(styles).conditioned(on: .hovered) }
    public static func focus(_ styles: TWStyle...) -> Self { Self(styles).conditioned(on: .focused) }
    public static func pressed(_ styles: TWStyle...) -> Self { Self(styles).conditioned(on: .pressed) }
    public static func disabled(_ styles: TWStyle...) -> Self { Self(styles).conditioned(on: .disabled) }

    private static func property(_ value: TWProperty) -> Self { Self(rules: [TWRule(property: value)]) }
    private static func padding(_ edges: [TWEdge], _ length: TWLength) -> Self {
        switch length {
        case .units(let value), .points(let value): precondition(value.isFinite && value >= 0)
        }
        return Self(rules: edges.map { TWRule(property: .padding($0, length)) })
    }
}
