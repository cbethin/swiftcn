import SwiftUI

/// Environment-scoped defaults and editable named classes. Local utilities take precedence.
public struct TWGlobalRules: Sendable {
    public var view: TWStyle
    public var button: TWStyle
    public var named: [String: TWStyle]
    public var animations: [String: TWAnimation]

    public init(view: TWStyle = TWStyle(), button: TWStyle = TWStyle(), named: [String: TWStyle] = [:],
                animations: [String: TWAnimation] = [:]) {
        self.view = view
        self.button = button
        self.named = named
        self.animations = TWAnimation.defaults.merging(animations) { _, override in override }
    }
}

private struct TWGlobalRulesKey: EnvironmentKey {
    static let defaultValue = TWGlobalRules()
}

extension EnvironmentValues {
    public var twRules: TWGlobalRules {
        get { self[TWGlobalRulesKey.self] }
        set { self[TWGlobalRulesKey.self] = newValue }
    }
}

extension View {
    /// Replace rules for this subtree. Unstyled descendants do not receive decoration.
    public func twRules(_ rules: TWGlobalRules) -> some View { environment(\.twRules, rules) }

    /// Change selected inherited rules without replacing the rest of the configuration.
    public func twRules(_ update: @escaping (inout TWGlobalRules) -> Void) -> some View {
        transformEnvironment(\.twRules, transform: update)
    }
}
