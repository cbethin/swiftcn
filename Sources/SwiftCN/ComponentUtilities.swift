import SwiftUI

/// Optional native utilities, installed only around components that need them.
/// Existing registrations win. Their arguments still participate in cn conflict resolution.
public enum CNUtilities {
    public static let tint: TWNativeUtility = .argument(default: "none", conflictKey: "cn-tint") { argument, theme in
        if argument.rawValue == "none" { return CNTintModifier(color: nil, token: nil) }
        if let color = argument.value(as: Color.self) { return CNTintModifier(color: color, token: nil) }
        let token = TWColor(argument.rawValue)
        guard theme.colors[token] != nil else { return nil }
        return CNTintModifier(color: nil, token: token)
    }
    public static let avatarCrop: TWNativeUtility = .view(phase: .decoration) { view, active in
        view.clipShape(RoundedRectangle(cornerRadius: active ? 10_000 : 0))
    }
    public static let avatarImage: TWNativeUtility = .view(phase: .layout) { view, active in
        view.aspectRatio(contentMode: active ? .fill : .fit)
    }
    public static let aspect: TWNativeUtility = .argument(default: Optional<CGFloat>.none, phase: .layout,
        parse: { argument, _ in guard let ratio = argument.points, ratio > 0 else { return nil }; return ratio }) {
        view, ratio in view.aspectRatio(ratio, contentMode: .fit)
    }
    public static let monospaced: TWNativeUtility = .view(phase: .content) { view, active in
        view.fontDesign(active ? .monospaced : nil)
    }
}

public struct CNTintModifier: ViewModifier {
    private let color: Color?
    private let token: TWColor?
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme

    public nonisolated init(color: Color?, token: TWColor?) { self.color = color; self.token = token }
    public func body(content: Content) -> some View {
        content.tint(token.map { theme.color($0, scheme: scheme) } ?? color)
    }
}

extension View {
    /// Scope to native controls. Include cn-tint-[primary] (or another color) in their classes.
    /// This installs no utilities in the application's global rules or unrelated styled rows.
    public func cnControlUtilities() -> some View {
        twRules { rules in
            if rules.modifiers["cn-tint"] == nil { rules.modifiers["cn-tint"] = CNUtilities.tint }
        }
    }
    public func cnAspectUtilities() -> some View {
        twRules { rules in
            if rules.modifiers["cn-aspect"] == nil { rules.modifiers["cn-aspect"] = CNUtilities.aspect }
        }
    }
    public func cnTextUtilities() -> some View {
        twRules { rules in
            if rules.modifiers["cn-mono"] == nil { rules.modifiers["cn-mono"] = CNUtilities.monospaced }
        }
    }
}

extension View {
    public func cnAvatarUtilities() -> some View {
        twRules { rules in
            if rules.modifiers["cn-avatar-crop"] == nil { rules.modifiers["cn-avatar-crop"] = CNUtilities.avatarCrop }
            if rules.modifiers["cn-avatar-image"] == nil { rules.modifiers["cn-avatar-image"] = CNUtilities.avatarImage }
        }
    }
}
