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

/// Which framework draws Liquid Glass surfaces and groups. Fills, roles, and the appearance policy are unchanged.
public enum TWGlassRenderer: Sendable, Hashable {
    /// UIKit's glass on iOS 27 and later, and SwiftUI's glass elsewhere.
    /// On a physical iPhone running iOS 27.0.1, SwiftUI's `glassEffect` stopped the window redrawing; UIKit's glass did not.
    case automatic
    /// SwiftUI's `glassEffect` and `GlassEffectContainer`.
    case swiftUI
    /// UIKit's `UIGlassEffect` and `UIGlassContainerEffect` where UIKit draws glass (iOS 26 and later).
    /// Other systems use SwiftUI's glass.
    case uiKit
}

extension EnvironmentValues {
    @Entry public var twAppearance: TWAppearance = .automatic
    /// Set it once, near the root. Changing it rebuilds the surfaces below.
    @Entry public var twGlassRenderer: TWGlassRenderer = .automatic
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

    /// Choose the framework that draws glass in this subtree. Set it once, near the root:
    /// a change rebuilds the surfaces below, unlike appearance and accessibility changes.
    public func twGlassRenderer(_ renderer: TWGlassRenderer) -> some View {
        environment(\.twGlassRenderer, renderer)
    }
}

/// The surface a view asks for. The policy and the system choose its fill.
enum TWSurfaceRole: Sendable, Hashable { case floating, solid, glass }

/// Every surface resolves to exactly one of these fills.
enum TWSurfaceFill: Sendable, Hashable { case glass, material, solid }

/// The API that draws glass. It depends on the system and the renderer setting, never on accessibility,
/// so it selects a surface's view structure once.
enum TWGlassEngine: Sendable, Hashable {
    /// No glass API. Glass fills draw nothing; other fills draw as usual.
    case none
    /// SwiftUI's `glassEffect`, applied in every state so the structure stays fixed.
    case swiftUI
    /// UIKit's `UIGlassEffect` behind the content. SwiftUI's glass is never applied, not even `.identity`.
    case uiKit

    /// UIKit draws Liquid Glass on iOS 26 and later.
    static var systemSupportsUIKitGlass: Bool {
        #if os(iOS)
        if #available(iOS 26, *) { return true }
        #endif
        return false
    }

    /// On a physical iPhone running iOS 27.0.1, SwiftUI's glass anywhere in a window stopped it redrawing
    /// while state and touches kept working. UIKit's glass renders. The simulators never froze. Mac Catalyst keeps SwiftUI.
    static var systemPrefersUIKitGlass: Bool {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 27, *) { return true }
        #endif
        return false
    }
}

extension TWGlassRenderer {
    /// Inputs are fixed for the life of the process; tests pass them explicitly.
    func engine(swiftUIGlass: Bool = TWSurfaceContext.systemSupportsGlass,
                uiKitGlass: Bool = TWGlassEngine.systemSupportsUIKitGlass,
                prefersUIKit: Bool = TWGlassEngine.systemPrefersUIKitGlass) -> TWGlassEngine {
        let fallback: TWGlassEngine = swiftUIGlass ? .swiftUI : .none
        switch self {
        case .automatic: return uiKitGlass && prefersUIKit ? .uiKit : fallback
        case .swiftUI: return fallback
        case .uiKit: return uiKitGlass ? .uiKit : fallback
        }
    }
}

/// The glass a surface applies. Only `.swiftUI` calls SwiftUI's `glassEffect`.
enum TWGlassLayer: Sendable, Hashable {
    case none
    /// SwiftUI's `glassEffect`: real glass when active, `.identity` otherwise.
    case swiftUI(active: Bool)
    /// A UIKit glass view behind the content.
    case uiKit
}

struct TWSurfaceContext: Sendable, Hashable {
    var appearance = TWAppearance.automatic
    var supportsGlass = false
    var requiresCompatibility = false
    var reduceTransparency = false
    var engine = TWGlassEngine.swiftUI

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

    /// The glass layer for a role. The engine fixes which API is used; the fill only decides whether it draws.
    func glassLayer(for role: TWSurfaceRole) -> TWGlassLayer {
        let glass = fill(for: role) == .glass
        switch engine {
        case .none: return .none
        case .swiftUI: return .swiftUI(active: glass)
        case .uiKit: return glass ? .uiKit : .none
        }
    }

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
    @Environment(\.twGlassRenderer) private var renderer
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var context: TWSurfaceContext {
        TWSurfaceContext(appearance: appearance, supportsGlass: glassSupport ?? TWSurfaceContext.systemSupportsGlass,
                         requiresCompatibility: TWSurfaceContext.systemRequiresCompatibility,
                         reduceTransparency: reduceTransparency, engine: engine)
    }

    var engine: TWGlassEngine { renderer.engine() }
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
        let context = inputs.context
        let fill = context.fill(for: role)
        let layer = context.glassLayer(for: role)
        // The engine selects the structure. Each branch keeps the same modifiers in every state,
        // so accessibility and policy changes preserve descendant state.
        switch context.engine {
        case .swiftUI:
            if #available(iOS 26, macOS 26, *) {
                decorate(content.glassEffect(layer == .swiftUI(active: true) ? glass : .identity, in: shape), fill: fill)
            } else {
                decorate(content, fill: fill)
            }
        case .uiKit:
            #if os(iOS)
            if #available(iOS 26, *) {
                decorate(content.modifier(TWUIKitSurfaceGlassModifier(style: layer == .uiKit ? uiKitGlass : nil)), fill: fill)
            } else {
                decorate(content, fill: fill)
            }
            #else
            decorate(content, fill: fill)
            #endif
        case .none:
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

    /// The same glass for UIKit. A nil radius is a capsule.
    private var uiKitGlass: TWGlassStyle {
        TWGlassStyle(tint: appearance.glassTint, interactive: appearance.glassInteractive,
                     radius: appearance.hasRadius ? appearance.radius : nil)
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

/// One surface's glass, as UIKit draws it.
struct TWGlassStyle: Hashable {
    var tint: Color?
    var interactive = false
    /// Nil is a capsule. A radius larger than half the shape's height is clamped, like a rounded rectangle.
    var radius: CGFloat?
}

/// A surface's identity within a group: its `twSurfaceID`, or one the surface keeps for itself.
struct TWGlassPieceID: Hashable, @unchecked Sendable {
    // Built only from `Hashable & Sendable` values.
    var namespace: Namespace.ID?
    var value: AnyHashable
}

extension EnvironmentValues {
    /// The `twSurfaceID` applied outside a surface's classes. The surface clears it for its content.
    @Entry var twSurfaceGlassID: TWGlassPieceID? = nil
}

/// Groups glass surfaces so nearby shapes blend and morph on systems with Liquid Glass.
/// Earlier systems show the content unchanged. Put a stack inside to arrange several surfaces.
/// With UIKit's renderer the group draws its surfaces' glass in one `UIGlassContainerEffect` behind its content.
public struct TWSurfaceGroup<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content
    private let inputs = TWSurfaceInputs()
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    public var body: some View {
        switch inputs.engine {
        case .swiftUI:
            if #available(iOS 26, macOS 26, *) {
                GlassEffectContainer(spacing: spacing) { content }
            } else {
                content
            }
        case .uiKit:
            #if os(iOS)
            if #available(iOS 26, *) {
                TWUIKitGlassGroup(spacing: spacing, content: content)
            } else {
                content
            }
            #else
            content
            #endif
        case .none:
            content
        }
    }
}

extension View {
    /// Morph identity for a glass surface inside a TWSurfaceGroup. Apply it after the surface's .tw classes.
    /// Other fills ignore the identifier; use native transitions for those.
    /// With UIKit's renderer, a surface that leaves and one that arrives with the same identifier share one glass shape,
    /// which moves and resizes with the transaction's animation.
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
    private let inputs = TWSurfaceInputs()
    func body(content: Content) -> some View {
        switch inputs.engine {
        case .swiftUI:
            if #available(iOS 26, macOS 26, *) {
                content.glassEffectID(id, in: namespace)
            } else {
                content
            }
        case .uiKit:
            content.environment(\.twSurfaceGlassID, id.map { TWGlassPieceID(namespace: namespace, value: AnyHashable($0)) })
        case .none:
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
