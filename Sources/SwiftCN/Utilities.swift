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
    /// A floating surface. The appearance policy and the system choose glass, a material, or a solid fill.
    public static var surfaceFloating: Self { property(.surface(.floating)) }
    /// A themed solid surface on every system.
    public static var surfaceSolid: Self { property(.surface(.solid)) }
    /// Liquid Glass where available. Earlier systems use a material, or a solid fill under Reduce Transparency.
    public static var glass: Self { property(.surface(.glass)) }
    /// Glass with a prominent native button style. Views draw it as glass.
    public static var glassProminent: Self { Self(property(.surface(.glass)), property(.prominent(true))) }
    /// Apple's touch and pointer feedback for glass. It installs no gesture.
    public static var glassInteractive: Self { property(.glassInteractive(true)) }
    public static func glassTint(_ token: TWColor) -> Self { property(.glassTint(.token(token))) }
    /// The tint of a native button or glass surface.
    public static func tint(_ token: TWColor) -> Self { property(.glassTint(.token(token))) }
    public static func tintColor(_ color: Color) -> Self { property(.glassTint(.color(color))) }
    /// A native button style. State variants never change it, so the button keeps its structure.
    public static func bezel(_ bezel: TWButtonBezel) -> Self { property(.bezel(bezel)) }
    public static func controlSize(_ size: ControlSize) -> Self { property(.controlSize(size)) }
    public static func glassTintColor(_ color: Color) -> Self { property(.glassTint(.color(color))) }
    public static func minW(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.minimumWidth(points))
    }
    public static func maxW(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.maximumWidth(points))
    }
    public static func maxH(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.maximumHeight(points))
    }

    public static func fontSize(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points > 0)
        return .font(.system(size: points))
    }
    public static func tracking(_ points: CGFloat) -> Self {
        precondition(points.isFinite)
        return property(.tracking(points))
    }
    public static func lineSpacing(_ points: CGFloat) -> Self {
        precondition(points.isFinite && points >= 0)
        return property(.lineSpacing(points))
    }
    public static func textAlignment(_ alignment: TextAlignment) -> Self { property(.textAlignment(alignment)) }
    public static func lineLimit(_ limit: Int?) -> Self {
        precondition(limit == nil || limit! > 0)
        return property(.lineLimit(limit))
    }
    public static func offset(x: CGFloat, y: CGFloat) -> Self {
        precondition(x.isFinite && y.isFinite)
        return property(.offset(CGSize(width: x, height: y)))
    }
    public static func scale(x: CGFloat, y: CGFloat) -> Self {
        precondition(x.isFinite && y.isFinite && x >= 0 && y >= 0)
        return property(.scale(CGSize(width: x, height: y)))
    }
    public static func scale(_ factor: CGFloat) -> Self { .scale(x: factor, y: factor) }
    public static func rotate(_ degrees: Double) -> Self {
        precondition(degrees.isFinite)
        return property(.rotation(degrees))
    }
    public static func blur(_ radius: CGFloat) -> Self {
        precondition(radius.isFinite && radius >= 0)
        return property(.blur(radius))
    }

    public static func animation(_ preset: TWAnimation) -> Self { property(.animation(preset)) }
    /// Duration in seconds. String duration utilities use milliseconds.
    public static func duration(_ seconds: TimeInterval) -> Self {
        precondition(seconds.isFinite && seconds >= 0)
        return property(.animationDuration(seconds))
    }
    /// Delay in seconds. String delay utilities use milliseconds.
    public static func delay(_ seconds: TimeInterval) -> Self {
        precondition(seconds.isFinite && seconds >= 0)
        return property(.animationDelay(seconds))
    }

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
