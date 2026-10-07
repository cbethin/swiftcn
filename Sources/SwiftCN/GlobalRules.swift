import SwiftUI

/// Environment-scoped defaults and editable named classes. Local utilities take precedence.
public struct TWGlobalRules: Sendable {
    public var view: TWStyle
    public var button: TWStyle
    public var named: [String: TWStyle]
    public var animations: [String: TWAnimation]
    public var utilities: [String: TWUtility]
    public var modifiers: [String: TWNativeUtility] {
        didSet { nativeSlots = Self.orderedSlots(modifiers) }
    }
    // Prepare order when the registry changes, rather than sorting it on every styled render.
    var nativeSlots: [TWNativeSlot]

    public init(view: TWStyle = TWStyle(), button: TWStyle = TWStyle(), named: [String: TWStyle] = [:],
                animations: [String: TWAnimation] = [:], utilities: [String: TWUtility] = [:],
                modifiers: [String: TWNativeUtility] = [:]) {
        self.view = view
        self.button = button
        self.named = named
        self.animations = TWAnimation.defaults.merging(animations) { _, override in override }
        self.utilities = utilities
        self.modifiers = modifiers
        self.nativeSlots = Self.orderedSlots(modifiers)
    }

    private static func orderedSlots(_ modifiers: [String: TWNativeUtility]) -> [TWNativeSlot] {
        modifiers.map { TWNativeSlot(name: $0.key, utility: $0.value) }.sorted {
            if $0.utility.phase != $1.utility.phase { return $0.utility.phase.rawValue < $1.utility.phase.rawValue }
            if $0.utility.order != $1.utility.order { return $0.utility.order < $1.utility.order }
            return $0.name < $1.name
        }
    }
}

extension EnvironmentValues {
    @Entry public var twRules: TWGlobalRules = TWGlobalRules()
}

extension View {
    /// Replace rules for this subtree. Unstyled descendants do not receive decoration.
    public func twRules(_ rules: TWGlobalRules) -> some View { environment(\.twRules, rules) }

    /// Change selected inherited rules without replacing the rest of the configuration.
    public func twRules(_ update: @escaping (inout TWGlobalRules) -> Void) -> some View {
        transformEnvironment(\.twRules, transform: update)
    }
}
