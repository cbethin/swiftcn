import SwiftUI
import os

extension View {
    @_disfavoredOverload public func tw(_ classes: String, state: TWState = TWState(), animationScope: TWAnimationScope = .surface) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state, text: self as? Text, image: self as? Image, shape: twShape(self), animationScope: animationScope))
    }
    public func tw(_ classes: TWClasses, state: TWState = TWState(), animationScope: TWAnimationScope = .surface) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state, text: self as? Text, image: self as? Image, shape: twShape(self), animationScope: animationScope))
    }

    /// Watch native state for layout and shared-element animation using these classes.
    @_disfavoredOverload public func tw<Value: Equatable>(_ classes: String, value: Value, state: TWState = TWState(), animationScope: TWAnimationScope = .all) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state, text: self as? Text, image: self as? Image, shape: twShape(self), animationScope: animationScope, animationValue: TWAnimationValue(value)))
    }
    public func tw<Value: Equatable>(_ classes: TWClasses, value: Value, state: TWState = TWState(), animationScope: TWAnimationScope = .all) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state, text: self as? Text, image: self as? Image, shape: twShape(self), animationScope: animationScope, animationValue: TWAnimationValue(value)))
    }
    /// Apply one styled surface. Later utilities replace earlier values by property.
    public func tw(_ styles: TWStyle..., state: TWState = TWState(), animationScope: TWAnimationScope = .surface) -> some View {
        modifier(TWModifier(style: TWStyle(styles), state: state, text: self as? Text, image: self as? Image, shape: twShape(self), animationScope: animationScope))
    }

    /// Array overload for computed or shared style collections.
    public func tw(_ styles: [TWStyle], state: TWState = TWState(), animationScope: TWAnimationScope = .surface) -> some View {
        modifier(TWModifier(style: TWStyle(styles), state: state, text: self as? Text, image: self as? Image, shape: twShape(self), animationScope: animationScope))
    }
}

struct TWModifier: ViewModifier {
    let style: TWStyle
    var state: TWState
    var isButton = false
    var text: Text? = nil
    var image: Image? = nil
    var shape: AnyShape? = nil
    var animationScope: TWAnimationScope = .surface
    var animationValue: TWAnimationValue? = nil
    @State private var animationID = UUID()
    private var target: TWTarget { text != nil ? .text : image != nil ? .image : shape != nil ? .shape : .view }
    @Environment(\.twTheme) private var theme
    @Environment(\.twRules) private var rules
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.twGroups) private var groups
    @Namespace private var groupNamespace
    @State private var isHovered = false

    func body(content: Content) -> some View {
        var activeState = state
        activeState.isDisabled = activeState.isDisabled || !isEnabled
        activeState.isHovered = activeState.isHovered || isHovered
        let combined = TWStyle(rules.view, isButton ? rules.button : TWStyle(), style)
        let appearance = TWStyleResolver.resolve(combined, theme: theme, scheme: scheme, state: activeState,
            globalRules: rules, groupStates: groups.states, target: target)
        return source(content, appearance: appearance)
            .transaction { transaction in
                if (animationScope == .content || animationScope == .all),
                   animationValue == nil || transaction[TWAnimationChangeKey.self] == animationID {
                    appearance.motion.update(&transaction, reduceMotion: reduceMotion)
                }
            }
            .transformEnvironment(\.contentTransition) { transition in
                // Native placement must share layout motion; content morphing remains separate.
                if animationValue != nil && appearance.motion.preset != nil && (animationScope == .surface || animationScope == .layout) {
                    transition = .identity
                }
            }
            .modifier(phase(.content, appearance: appearance))
            .modifier(phase(.layout, appearance: appearance))
            .modifier(phase(.decoration, appearance: appearance))
            .modifier(phase(.effects, appearance: appearance))
            .modifier(TWDrivenAnimationModifier(motion: appearance.motion, value: animationValue,
                appliesToRoot: animationValue != nil && animationScope != .content,
                animationID: animationValue != nil ? animationID : nil))
            .onHover { isHovered = $0 }
            .transformEnvironment(\.twGroups) { inherited in
                if let name = appearance.group {
                    inherited.scopes.append(TWGroupScope(name: name, namespace: groupNamespace, state: activeState))
                }
            }
    }

    private func phase(_ phase: TWModifierPhase, appearance: TWResolvedStyle) -> TWPhaseModifier {
        TWPhaseModifier(phase: phase, appearance: appearance, theme: theme, scheme: scheme,
            groups: groups, scope: animationScope, watched: animationValue != nil, animationID: animationID,
            reduceMotion: reduceMotion)
    }

    @ViewBuilder private func source(_ content: Content, appearance: TWResolvedStyle) -> some View {
        if let text {
            // Text attributes return Text, so changing them preserves the view's structural type.
            appearance.nativeSlots.filter { $0.utility.target == .text }.reduce(tracked(text, points: appearance.tracking)) { text, slot in
                slot.utility.apply(to: text, argument: slot.argument, active: slot.active, theme: theme)
            }
        } else if let image {
            appearance.nativeSlots.filter { $0.utility.target == .image }.reduce(image) { image, slot in
                slot.utility.apply(to: image, argument: slot.argument, active: slot.active, theme: theme)
            }
        } else if let shape {
            appearance.nativeSlots.filter { $0.utility.target == .shape }.reduce(shape) { shape, slot in
                slot.utility.apply(to: shape, argument: slot.argument, active: slot.active, theme: theme)
            }
        } else {
            content.onAppear {
                if appearance.tracking != nil {
                    Logger(subsystem: "swiftcn", category: "classes")
                        .error("Tracking requires .tw directly on a native Text value")
                }
            }
        }
    }

    private func tracked(_ text: Text, points: CGFloat?) -> Text {
        guard let points else { return text }
        return text.tracking(points)
    }
}

/// Only decoration changes conditionally; the main content keeps the same structure.
struct TWTextAttributesModifier: ViewModifier {
    let appearance: TWResolvedStyle

    func body(content: Content) -> some View {
        content
            .transformEnvironment(\.font) { inherited in
                if let font = appearance.font { inherited = font }
                if let weight = appearance.weight { inherited = (inherited ?? .body).weight(weight) }
            }
            .transformEnvironment(\.lineSpacing) { inherited in
                if let value = appearance.lineSpacing { inherited = value }
            }
            .transformEnvironment(\.multilineTextAlignment) { inherited in
                if let value = appearance.textAlignment { inherited = value }
            }
            .transformEnvironment(\.lineLimit) { inherited in
                if let value = appearance.lineLimit { inherited = value }
            }
            // Hierarchical primary is relative to the parent's style, including gradients.
            .foregroundStyle(appearance.foreground.map(AnyShapeStyle.init) ?? AnyShapeStyle(HierarchicalShapeStyle.primary))
    }
}

struct TWLayoutModifier: ViewModifier {
    let appearance: TWResolvedStyle
    func body(content: Content) -> some View {
        content.padding(appearance.padding)
            .frame(width: appearance.width, height: appearance.height)
            .frame(minWidth: appearance.minimumWidth,
                   maxWidth: appearance.maximumWidth ?? (appearance.expandsWidth ? .infinity : nil),
                   minHeight: appearance.minimumHeight, maxHeight: appearance.maximumHeight)
    }
}

struct TWDecorationModifier: ViewModifier {
    let appearance: TWResolvedStyle
    let scheme: ColorScheme
    func body(content: Content) -> some View {
        content.background {
                RoundedRectangle(cornerRadius: appearance.radius, style: .continuous)
                    .fill(appearance.background ?? .clear)
                    .shadow(
                        color: appearance.shadow?.color.resolve(scheme) ?? .clear,
                        radius: appearance.shadow?.radius ?? 0,
                        x: appearance.shadow?.x ?? 0,
                        y: appearance.shadow?.y ?? 0
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: appearance.radius, style: .continuous)
                    .strokeBorder(appearance.border ?? .clear, lineWidth: appearance.borderWidth)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

struct TWEffectsModifier: ViewModifier {
    let appearance: TWResolvedStyle
    func body(content: Content) -> some View {
        content.opacity(appearance.opacity)
            .blur(radius: appearance.blur)
            .scaleEffect(x: appearance.scale.width, y: appearance.scale.height)
            .rotationEffect(.degrees(appearance.rotation))
            .offset(appearance.offset)
    }
}

private func twShape<V: View>(_ view: V) -> AnyShape? {
    guard let shape = view as? any Shape else { return nil }
    return AnyShape(shape)
}

struct TWPhaseModifier: ViewModifier {
    let phase: TWModifierPhase
    let appearance: TWResolvedStyle
    let theme: TWTheme
    let scheme: ColorScheme
    let groups: TWGroupContext
    let scope: TWAnimationScope
    let watched: Bool
    let animationID: UUID
    let reduceMotion: Bool

    private var enabled: Bool {
        switch scope {
        case .all, .surface: true
        case .layout: phase == .layout
        case .content: phase == .content
        }
    }

    func body(content: Content) -> some View {
        content.transaction { transaction in
            // Restore the caller for stages outside the selected explicit preset.
            guard enabled && (!watched || scope == .all || transaction[TWAnimationChangeKey.self] == animationID) else {
                if let caller = transaction[TWCallerAnimationKey.self] { transaction.animation = caller.animation }
                return
            }
            appearance.motion.update(&transaction, reduceMotion: reduceMotion)
        } body: { surface in
            stage(surface)
                .modifier(TWNativeChainModifier(slots: appearance.nativeSlots, theme: theme, phase: phase))
        }
    }

    @ViewBuilder private func stage<V: View>(_ view: V) -> some View {
        switch phase {
        case .content: view.modifier(TWTextAttributesModifier(appearance: appearance))
        case .layout:
            view.modifier(TWClassSharedElementModifier(appearance: appearance, groups: groups))
                .modifier(TWLayoutModifier(appearance: appearance))
        case .decoration: view.modifier(TWDecorationModifier(appearance: appearance, scheme: scheme))
        case .effects: view.modifier(TWEffectsModifier(appearance: appearance))
        }
    }
}
