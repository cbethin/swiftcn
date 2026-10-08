import SwiftUI

/// Which part of a styled view receives the explicit animation preset.
public enum TWAnimationScope: String, Sendable, CaseIterable {
    case surface, layout, content, all
}

// Preserve Equatable state without requiring bindings or state values to be Sendable.
struct TWAnimationValue: Equatable {
    let value: Any
    private let equals: (Any) -> Bool
    init<Value: Equatable>(_ value: Value) {
        self.value = value
        equals = { ($0 as? Value) == value }
    }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.equals(rhs.value) }
}

struct TWCallerAnimation {
    let animation: Animation?
}
struct TWCallerAnimationKey: TransactionKey {
    static let defaultValue: TWCallerAnimation? = nil
}

struct TWAnimationChangeKey: TransactionKey {
    static let defaultValue: UUID? = nil
}

/// A native animation preset. Factories receive the duration selected by the style, in seconds.
public struct TWAnimation: Sendable {
    private let makeAnimation: @Sendable (TimeInterval) -> Animation?

    /// Use an exact native animation. Duration utilities do not retime this fixed preset.
    public init(_ animation: Animation) { makeAnimation = { _ in animation } }

    /// Define a native preset that responds to duration utilities.
    public init(_ makeAnimation: @escaping @Sendable (TimeInterval) -> Animation) {
        self.makeAnimation = makeAnimation
    }

    private init(optional makeAnimation: @escaping @Sendable (TimeInterval) -> Animation?) {
        self.makeAnimation = makeAnimation
    }

    public static let none = Self(optional: { _ in nil })
    public static let linear = Self { .linear(duration: $0) }
    public static let easeIn = Self { .easeIn(duration: $0) }
    public static let easeOut = Self { .easeOut(duration: $0) }
    public static let easeInOut = Self { .easeInOut(duration: $0) }
    public static let spring = Self { .spring(duration: $0) }
    public static let smooth = Self { .smooth(duration: $0) }
    public static let snappy = Self { .snappy(duration: $0) }
    public static let bouncy = Self { .bouncy(duration: $0) }

    static let defaults: [String: Self] = [
        "none": .none, "linear": .linear, "ease-in": .easeIn, "ease-out": .easeOut,
        "ease-in-out": .easeInOut, "spring": .spring, "smooth": .smooth,
        "snappy": .snappy, "bouncy": .bouncy
    ]

    func resolve(duration: TimeInterval, delay: TimeInterval) -> Animation? {
        makeAnimation(duration)?.delay(delay)
    }
}

struct TWResolvedMotion {
    var preset: TWAnimation?
    var duration: TimeInterval = 0.3
    var delay: TimeInterval = 0

    func update(_ transaction: inout Transaction, reduceMotion: Bool) {
        guard let preset, !transaction.disablesAnimations else { return }
        transaction.animation = reduceMotion ? nil : preset.resolve(duration: duration, delay: delay)
    }
}

extension View {
    /// Animate a subtree when a native state value changes, using the shared preset registry.
    /// Unlike `.tw`, this affects layout, transitions, and content as well as styled values.
    /// Set `tracksHover` to false on broad layout containers that should not observe pointer entry.
    @_disfavoredOverload public func twAnimation<Value: Equatable>(_ classes: String, value: Value, tracksHover: Bool = true) -> some View {
        modifier(TWValueAnimationModifier(style: .classes(classes), value: value, tracksHover: tracksHover))
    }
    public func twAnimation<Value: Equatable>(_ classes: TWClasses, value: Value, tracksHover: Bool = true) -> some View {
        modifier(TWValueAnimationModifier(style: .classes(classes), value: value, tracksHover: tracksHover))
    }

    public func twAnimation<Value: Equatable>(_ styles: TWStyle..., value: Value, tracksHover: Bool = true) -> some View {
        modifier(TWValueAnimationModifier(style: TWStyle(styles), value: value, tracksHover: tracksHover))
    }
}

struct TWValueAnimationModifier<Value: Equatable>: ViewModifier {
    let style: TWStyle
    let value: Value
    let state: TWState
    let tracksHover: Bool
    @Environment(\.twTheme) private var theme
    @Environment(\.twRules) private var rules
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.twGroups) private var groups
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    init(style: TWStyle, value: Value, state: TWState = TWState(), tracksHover: Bool = true) {
        self.style = style
        self.value = value
        self.state = state
        self.tracksHover = tracksHover
    }

    func body(content: Content) -> some View {
        var activeState = state
        activeState.isDisabled = activeState.isDisabled || !isEnabled
        activeState.isHovered = activeState.isHovered || isHovered
        let motion = TWStyleResolver.resolve(TWStyle(rules.view, style), theme: theme,
            scheme: scheme, state: activeState, globalRules: rules, groupStates: groups.states, target: nil).motion
        let animated = content.transaction(value: value) { transaction in
            motion.update(&transaction, reduceMotion: reduceMotion)
        }
        return Group {
            if tracksHover { animated.onHover { isHovered = $0 } }
            else { animated }
        }
    }
}
