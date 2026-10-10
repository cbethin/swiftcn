import SwiftUI

/// A native Button. When its classes choose a native style (a button variant, `bezel-*`, or a glass surface),
/// Apple draws the bezel and the classes shape only the label. Other classes style the label of a plain button,
/// as list rows, menu items and calendar days need. Recognition, roles and activation remain with SwiftUI.
public struct TWButtonStyle: PrimitiveButtonStyle {
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
        TWButtonBody(configuration: configuration, style: style, state: state)
    }
}

extension PrimitiveButtonStyle where Self == TWButtonStyle {
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

private struct TWButtonBody: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: TWStyle
    let state: TWState
    private let inputs = TWSurfaceInputs()
    @Environment(\.twTheme) private var theme
    @Environment(\.twRules) private var rules
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let appearance = TWStyleResolver.resolve(TWStyle(rules.view, rules.button, style), theme: theme, scheme: scheme,
                                                 state: state, globalRules: rules)
        // The bezel is part of the button's design, so it selects a structure once, like a surface role.
        if let bezel = appearance.buttonBezel {
            TWNativeBezelButton(configuration: configuration, style: style, state: state, appearance: appearance,
                                bezel: bezel, glass: appearance.surface.map(inputs.context.usesGlass) ?? false,
                                fullRadius: theme.radius(.full))
        } else {
            Button(role: configuration.role, action: configuration.trigger) { configuration.label }
                .buttonStyle(TWPlainButtonStyle(style: style, state: state))
        }
    }
}

/// Apple draws the bezel, press, hover, focus and disabled appearance. Classes add the label's layout and type,
/// never another background.
private struct TWNativeBezelButton: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: TWStyle
    let state: TWState
    let appearance: TWResolvedStyle
    let bezel: TWButtonBezel
    let glass: Bool
    let fullRadius: CGFloat
    @Environment(\.isEnabled) private var isEnabled
    #if os(macOS)
    @Environment(\.controlActiveState) private var activeState
    #endif

    var body: some View {
        let button = Button(role: configuration.role, action: configuration.trigger) {
            configuration.label.modifier(TWModifier(style: style, state: state, isButton: true, decorates: false))
                .foregroundStyle(foreground)
        }
        .buttonBorderShape(borderShape)
        .transformEnvironment(\.controlSize) { size in
            if let value = appearance.controlSize { size = value }
        }
        .modifier(TWOptionalTint(color: appearance.glassTint))
        if #available(iOS 26, macOS 26, *), glass, bezel == .prominent || bezel == .bordered {
            if bezel == .prominent { button.buttonStyle(.glassProminent) } else { button.buttonStyle(.glass) }
        } else {
            switch bezel {
            case .prominent: button.buttonStyle(.borderedProminent)
            case .bordered: button.buttonStyle(.bordered)
            case .borderless: button.buttonStyle(.borderless)
            case .link:
                #if os(macOS)
                button.buttonStyle(.link)
                #else
                button.buttonStyle(.borderless)
                #endif
            }
        }
    }

    /// Native styles adopt any explicit foreground, so the label sets the style's own color unless a class does.
    private var foreground: AnyShapeStyle {
        // An explicit theme color would hide the native disabled appearance.
        #if os(macOS)
        if !isEnabled { return AnyShapeStyle(Color(nsColor: .disabledControlTextColor)) }
        #else
        if !isEnabled { return AnyShapeStyle(Color(uiColor: .tertiaryLabel)) }
        #endif
        #if os(macOS)
        // AppKit draws prominent bezels gray in an inactive window, with the system label color.
        if bezel == .prominent && activeState == .inactive { return AnyShapeStyle(Color.primary) }
        #endif
        if let color = appearance.foreground { return AnyShapeStyle(color) }
        if bezel == .prominent { return AnyShapeStyle(Color.white) }
        return glass ? AnyShapeStyle(HierarchicalShapeStyle.primary) : AnyShapeStyle(TintShapeStyle())
    }

    private var borderShape: ButtonBorderShape {
        guard appearance.hasRadius else { return .automatic }
        return appearance.radius >= fullRadius ? .capsule : .roundedRectangle(radius: appearance.radius)
    }
}

/// A plain button whose label carries the classes, including pressed, hover and focus states.
private struct TWPlainButtonStyle: ButtonStyle {
    let style: TWStyle
    let state: TWState

    func makeBody(configuration: Configuration) -> some View {
        var activeState = state
        activeState.isPressed = configuration.isPressed
        return configuration.label
            .modifier(TWModifier(style: style, state: activeState, isButton: true))
            .contentShape(.interaction, Rectangle())
    }
}

/// Applies a tint only when a class supplies one, so the inherited tint otherwise remains.
struct TWOptionalTint: ViewModifier {
    let color: Color?
    func body(content: Content) -> some View {
        if let color { content.tint(color) } else { content }
    }
}
