import SwiftUI

/// Appearance for a native Button. Recognition, roles, and activation remain with SwiftUI.
public struct TWButtonStyle: ButtonStyle {
    public var style: TWStyle
    public var state: TWState

    @_disfavoredOverload public init(_ classes: String, state: TWState = TWState()) {
        style = .classes(classes)
        self.state = state
    }
    public init(_ classes: TWClasses, state: TWState = TWState()) {
        style = .classes(classes)
        self.state = state
    }

    public init(_ styles: TWStyle..., state: TWState = TWState()) {
        style = TWStyle(styles)
        self.state = state
    }

    public func makeBody(configuration: Configuration) -> some View {
        var activeState = state
        activeState.isPressed = configuration.isPressed
        return configuration.label
            .modifier(TWModifier(style: style, state: activeState, isButton: true))
    }
}

extension ButtonStyle where Self == TWButtonStyle {
    @_disfavoredOverload public static func tw(_ classes: String, state: TWState = TWState()) -> TWButtonStyle {
        TWButtonStyle(classes, state: state)
    }
    public static func tw(_ classes: TWClasses, state: TWState = TWState()) -> TWButtonStyle {
        TWButtonStyle(classes, state: state)
    }
    public static func tw(_ styles: TWStyle..., state: TWState = TWState()) -> TWButtonStyle {
        TWButtonStyle(TWStyle(styles), state: state)
    }
}
