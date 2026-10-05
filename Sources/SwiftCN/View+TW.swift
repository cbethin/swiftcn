import SwiftUI

extension View {
    public func tw(_ classes: String, state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state))
    }

    /// Watch native state for layout and shared-element animation using these classes.
    public func tw<Value: Equatable>(_ classes: String, value: Value, state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state))
            .modifier(TWValueAnimationModifier(style: .classes(classes), value: value, state: state))
    }
    /// Apply one styled surface. Later utilities replace earlier values by property.
    public func tw(_ styles: TWStyle..., state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: TWStyle(styles), state: state))
    }

    /// Array overload for computed or shared style collections.
    public func tw(_ styles: [TWStyle], state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: TWStyle(styles), state: state))
    }
}

struct TWModifier: ViewModifier {
    let style: TWStyle
    var state: TWState
    var isButton = false
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
            globalRules: rules, groupStates: groups.states)
        return content
            .transaction { transaction in
                appearance.motion.update(&transaction, reduceMotion: reduceMotion)
            } body: { surface in
                surface.modifier(TWClassSharedElementModifier(appearance: appearance, groups: groups))
                    .modifier(TWAppearanceModifier(appearance: appearance, scheme: scheme))
            }
            .onHover { isHovered = $0 }
            .transformEnvironment(\.twGroups) { inherited in
                if let name = appearance.group {
                    inherited.scopes.append(TWGroupScope(name: name, namespace: groupNamespace, state: activeState))
                }
            }
    }
}

/// Only decoration changes conditionally; the main content keeps the same structure.
struct TWAppearanceModifier: ViewModifier {
    let appearance: TWResolvedStyle
    let scheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .transformEnvironment(\.font) { inherited in
                if let font = appearance.font { inherited = font }
                if let weight = appearance.weight { inherited = (inherited ?? .body).weight(weight) }
            }
            // Hierarchical primary is relative to the parent's style, including gradients.
            .foregroundStyle(appearance.foreground.map(AnyShapeStyle.init) ?? AnyShapeStyle(HierarchicalShapeStyle.primary))
            .padding(appearance.padding)
            .frame(width: appearance.width, height: appearance.height)
            .frame(maxWidth: appearance.expandsWidth ? .infinity : nil, minHeight: appearance.minimumHeight)
            .background {
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
            .opacity(appearance.opacity)
    }
}
