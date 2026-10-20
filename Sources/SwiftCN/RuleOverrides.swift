import SwiftUI
import os

/// Reusable changes to inherited rules. Named styles extend; replacing styles start fresh.
/// Keep a preset in a stored value so its copies share the same cache identity.
public struct TWRuleOverrides: Sendable {
    public var view: TWStyle
    public var button: TWStyle
    public var named: [String: TWStyle] { didSet { validate(); revision = TWRevision.next() } }
    public var replacing: [String: TWStyle] { didSet { validate(); revision = TWRevision.next() } }
    public var animations: [String: TWAnimation] { didSet { revision = TWRevision.next() } }
    public var utilities: [String: TWUtility] { didSet { revision = TWRevision.next() } }
    public var modifiers: [String: TWNativeUtility] { didSet { revision = TWRevision.next() } }
    private(set) var revision: UInt64

    public init(view: TWStyle = TWStyle(), button: TWStyle = TWStyle(), named: [String: TWStyle] = [:],
                replacing: [String: TWStyle] = [:], animations: [String: TWAnimation] = [:],
                utilities: [String: TWUtility] = [:], modifiers: [String: TWNativeUtility] = [:]) {
        self.view = view; self.button = button; self.named = named; self.replacing = replacing
        self.animations = animations; self.utilities = utilities; self.modifiers = modifiers
        revision = TWRevision.next()
        validate()
    }

    private func validate() {
        precondition(Set(named.keys).isDisjoint(with: replacing.keys),
                     "A recipe cannot occur in both named and replacing overrides.")
    }

    /// Resolve against any rules value, including the standard component registries.
    public func applying(to parent: TWGlobalRules) -> TWGlobalRules {
        let key = TWRuleOverrideCache.Key(parent: parent.revision, patch: revision)
        var result = TWRuleOverrideCache.shared.value(for: key) {
            var result = parent
            if !named.isEmpty || !replacing.isEmpty {
                for (name, patch) in named {
                    result.named[name] = TWStyle(result.named[name] ?? TWStyle.defaultClasses[name] ?? TWStyle(), patch)
                }
                result.named.merge(replacing) { _, replacement in replacement }
            }
            if !animations.isEmpty { result.animations.merge(animations) { _, patch in patch } }
            if !utilities.isEmpty { result.utilities.merge(utilities) { _, patch in patch } }
            if !modifiers.isEmpty { result.modifiers.merge(modifiers) { _, patch in patch } }
            return result
        }
        // These defaults do not participate in registry revisions. Compose the current values,
        // rather than caching them with a potentially older parent's view or button defaults.
        result.view = TWStyle(parent.view, view)
        result.button = TWStyle(parent.button, button)
        return result
    }
}

private final class TWRuleOverrideCache: @unchecked Sendable {
    struct Key: Hashable { let parent: UInt64; let patch: UInt64 }
    static let shared = TWRuleOverrideCache()
    private let storage = OSAllocatedUnfairLock(initialState: [Key: TWGlobalRules]())

    func value(for key: Key, create: @Sendable () -> TWGlobalRules) -> TWGlobalRules {
        storage.withLock { values in
            if let cached = values[key] { return cached }
            let result = create()
            if values.count >= 256 { values.removeAll(keepingCapacity: true) }
            values[key] = result
            return result
        }
    }
}

extension View {
    /// Extend inherited recipes without replacing unrelated rules or registries.
    public func twRules(overrides: TWRuleOverrides) -> some View {
        transformEnvironment(\.twRules) { inherited in inherited = overrides.applying(to: inherited) }
    }
}
