import SwiftUI
import os

extension View {
    public func tw(_ classes: String, state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state, text: self as? Text))
    }

    /// Watch native state for layout and shared-element animation using these classes.
    public func tw<Value: Equatable>(_ classes: String, value: Value, state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: .classes(classes), state: state, text: self as? Text))
            .modifier(TWValueAnimationModifier(style: .classes(classes), value: value, state: state))
    }
    /// Apply one styled surface. Later utilities replace earlier values by property.
    public func tw(_ styles: TWStyle..., state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: TWStyle(styles), state: state, text: self as? Text))
    }

    /// Array overload for computed or shared style collections.
    public func tw(_ styles: [TWStyle], state: TWState = TWState()) -> some View {
        modifier(TWModifier(style: TWStyle(styles), state: state, text: self as? Text))
    }
}

struct TWModifier: ViewModifier {
    let style: TWStyle
    var state: TWState
    var isButton = false
    var text: Text? = nil
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
        return source(content, appearance: appearance)
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

    @ViewBuilder private func source(_ content: Content, appearance: TWResolvedStyle) -> some View {
        if let text {
            // Text attributes return Text, so changing them preserves the view's structural type.
            tracked(text, points: appearance.tracking)
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
struct TWAppearanceModifier: ViewModifier {
    let appearance: TWResolvedStyle
    let scheme: ColorScheme

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
            .padding(appearance.padding)
            .frame(width: appearance.width, height: appearance.height)
            .frame(minWidth: appearance.minimumWidth,
                   maxWidth: appearance.maximumWidth ?? (appearance.expandsWidth ? .infinity : nil),
                   minHeight: appearance.minimumHeight, maxHeight: appearance.maximumHeight)
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
            .blur(radius: appearance.blur)
            .scaleEffect(x: appearance.scale.width, y: appearance.scale.height)
            .rotationEffect(.degrees(appearance.rotation))
            .offset(appearance.offset)
    }
}
