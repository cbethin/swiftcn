import SwiftUI

/// Placement relative to the built-in surface modifiers.
public enum TWModifierPhase: Int, Sendable, CaseIterable {
    case content, layout, decoration, effects
}

/// Native source required by a target-specific registration.
public enum TWTarget: String, Sendable {
    case view, text, image, shape
}

/// A registered native modifier with a stable inactive representation.
/// Slots run in their phase, ordered by `order`, then registration name.
public struct TWNativeUtility: Sendable {
    public let phase: TWModifierPhase
    public let target: TWTarget
    public let order: Int
    public let conflictKey: String?
    private let accepts: @Sendable (TWArgument?, TWTheme) -> Bool
    private let transform: @MainActor @Sendable (AnyView, TWArgument?, Bool, TWTheme) -> AnyView

    private let textTransform: (@MainActor @Sendable (Text, TWArgument?, Bool, TWTheme) -> Text)?
    private let imageTransform: (@MainActor @Sendable (Image, TWArgument?, Bool, TWTheme) -> Image)?
    private let shapeTransform: (@MainActor @Sendable (AnyShape, TWArgument?, Bool, TWTheme) -> AnyShape)?

    private init(phase: TWModifierPhase = .effects, target: TWTarget = .view, order: Int, conflictKey: String?,
                 accepts: @escaping @Sendable (TWArgument?, TWTheme) -> Bool,
                 transform: @escaping @MainActor @Sendable (AnyView, TWArgument?, Bool, TWTheme) -> AnyView = { view, _, _, _ in view },
                 textTransform: (@MainActor @Sendable (Text, TWArgument?, Bool, TWTheme) -> Text)? = nil,
                 imageTransform: (@MainActor @Sendable (Image, TWArgument?, Bool, TWTheme) -> Image)? = nil,
                 shapeTransform: (@MainActor @Sendable (AnyShape, TWArgument?, Bool, TWTheme) -> AnyShape)? = nil) {
        self.phase = phase
        self.target = target
        self.textTransform = textTransform
        self.imageTransform = imageTransform
        self.shapeTransform = shapeTransform
        self.order = order
        self.conflictKey = conflictKey
        self.accepts = accepts
        self.transform = transform
    }

    /// An exact tag. Keep the same view structure and use `active` to select neutral values.
    public static func view<Output: View>(phase: TWModifierPhase = .effects, order: Int = 0, conflictKey: String? = nil,
        @ViewBuilder _ transform: @escaping @MainActor @Sendable (AnyView, Bool) -> Output) -> Self {
        Self(phase: phase, order: order, conflictKey: conflictKey, accepts: { argument, _ in argument == nil }) {
            content, _, active, _ in AnyView(transform(content, active))
        }
    }

    /// An exact tag backed by a native modifier. The factory also supplies its inactive value.
    public static func modifier<M: ViewModifier>(phase: TWModifierPhase = .effects, order: Int = 0, conflictKey: String? = nil,
        _ make: @escaping @MainActor @Sendable (Bool, TWTheme) -> M) -> Self {
        Self(phase: phase, order: order, conflictKey: conflictKey, accepts: { argument, _ in argument == nil }) {
            content, _, active, theme in AnyView(content.modifier(make(active, theme)))
        }
    }

    /// Decode a bracket argument into a typed value, then apply native modifiers directly.
    /// The inactive value must be neutral and safe for the native API.
    public static func argument<Value: Sendable, Output: View>(default inactiveValue: Value,
        phase: TWModifierPhase = .effects, order: Int = 0, conflictKey: String? = nil,
        parse: @escaping @Sendable (TWArgument, TWTheme) -> Value?,
        @ViewBuilder _ transform: @escaping @MainActor @Sendable (AnyView, Value) -> Output) -> Self {
        Self(phase: phase, order: order, conflictKey: conflictKey, accepts: { argument, theme in
            guard let argument else { return false }
            return parse(argument, theme) != nil
        }) { content, argument, active, theme in
            let value = active ? argument.flatMap { parse($0, theme) } ?? inactiveValue : inactiveValue
            return AnyView(transform(content, value))
        }
    }

    /// Accept an interpolated native value, or a supported literal scalar representation.
    public static func value<Value: Sendable, Output: View>(default inactiveValue: Value,
        phase: TWModifierPhase = .effects, order: Int = 0, conflictKey: String? = nil,
        @ViewBuilder _ transform: @escaping @MainActor @Sendable (AnyView, Value) -> Output) -> Self {
        argument(default: inactiveValue, phase: phase, order: order, conflictKey: conflictKey,
            parse: { argument, _ in argument.value(as: Value.self) }, transform)
    }

    /// A bracket utility. The default argument must produce a neutral modifier in every theme.
    /// Return nil to reject an argument. Factories must be pure and may run during validation.
    public static func argument<M: ViewModifier>(default inactiveArgument: String,
        phase: TWModifierPhase = .effects, order: Int = 0, conflictKey: String? = nil,
        _ make: @escaping @Sendable (TWArgument, TWTheme) -> M?) -> Self {
        let factory: any TWNativeArgumentMaking = TWNativeArgumentFactory(inactiveArgument: inactiveArgument, make: make)
        return Self(phase: phase, order: order, conflictKey: conflictKey, accepts: { argument, theme in
            factory.validate(argument, theme: theme)
        }) { content, argument, active, theme in
            factory.apply(to: content, argument: argument, active: active, theme: theme)
        }
    }

    /// Transform a native Text before it becomes a general View.
    public static func text(order: Int = 0, conflictKey: String? = nil,
        _ transform: @escaping @MainActor @Sendable (Text, Bool) -> Text) -> Self {
        Self(phase: .content, target: .text, order: order, conflictKey: conflictKey,
             accepts: { argument, _ in argument == nil },
             textTransform: { text, _, active, _ in transform(text, active) })
    }

    /// Transform a native Image before layout and decoration.
    public static func image(order: Int = 0, conflictKey: String? = nil,
        _ transform: @escaping @MainActor @Sendable (Image, Bool) -> Image) -> Self {
        Self(phase: .content, target: .image, order: order, conflictKey: conflictKey,
             accepts: { argument, _ in argument == nil },
             imageTransform: { image, _, active, _ in transform(image, active) })
    }

    /// Transform a Shape through SwiftUI's AnyShape, before layout and decoration.
    public static func shape(order: Int = 0, conflictKey: String? = nil,
        _ transform: @escaping @MainActor @Sendable (AnyShape, Bool) -> AnyShape) -> Self {
        Self(phase: .content, target: .shape, order: order, conflictKey: conflictKey,
             accepts: { argument, _ in argument == nil },
             shapeTransform: { shape, _, active, _ in transform(shape, active) })
    }

    public static func textValue<Value: Sendable>(default inactiveValue: Value,
        order: Int = 0, conflictKey: String? = nil,
        _ transform: @escaping @MainActor @Sendable (Text, Value) -> Text) -> Self {
        Self(phase: .content, target: .text, order: order, conflictKey: conflictKey,
             accepts: { argument, _ in argument?.value(as: Value.self) != nil },
             textTransform: { text, argument, active, _ in
                 transform(text, active ? argument?.value(as: Value.self) ?? inactiveValue : inactiveValue)
             })
    }

    public static func imageValue<Value: Sendable>(default inactiveValue: Value,
        order: Int = 0, conflictKey: String? = nil,
        _ transform: @escaping @MainActor @Sendable (Image, Value) -> Image) -> Self {
        Self(phase: .content, target: .image, order: order, conflictKey: conflictKey,
             accepts: { argument, _ in argument?.value(as: Value.self) != nil },
             imageTransform: { image, argument, active, _ in
                 transform(image, active ? argument?.value(as: Value.self) ?? inactiveValue : inactiveValue)
             })
    }

    public static func shapeValue<Value: Sendable>(default inactiveValue: Value,
        order: Int = 0, conflictKey: String? = nil,
        _ transform: @escaping @MainActor @Sendable (AnyShape, Value) -> AnyShape) -> Self {
        Self(phase: .content, target: .shape, order: order, conflictKey: conflictKey,
             accepts: { argument, _ in argument?.value(as: Value.self) != nil },
             shapeTransform: { shape, argument, active, _ in
                 transform(shape, active ? argument?.value(as: Value.self) ?? inactiveValue : inactiveValue)
             })
    }

    @MainActor func apply(to text: Text, argument: TWArgument?, active: Bool, theme: TWTheme) -> Text {
        // Text attributes accumulate; even a zero-valued inactive attribute can mask a winner.
        // The source remains Text when an attribute is absent, so no wrapper needs retaining.
        guard active else { return text }
        return textTransform?(text, argument, active, theme) ?? text
    }
    @MainActor func apply(to image: Image, argument: TWArgument?, active: Bool, theme: TWTheme) -> Image {
        guard active else { return image }
        return imageTransform?(image, argument, active, theme) ?? image
    }
    @MainActor func apply(to shape: AnyShape, argument: TWArgument?, active: Bool, theme: TWTheme) -> AnyShape {
        shapeTransform?(shape, argument, active, theme) ?? shape
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

struct TWNativeSlot: Sendable {
    let name: String
    let utility: TWNativeUtility
    var argument: TWArgument?
    var active = false
}

struct TWNativeChainModifier: ViewModifier {
    let slots: [TWNativeSlot]
    let theme: TWTheme
    var phase: TWModifierPhase = .effects

    @ViewBuilder func body(content: Content) -> some View {
        let slots = slots.filter { $0.utility.target == .view && $0.utility.phase == phase }
        if slots.isEmpty {
            content
        } else {
            slots.reduce(AnyView(content)) { view, slot in
                slot.utility.apply(to: view, argument: slot.argument, active: slot.active, theme: theme)
            }
        }
    }
}
