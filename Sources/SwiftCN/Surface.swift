import SwiftUI

/// How semantic surfaces choose a native appearance. The theme keeps colors, spacing, type, and radii.
public enum TWAppearance: Sendable, Hashable {
    /// Liquid Glass where the system uses it, a material before it, and a solid surface under Reduce Transparency.
    case automatic
    /// Prefer glass for floating surfaces, including in apps that request the compatibility design.
    case glass
    /// Use themed solid fills for floating surfaces and native sheets.
    case solid
}

extension EnvironmentValues {
    @Entry public var twAppearance: TWAppearance = .automatic
    /// Test override for the operating system's glass support. Nil reads the running system.
    @Entry var twGlassSupport: Bool? = nil
    /// True inside a presentation that keeps the system background. Custom content should then omit its own fill.
    @Entry public var twSystemPresentation = false
}

extension View {
    /// Set the appearance policy for semantic surfaces in this subtree. Local surface classes still take precedence.
    public func twAppearance(_ appearance: TWAppearance) -> some View {
        environment(\.twAppearance, appearance)
    }
}

/// The surface a view asks for. The policy and the system choose its fill.
enum TWSurfaceRole: Sendable, Hashable { case floating, solid, glass }

/// Every surface resolves to exactly one of these fills.
enum TWSurfaceFill: Sendable, Hashable { case glass, material, solid }

struct TWSurfaceContext: Sendable, Hashable {
    var appearance = TWAppearance.automatic
    var supportsGlass = false
    var requiresCompatibility = false
    var reduceTransparency = false

    /// Native glass and controls adapt to accessibility settings themselves; custom fallbacks do not.
    func fill(for role: TWSurfaceRole) -> TWSurfaceFill {
        if usesGlass(role) { return .glass }
        return role == .solid || role == .floating && appearance == .solid || reduceTransparency ? .solid : .material
    }

    /// Accessibility settings never change this answer, so native controls keep one style type.
    func usesGlass(_ role: TWSurfaceRole) -> Bool {
        guard supportsGlass else { return false }
        switch role {
        case .glass: return true
        case .solid: return false
        case .floating:
            switch appearance {
            case .automatic: return !requiresCompatibility
            case .glass: return true
            case .solid: return false
            }
        }
    }

    /// Native sheets keep the system background wherever the system draws glass.
    var keepsSystemPresentation: Bool { usesGlass(.floating) }

    static var systemSupportsGlass: Bool {
        if #available(iOS 26, macOS 26, *) { true } else { false }
    }

    /// Apps can ask the system to keep the earlier design. Automatic surfaces follow that request.
    static let systemRequiresCompatibility =
        Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool ?? false
}

/// Reads the inputs once at a stable boundary. Changes alter values, never the view structure.
struct TWSurfaceInputs: DynamicProperty {
    @Environment(\.twAppearance) private var appearance
    @Environment(\.twGlassSupport) private var glassSupport
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var context: TWSurfaceContext {
        TWSurfaceContext(appearance: appearance, supportsGlass: glassSupport ?? TWSurfaceContext.systemSupportsGlass,
                         requiresCompatibility: TWSurfaceContext.systemRequiresCompatibility,
                         reduceTransparency: reduceTransparency)
    }
}

/// Draws one surface behind the content: glass, a material, or a solid fill. Explicit borders and shadows remain.
struct TWSurfaceModifier: ViewModifier {
    let appearance: TWResolvedStyle
    let role: TWSurfaceRole
    let theme: TWTheme
    let scheme: ColorScheme
    private let inputs = TWSurfaceInputs()
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let fill = inputs.context.fill(for: role)
        // Keep the same modifiers in every state so accessibility changes preserve descendant state.
        if #available(iOS 26, macOS 26, *) {
            decorate(content.glassEffect(fill == .glass ? glass : .identity, in: shape), fill: fill)
        } else {
            decorate(content, fill: fill)
        }
    }

    private func decorate<V: View>(_ view: V, fill: TWSurfaceFill) -> some View {
        view.background {
                shape.fill(fillStyle(fill))
                    .shadow(color: fill == .glass ? .clear : appearance.shadow?.color.resolve(scheme) ?? .clear,
                            radius: appearance.shadow?.radius ?? 0,
                            x: appearance.shadow?.x ?? 0, y: appearance.shadow?.y ?? 0)
            }
            .overlay {
                shape.strokeBorder(border(fill) ?? .clear, lineWidth: borderWidth(fill))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }

    @available(iOS 26, macOS 26, *)
    private var glass: Glass {
        Glass.regular.tint(appearance.glassTint).interactive(appearance.glassInteractive)
    }

    /// Floating surfaces default to a capsule, like native glass. Radius classes select a rounded rectangle.
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: appearance.hasRadius ? appearance.radius : 10_000, style: .continuous)
    }

    private func fillStyle(_ fill: TWSurfaceFill) -> AnyShapeStyle {
        switch fill {
        case .glass: AnyShapeStyle(Color.clear)
        case .material: AnyShapeStyle(.regularMaterial)
        case .solid: AnyShapeStyle(appearance.background ?? theme.color(.surface, scheme: scheme))
        }
    }

    /// Fallbacks need an edge to separate them from content. Increase Contrast strengthens it.
    private func border(_ fill: TWSurfaceFill) -> Color? {
        if appearance.borderWidth > 0 { return appearance.border }
        guard fill != .glass else { return nil }
        let color = theme.color(.border, scheme: scheme)
        return contrast == .increased ? theme.color(.input, scheme: scheme) : fill == .material ? color.opacity(0.7) : color
    }

    private func borderWidth(_ fill: TWSurfaceFill) -> CGFloat {
        if appearance.borderWidth > 0 { return appearance.borderWidth }
        return fill == .glass ? 0 : 1
    }
}

/// Groups glass surfaces so nearby shapes blend and morph on systems with Liquid Glass.
/// Earlier systems show the content unchanged. Put a stack inside to arrange several surfaces.
public struct TWSurfaceGroup<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    public var body: some View {
        if #available(iOS 26, macOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

extension View {
    /// Morph identity for a glass surface inside a TWSurfaceGroup. Apply it after the surface's .tw classes.
    /// Other fills ignore the identifier; use native transitions for those.
    public func twSurfaceID<ID: Hashable & Sendable>(_ id: ID?, in namespace: Namespace.ID) -> some View {
        modifier(TWSurfaceIDModifier(id: id, namespace: namespace))
    }

    /// Native presentation background for a sheet. Systems with Liquid Glass keep the system sheet;
    /// earlier systems and the solid policy use the theme surface. Apply it at the sheet root.
    public func twPresentationSurface() -> some View {
        modifier(TWPresentationSurfaceModifier())
    }
}

private struct TWSurfaceIDModifier<ID: Hashable & Sendable>: ViewModifier {
    let id: ID?
    let namespace: Namespace.ID
    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            content.glassEffectID(id, in: namespace)
        } else {
            content
        }
    }
}

struct TWPresentationSurfaceModifier: ViewModifier {
    private let inputs = TWSurfaceInputs()
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        // The branch depends on the system and policy only, so accessibility changes keep the sheet's content.
        if inputs.context.keepsSystemPresentation {
            content.environment(\.twSystemPresentation, true)
        } else {
            content.presentationBackground(theme.color(.surface, scheme: scheme))
        }
    }
}

/// A native Button with a native style chosen by role. Glass styles need Liquid Glass; bordered styles serve
/// earlier systems and solid roles. Classes add spacing and typography to the label, never another background.
public struct TWNativeButtonStyle: PrimitiveButtonStyle {
    public var style: TWStyle
    public var state: TWState

    @_disfavoredOverload public init(_ classes: String, state: TWState = TWState()) {
        style = .classes(classes)
        self.state = state
    }
    public init(_ classes: TWClasses = "glass", state: TWState = TWState()) {
        style = .classes(classes)
        self.state = state
    }
    public init(_ styles: TWStyle..., state: TWState = TWState()) {
        style = TWStyle(styles)
        self.state = state
    }

    public func makeBody(configuration: Configuration) -> some View {
        TWNativeButtonBody(configuration: configuration, style: style, state: state)
    }
}

extension PrimitiveButtonStyle where Self == TWNativeButtonStyle {
    @_disfavoredOverload public static func twNative(_ classes: String, state: TWState = TWState()) -> Self {
        TWNativeButtonStyle(classes, state: state)
    }
    public static func twNative(_ classes: TWClasses = "glass", state: TWState = TWState()) -> Self {
        TWNativeButtonStyle(classes, state: state)
    }
    public static func twNative(_ styles: TWStyle..., state: TWState = TWState()) -> Self {
        TWNativeButtonStyle(TWStyle(styles), state: state)
    }
}

private struct TWNativeButtonBody: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: TWStyle
    let state: TWState
    private let inputs = TWSurfaceInputs()
    @Environment(\.twTheme) private var theme
    @Environment(\.twRules) private var rules
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let appearance = TWStyleResolver.resolve(TWStyle(rules.view, style), theme: theme, scheme: scheme,
                                                 state: state, globalRules: rules)
        let glass = inputs.context.usesGlass(appearance.surface ?? .floating)
        let prominent = appearance.prominent
        // A text color class on any ancestor, such as a card, sets an explicit foreground that native styles would adopt.
        let foreground = appearance.foreground.map(AnyShapeStyle.init) ?? (prominent ? AnyShapeStyle(Color.white)
            : glass ? AnyShapeStyle(HierarchicalShapeStyle.primary) : AnyShapeStyle(TintShapeStyle()))
        let button = Button(role: configuration.role, action: configuration.trigger) {
            configuration.label.modifier(TWModifier(style: style, state: state, decorates: false))
                .foregroundStyle(foreground)
        }
        .modifier(TWOptionalTint(color: appearance.glassTint))
        if #available(iOS 26, macOS 26, *), glass {
            if prominent { button.buttonStyle(.glassProminent) } else { button.buttonStyle(.glass) }
        } else {
            if prominent { button.buttonStyle(.borderedProminent) } else { button.buttonStyle(.bordered) }
        }
    }
}

/// Applies a tint only when a class supplies one, so the inherited tint otherwise remains.
private struct TWOptionalTint: ViewModifier {
    let color: Color?
    func body(content: Content) -> some View {
        if let color { content.tint(color) } else { content }
    }
}
