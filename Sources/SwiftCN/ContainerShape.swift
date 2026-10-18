import SwiftUI

extension View {
    /// Style a container and publish its outline to `rounded-container` descendants.
    public func twContainer(_ classes: TWClasses, state: TWState = TWState()) -> some View {
        tw(classes, state: state).modifier(TWContainerShapeModifier(style: .classes(classes), state: state))
    }
    @_disfavoredOverload public func twContainer(_ classes: String, state: TWState = TWState()) -> some View {
        twContainer(TWClasses(classes), state: state)
    }
    public func twContainer(_ styles: TWStyle..., state: TWState = TWState()) -> some View {
        tw(styles, state: state).modifier(TWContainerShapeModifier(style: TWStyle(styles), state: state))
    }
}

/// Publish a styled container's outline to native ContainerRelativeShape descendants.
/// Container boundaries opt in explicitly so text wrappers do not reset the enclosing shape.
struct TWContainerShapeModifier: ViewModifier {
    let style: TWStyle
    var state = TWState()
    @Environment(\.twTheme) private var theme
    @Environment(\.twRules) private var rules
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let appearance = TWStyleResolver.resolve(TWStyle(rules.view, style), theme: theme,
                                                scheme: scheme, state: state, globalRules: rules)
        if appearance.containerRelativeRadius {
            content
        } else {
            content.containerShape(appearance.outline)
        }
    }
}
