import SwiftUI

enum TWArgumentUtilities {
    static func resolve(_ prefix: String, argument: TWArgument, theme: TWTheme) -> TWStyle? {
        if prefix == "animate" {
            if let native = argument.value(as: Animation.self) { return .animation(TWAnimation(native)) }
            if let preset = argument.value(as: TWAnimation.self) { return .animation(preset) }
            return nil
        }
        let (hint, value) = argument.hinted
        if ["text", "bg", "border", "glass-tint"].contains(prefix), hint == nil || hint == "color" {
            if let color = value.hexColor {
                switch prefix {
                case "text": return .fgColor(color)
                case "bg": return .bgColor(color)
                case "glass-tint": return .glassTintColor(color)
                default: return TWStyle(rules: [TWRule(property: .borderColor(.color(color)))])
                }
            }
            let token = value.value(as: TWColor.self) ?? TWColor(value.rawValue)
            if theme.colors[token] != nil {
                switch prefix {
                case "text": return .fg(token)
                case "bg": return .bg(token)
                case "glass-tint": return .glassTint(token)
                default: return TWStyle(rules: [TWRule(property: .borderColor(.token(token)))])
                }
            }
            if hint == "color" { return nil }
        }
        guard hint == nil || hint == "length" || hint == "size" else { return nil }
        switch prefix {
        case "duration", "delay":
            guard hint == nil, let seconds = value.seconds, seconds >= 0 else { return nil }
            return prefix == "duration" ? .duration(seconds) : .delay(seconds)
        case "opacity":
            guard hint == nil, let amount = value.number, (0...1).contains(amount) else { return nil }
            return .opacity(amount)
        case "rotate":
            guard hint == nil, let degrees = value.degrees else { return nil }
            return .rotate(degrees)
        case "scale":
            guard hint == nil else { return nil }
            let parts = value.components
            guard parts.count == 1 || parts.count == 2,
                  let x = parts[0].number, let y = parts.last?.number, x >= 0, y >= 0 else { return nil }
            return .scale(x: CGFloat(x), y: CGFloat(y))
        case "offset":
            guard hint == nil else { return nil }
            let parts = value.components
            guard parts.count == 2, let x = parts[0].points, let y = parts[1].points else { return nil }
            return .offset(x: x, y: y)
        case "line-clamp":
            guard hint == nil, let count = value.value(as: Int.self), count > 0 else { return nil }
            return .lineLimit(count)
        default: break
        }
        guard let points = value.points else { return nil }
        if prefix == "tracking" { return .tracking(points) }
        guard points >= 0 else { return nil }
        switch prefix {
        case "p", "px", "py", "pt", "pb", "ps", "pe", "pl", "pr":
            let edges: [TWEdge]
            switch prefix {
            case "px": edges = [.leading, .trailing]
            case "py": edges = [.top, .bottom]
            case "pt": edges = [.top]
            case "pb": edges = [.bottom]
            case "ps", "pl": edges = [.leading]
            case "pe", "pr": edges = [.trailing]
            default: edges = [.top, .leading, .bottom, .trailing]
            }
            return TWStyle(rules: edges.map { TWRule(property: .padding($0, .points(points))) })
        case "w": return .w(points)
        case "h": return .h(points)
        case "size": return TWStyle(.w(points), .h(points))
        case "min-w": return .minW(points)
        case "max-w": return .maxW(points)
        case "min-h": return .minH(points)
        case "max-h": return .maxH(points)
        case "rounded": return .radius(points)
        case "border": return TWStyle(rules: [TWRule(property: .borderWidth(points))])
        case "text": return points > 0 ? .fontSize(points) : nil
        case "line-spacing": return .lineSpacing(points)
        case "blur": return .blur(points)
        default: return nil
        }
    }
}
