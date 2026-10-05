import SwiftUI

/// Appearance for a native Button. Recognition, roles, and activation remain with SwiftUI.
public struct TWButtonStyle: ButtonStyle {
    public var style: TWStyle
    public var state: TWState

    public init(_ styles: TWStyle..., state: TWState = TWState()) {
        style = TWStyle(styles)
        self.state = state
    }

    public func makeBody(configuration: Configuration) -> some View {
        var activeState = state
        activeState.isPressed = configuration.isPressed
        return configuration.label
            .modifier(TWModifier(style: style, state: activeState))
    }
}

extension ButtonStyle where Self == TWButtonStyle {
    public static func tw(_ styles: TWStyle..., state: TWState = TWState()) -> TWButtonStyle {
        TWButtonStyle(TWStyle(styles), state: state)
    }
}
