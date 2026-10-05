import SwiftUI

/// A registered native modifier with a stable inactive representation.
/// Slots run after built-in decoration, ordered by `order`, then registration name.
public struct TWNativeUtility: Sendable {
    public let order: Int
    public let conflictKey: String?
    private let accepts: @Sendable (TWArgument?, TWTheme) -> Bool
    private let transform: @MainActor @Sendable (AnyView, TWArgument?, Bool, TWTheme) -> AnyView

    private init(order: Int, conflictKey: String?,
                 accepts: @escaping @Sendable (TWArgument?, TWTheme) -> Bool,
                 transform: @escaping @MainActor @Sendable (AnyView, TWArgument?, Bool, TWTheme) -> AnyView) {
        self.order = order
        self.conflictKey = conflictKey
        self.accepts = accepts
        self.transform = transform
    }

    /// An exact tag. Keep the same view structure and use `active` to select neutral values.
    public static func view<Output: View>(order: Int = 0, conflictKey: String? = nil,
        @ViewBuilder _ transform: @escaping @MainActor @Sendable (AnyView, Bool) -> Output) -> Self {
        Self(order: order, conflictKey: conflictKey, accepts: { argument, _ in argument == nil }) {
            content, _, active, _ in AnyView(transform(content, active))
        }
    }

    /// An exact tag backed by a native modifier. The factory also supplies its inactive value.
    public static func modifier<M: ViewModifier>(order: Int = 0, conflictKey: String? = nil,
        _ make: @escaping @MainActor @Sendable (Bool, TWTheme) -> M) -> Self {
        Self(order: order, conflictKey: conflictKey, accepts: { argument, _ in argument == nil }) {
            content, _, active, theme in AnyView(content.modifier(make(active, theme)))
        }
    }

    /// Decode a bracket argument into a typed value, then apply native modifiers directly.
    /// The inactive value must be neutral and safe for the native API.
    public static func argument<Value: Sendable, Output: View>(default inactiveValue: Value,
        order: Int = 0, conflictKey: String? = nil,
        parse: @escaping @Sendable (TWArgument, TWTheme) -> Value?,
        @ViewBuilder _ transform: @escaping @MainActor @Sendable (AnyView, Value) -> Output) -> Self {
        Self(order: order, conflictKey: conflictKey, accepts: { argument, theme in
            guard let argument else { return false }
            return parse(argument, theme) != nil
        }) { content, argument, active, theme in
            let value = active ? argument.flatMap { parse($0, theme) } ?? inactiveValue : inactiveValue
            return AnyView(transform(content, value))
        }
    }

    /// Accept an interpolated native value, or a supported literal scalar representation.
    public static func value<Value: Sendable, Output: View>(default inactiveValue: Value,
        order: Int = 0, conflictKey: String? = nil,
        @ViewBuilder _ transform: @escaping @MainActor @Sendable (AnyView, Value) -> Output) -> Self {
        argument(default: inactiveValue, order: order, conflictKey: conflictKey,
            parse: { argument, _ in argument.value(as: Value.self) }, transform)
    }

    /// A bracket utility. The default argument must produce a neutral modifier in every theme.
    /// Return nil to reject an argument. Factories must be pure and may run during validation.
    public static func argument<M: ViewModifier>(default inactiveArgument: String,
        order: Int = 0, conflictKey: String? = nil,
        _ make: @escaping @Sendable (TWArgument, TWTheme) -> M?) -> Self {
        let factory: any TWNativeArgumentMaking = TWNativeArgumentFactory(inactiveArgument: inactiveArgument, make: make)
        return Self(order: order, conflictKey: conflictKey, accepts: { argument, theme in
            factory.validate(argument, theme: theme)
        }) { content, argument, active, theme in
            factory.apply(to: content, argument: argument, active: active, theme: theme)
        }
    }

    func validate(_ argument: TWArgument?, theme: TWTheme) -> Bool { accepts(argument, theme) }

    @MainActor func apply(to content: AnyView, argument: TWArgument?, active: Bool, theme: TWTheme) -> AnyView {
        transform(content, argument, active, theme)
    }
}

// Keep generic modifier construction outside Sendable closure captures. Modifier values
// need not be Sendable: validation discards them and rendering stays on the main actor.
private protocol TWNativeArgumentMaking: Sendable {
    func validate(_ argument: TWArgument?, theme: TWTheme) -> Bool
    @MainActor func apply(to content: AnyView, argument: TWArgument?, active: Bool, theme: TWTheme) -> AnyView
}

private final class TWNativeArgumentFactory<M: ViewModifier>: TWNativeArgumentMaking {
    let inactiveArgument: String
    let make: @Sendable (TWArgument, TWTheme) -> M?

    init(inactiveArgument: String, make: @escaping @Sendable (TWArgument, TWTheme) -> M?) {
        self.inactiveArgument = inactiveArgument
        self.make = make
    }

    func validate(_ argument: TWArgument?, theme: TWTheme) -> Bool {
        guard let argument, make(TWArgument(inactiveArgument), theme) != nil,
              make(argument, theme) != nil else { return false }
        return true
    }

    @MainActor func apply(to content: AnyView, argument: TWArgument?, active: Bool, theme: TWTheme) -> AnyView {
        let argument = active ? argument : TWArgument(inactiveArgument)
        guard let argument, let modifier = make(argument, theme) else { return content }
        return AnyView(content.modifier(modifier))
    }
}

struct TWNativeSlot {
    let name: String
    let utility: TWNativeUtility
    var argument: TWArgument?
    var active = false
}

struct TWNativeChainModifier: ViewModifier {
    let slots: [TWNativeSlot]
    let theme: TWTheme

    @ViewBuilder func body(content: Content) -> some View {
        if slots.isEmpty {
            content
        } else {
            slots.reduce(AnyView(content)) { view, slot in
                slot.utility.apply(to: view, argument: slot.argument, active: slot.active, theme: theme)
            }
        }
    }
}
