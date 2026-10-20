import SwiftUI

/// A native Button. When its classes choose a native style (`bezel-*` or a glass surface),
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
    @Environment(\.controlSize) private var controlSize
    @Environment(\.twTheme) private var theme
    @Environment(\.twRules) private var rules
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The state, with Reduce Motion, for `motion-reduce:` and `motion-safe:` classes.
    private var resolvedState: TWState {
        var state = self.state
        state.prefersReducedMotion = state.prefersReducedMotion || reduceMotion
        return state
    }

    var body: some View {
        let appearance = TWStyleResolver.resolve(TWStyle(rules.view, rules.button, style), theme: theme, scheme: scheme,
                                                 state: resolvedState, globalRules: rules, controlSize: controlSize)
        // The bezel is part of the button's design, so it selects a structure once, like a surface role.
        if let bezel = appearance.buttonBezel {
            let glass = appearance.buttonSurface.map(inputs.context.usesGlass) ?? false
            TWNativeBezelButton(configuration: configuration, style: style, state: state, appearance: appearance, bezel: bezel,
                                rendering: .resolve(bezel: bezel, glass: glass, engine: inputs.engine),
                                fullRadius: theme.radius(.full))
        } else {
            Button(role: configuration.role, action: configuration.trigger) { configuration.label }
                .buttonStyle(TWPlainButtonStyle(style: style, state: state))
        }
    }
}

/// How a button with a native bezel draws. The glass engine and the policy choose it, never accessibility,
/// so a button keeps one style type, and with it its identity, focus, and pending activation.
enum TWButtonRendering: Sendable, Hashable {
    /// SwiftUI's `.glass` or `.glassProminent` style.
    case swiftUIGlass(prominent: Bool)
    /// A plain button with UIKit's glass behind the label. SwiftUI's glass styles are never used.
    case uiKitGlass(prominent: Bool)
    case borderedProminent, bordered, borderless, link

    static func resolve(bezel: TWButtonBezel, glass: Bool, engine: TWGlassEngine) -> Self {
        if glass, bezel == .prominent || bezel == .bordered {
            switch engine {
            case .swiftUI: return .swiftUIGlass(prominent: bezel == .prominent)
            case .uiKit: return .uiKitGlass(prominent: bezel == .prominent)
            case .none: break
            }
        }
        switch bezel {
        case .prominent: return .borderedProminent
        case .bordered: return .bordered
        case .borderless: return .borderless
        case .link: return .link
        }
    }

    var isGlass: Bool {
        switch self {
        case .swiftUIGlass, .uiKitGlass: true
        default: false
        }
    }
}

/// Apple draws the bezel, press, hover, focus and disabled appearance. Classes add the label's layout and type,
/// never another background. UIKit's glass renderer draws glass buttons itself; see `TWUIKitGlassButtonStyle`.
private struct TWNativeBezelButton: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: TWStyle
    let state: TWState
    let appearance: TWResolvedStyle
    let bezel: TWButtonBezel
    let rendering: TWButtonRendering
    let fullRadius: CGFloat
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme
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
        .modifier(TWButtonTintModifier(inherits: appearance.inheritsTint, tint: appearance.glassTint))
        switch rendering {
        case .swiftUIGlass(let prominent):
            if #available(iOS 26, macOS 26, *) {
                if prominent { button.buttonStyle(.glassProminent) } else { button.buttonStyle(.glass) }
            } else if prominent {
                button.buttonStyle(.borderedProminent)
            } else {
                button.buttonStyle(.bordered)
            }
        case .uiKitGlass(let prominent):
            #if os(iOS)
            if #available(iOS 26, *) {
                button.buttonStyle(TWUIKitGlassButtonStyle(
                    prominent: prominent, tint: appearance.glassTint, radius: glassRadius,
                    surface: theme.color(.surface, scheme: scheme), edge: theme.color(.border, scheme: scheme),
                    strongEdge: theme.color(.input, scheme: scheme)))
            } else if prominent {
                button.buttonStyle(.borderedProminent)
            } else {
                button.buttonStyle(.bordered)
            }
            #else
            if prominent { button.buttonStyle(.borderedProminent) } else { button.buttonStyle(.bordered) }
            #endif
        case .borderedProminent: button.buttonStyle(.borderedProminent)
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

    /// UIKit glass buttons are capsules, like native glass buttons, unless a radius class asks for corners.
    private var glassRadius: CGFloat? {
        appearance.hasRadius && appearance.radius < fullRadius ? appearance.radius : nil
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
        return rendering.isGlass ? AnyShapeStyle(HierarchicalShapeStyle.primary) : AnyShapeStyle(TintShapeStyle())
    }

    private var borderShape: ButtonBorderShape {
        guard appearance.hasRadius else { return .automatic }
        return appearance.radius >= fullRadius ? .capsule : .roundedRectangle(radius: appearance.radius)
    }
}

/// Applies a tint class. Without one in any state, the button keeps the inherited tint: `.tint(nil)` would reset it.
/// The choice never depends on state, so hover and focus tints keep the button's structure. A state without its tint
/// uses the default tint.
private struct TWButtonTintModifier: ViewModifier {
    let inherits: Bool
    let tint: Color?

    func body(content: Content) -> some View {
        if inherits { content } else { content.tint(tint) }
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
