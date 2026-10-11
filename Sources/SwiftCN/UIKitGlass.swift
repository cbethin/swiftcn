#if os(iOS)
import SwiftUI
import UIKit

// UIKit's Liquid Glass for surfaces and groups. `TWGlassRenderer` selects it; see that type for why.
// SwiftUI keeps every touch: the glass views only draw.

extension EnvironmentValues {
    /// The innermost UIKit glass group, which draws the glass of the surfaces it claims.
    @Entry var twGlassGroup: TWGlassGroup? = nil
}

@available(iOS 26, *) @MainActor
extension TWGlassStyle {
    var effect: UIGlassEffect { effect(tint: tint.map(UIColor.init)) }

    func effect(tint: UIColor?) -> UIGlassEffect {
        let glass = UIGlassEffect(style: .regular)
        glass.isInteractive = interactive
        glass.tintColor = tint
        return glass
    }

    var corners: UICornerConfiguration {
        radius.map { .capsule(maximumRadius: $0) } ?? .capsule()
    }
}

/// Draws a surface's glass behind its content, unless a group claims it.
/// Inside a group the surface reports its bounds, so the group can draw it in its container.
@available(iOS 26, *)
struct TWUIKitSurfaceGlassModifier: ViewModifier {
    /// Nil when another fill wins. Then no UIKit view exists.
    let style: TWGlassStyle?
    @Environment(\.twGlassGroup) private var group
    @Environment(\.twSurfaceGlassID) private var surfaceID
    @State private var ownID = UUID()

    func body(content: Content) -> some View {
        let id = surfaceID ?? TWGlassPieceID(value: ownID)
        content
            // A surface nested in this one keeps its own identity.
            .environment(\.twSurfaceGlassID, nil)
            .background {
                if let style { TWUIKitSurfaceGlass(style: style, id: id, group: group) }
            }
            .anchorPreference(key: TWGlassPieceKey.self, value: .bounds) { bounds in
                guard let style, group != nil else { return [] }
                return [TWGlassPiece(id: id, bounds: bounds, style: style)]
            }
    }
}

@available(iOS 26, *)
private struct TWUIKitSurfaceGlass: UIViewRepresentable {
    let style: TWGlassStyle
    let id: TWGlassPieceID
    let group: TWGlassGroup?

    func makeUIView(context: Context) -> TWGlassSlotView { TWGlassSlotView() }

    func updateUIView(_ view: TWGlassSlotView, context: Context) {
        let animation = TWGlassAnimation(context.transaction, animate: context.animate)
        view.update(style: style, id: id, group: group, animation: animation)
    }

    static func dismantleUIView(_ view: TWGlassSlotView, coordinator: ()) {
        view.update(style: nil, id: nil, group: nil, animation: TWGlassAnimation())
    }
}

/// A surface's own glass. It is empty while its group draws the surface.
@available(iOS 26, *)
final class TWGlassSlotView: UIView {
    private let glass = UIVisualEffectView()
    private var style: TWGlassStyle?
    private var drawn: TWGlassStyle?
    private var id: TWGlassPieceID?
    private weak var group: TWGlassGroup?

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        glass.frame = bounds
        glass.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(glass)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func update(style: TWGlassStyle?, id: TWGlassPieceID?, group: TWGlassGroup?, animation: TWGlassAnimation) {
        self.style = style
        self.id = id
        if group !== self.group {
            self.group?.slots.remove(self)
            group?.slots.add(self)
            self.group = group
        }
        refresh(animation)
    }

    /// Shows the glass unless the group draws this surface. Called again when the group's claims change.
    func refresh(_ animation: TWGlassAnimation) {
        let claimed = id.map { group?.claimed.contains($0) == true } ?? false
        let next = claimed ? nil : style
        guard next != drawn else { return }
        drawn = next
        animation.perform {
            self.glass.effect = next?.effect
            if let next { self.glass.cornerConfiguration = next.corners }
        }
    }
}

/// The surfaces a group draws. A surface outside the group's hierarchy, such as one in a sheet presented
/// from inside the group, never reaches its preferences, so it is never claimed and draws its own glass.
@MainActor final class TWGlassGroup {
    var claimed: Set<TWGlassPieceID> = []
    let slots = NSHashTable<UIView>.weakObjects()

    @available(iOS 26, *)
    func claim(_ ids: Set<TWGlassPieceID>, animation: TWGlassAnimation) {
        guard ids != claimed else { return }
        claimed = ids
        for case let slot as TWGlassSlotView in slots.allObjects { slot.refresh(animation) }
    }
}

struct TWGlassPiece {
    var id: TWGlassPieceID
    var bounds: Anchor<CGRect>
    var style: TWGlassStyle
}

struct TWGlassPieceKey: PreferenceKey {
    static var defaultValue: [TWGlassPiece] { [] }
    static func reduce(value: inout [TWGlassPiece], nextValue: () -> [TWGlassPiece]) { value += nextValue() }
}

/// A `GlassEffectContainer` drawn with `UIGlassContainerEffect`. Surfaces report their bounds by preference;
/// the group draws their glass in one container behind its content, so nearby shapes blend.
@available(iOS 26, *)
struct TWUIKitGlassGroup<Content: View>: View {
    let spacing: CGFloat?
    let content: Content
    @State private var group = TWGlassGroup()

    var body: some View {
        content
            .environment(\.twGlassGroup, group)
            .backgroundPreferenceValue(TWGlassPieceKey.self) { pieces in
                GeometryReader { proxy in
                    TWUIKitGlassContainer(spacing: spacing, group: group, pieces: pieces.map {
                        TWGlassFrame(id: $0.id, frame: proxy[$0.bounds], style: $0.style)
                    })
                }
            }
            // An enclosing group must not draw these surfaces again.
            .transformPreference(TWGlassPieceKey.self) { $0 = [] }
    }
}

struct TWGlassFrame {
    var id: TWGlassPieceID
    var frame: CGRect
    var style: TWGlassStyle
}

@available(iOS 26, *)
private struct TWUIKitGlassContainer: UIViewRepresentable {
    let spacing: CGFloat?
    let group: TWGlassGroup
    let pieces: [TWGlassFrame]

    final class Coordinator {
        var views: [TWGlassPieceID: UIVisualEffectView] = [:]
        var styles: [TWGlassPieceID: TWGlassStyle] = [:]
        /// Glass that is dematerializing, with a token so only the latest departure removes it.
        var leaving: [TWGlassPieceID: UUID] = [:]
        weak var group: TWGlassGroup?
    }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ container: UIVisualEffectView, context: Context) {
        let animation = TWGlassAnimation(context.transaction, animate: context.animate)
        let coordinator = context.coordinator
        coordinator.group = group
        let current = container.effect as? UIGlassContainerEffect
        if current == nil || spacing.map({ $0 != current?.spacing }) == true {
            let effect = UIGlassContainerEffect()
            if let spacing { effect.spacing = spacing }
            container.effect = effect
        }
        for piece in pieces {
            coordinator.leaving[piece.id] = nil
            if let view = coordinator.views[piece.id] {
                // Move existing glass with the transaction, so shapes morph alongside their content.
                let restyle = coordinator.styles[piece.id] != piece.style
                coordinator.styles[piece.id] = piece.style
                animation.perform {
                    view.frame = piece.frame
                    view.cornerConfiguration = piece.style.corners
                    if restyle || view.effect == nil { view.effect = piece.style.effect }
                }
            } else {
                // New glass starts empty in its final place and materializes.
                let view = UIVisualEffectView()
                UIView.performWithoutAnimation {
                    view.frame = piece.frame
                    view.cornerConfiguration = piece.style.corners
                }
                container.contentView.addSubview(view)
                coordinator.views[piece.id] = view
                coordinator.styles[piece.id] = piece.style
                animation.perform { view.effect = piece.style.effect }
            }
        }
        let live = Set(pieces.map(\.id))
        for (id, view) in coordinator.views where !live.contains(id) && coordinator.leaving[id] == nil {
            // Glass that leaves dematerializes, unless a piece with its identifier returns first.
            let token = UUID()
            coordinator.leaving[id] = token
            animation.perform({ view.effect = nil }) {
                guard coordinator.leaving[id] == token else { return }
                coordinator.leaving[id] = nil
                coordinator.views.removeValue(forKey: id)?.removeFromSuperview()
                coordinator.styles[id] = nil
            }
        }
        group.claim(live, animation: animation)
    }

    static func dismantleUIView(_ container: UIVisualEffectView, coordinator: Coordinator) {
        // Surfaces that outlive the container draw their own glass again.
        coordinator.group?.claim([], animation: TWGlassAnimation())
    }
}

/// A glass button drawn with UIKit, for the UIKit renderer, where SwiftUI's `.glass` and `.glassProminent`
/// styles are avoided. Sizes match the native glass styles: 28 points tall for small and mini controls,
/// 34 for regular, and 50 for large. The touch target is at least 44 points without changing layout.
/// Prominent glass takes the tint, or the inherited tint like the native style. Under Reduce Transparency
/// a themed solid fill replaces the glass view.
@available(iOS 26, *)
struct TWUIKitGlassButtonStyle: ButtonStyle {
    let prominent: Bool
    /// The `tint-*` or `glass-tint-*` color. Nil follows the inherited tint for prominent glass.
    let tint: Color?
    /// Nil is a capsule.
    let radius: CGFloat?
    /// The Reduce Transparency fallback for plain glass.
    let surface: Color
    let edge: Color

    func makeBody(configuration: Configuration) -> some View {
        TWUIKitGlassButtonBody(configuration: configuration, style: self)
    }
}

@available(iOS 26, *)
private struct TWUIKitGlassButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let style: TWUIKitGlassButtonStyle
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    var body: some View {
        let pressed = isEnabled && configuration.isPressed
        let metrics = TWGlassButtonMetrics(controlSize)
        let shape = style.radius.map { AnyShape(RoundedRectangle(cornerRadius: $0, style: .continuous)) } ?? AnyShape(Capsule())
        configuration.label
            // Native styles size their label for the control size unless the app or a class sets a font.
            .transformEnvironment(\.font) { font in if font == nil { font = metrics.font } }
            .padding(.horizontal, metrics.horizontalPadding)
            .frame(minHeight: metrics.height)
            .background {
                // Accessibility changes the background only; the label keeps its identity.
                if reduceTransparency {
                    fallback(shape)
                } else {
                    TWUIKitButtonGlass(tint: isEnabled ? style.tint : nil, followsTint: style.prominent && isEnabled,
                                       glassTint: style.prominent || style.tint != nil, radius: style.radius)
                }
            }
            .contentShape(.interaction, TWMinimumTargetShape())
            .contentShape(.hoverEffect, shape)
            .hoverEffect(.highlight)
            .scaleEffect(reduceMotion || !pressed ? 1 : 0.96)
            .opacity(pressed ? 0.78 : 1)
            .animation(reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.23, dampingFraction: 0.72), value: pressed)
    }

    @ViewBuilder private func fallback(_ shape: AnyShape) -> some View {
        if style.prominent {
            if !isEnabled {
                shape.fill(Color(uiColor: .tertiarySystemFill))
            } else if let tint = style.tint {
                shape.fill(tint)
            } else {
                shape.fill(.tint)
            }
        } else {
            shape.fill(style.surface).overlay(shape.stroke(style.edge, lineWidth: 1))
        }
    }
}

/// The native glass styles' metrics on iOS 27.
private struct TWGlassButtonMetrics {
    var height: CGFloat
    var horizontalPadding: CGFloat
    var font: Font

    init(_ size: ControlSize) {
        switch size {
        case .mini, .small: (height, horizontalPadding, font) = (28, 10, .subheadline)
        case .large, .extraLarge: (height, horizontalPadding, font) = (50, 20, .body)
        default: (height, horizontalPadding, font) = (34, 12, .body)
        }
    }
}

/// The bezel, grown to at least 44 points in each direction around its center.
private struct TWMinimumTargetShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: min(0, (rect.width - 44) / 2), dy: min(0, (rect.height - 44) / 2)))
    }
}

@available(iOS 26, *)
private struct TWUIKitButtonGlass: UIViewRepresentable {
    let tint: Color?
    /// Prominent glass without a tint class follows the inherited tint, as the native style does.
    let followsTint: Bool
    /// Plain glass without a tint class stays clear.
    let glassTint: Bool
    let radius: CGFloat?

    func makeUIView(context: Context) -> TWGlassButtonView { TWGlassButtonView() }

    func updateUIView(_ view: TWGlassButtonView, context: Context) {
        view.cornerConfiguration = TWGlassStyle(radius: radius).corners
        view.configure(tint: glassTint ? tint.map(UIColor.init) : nil, followsTint: followsTint && tint == nil)
    }
}

/// SwiftUI's tint reaches a hosted view's `tintColor`, so prominent glass follows it as it changes.
@available(iOS 26, *)
final class TWGlassButtonView: UIVisualEffectView {
    private var fixedTint: UIColor?
    private var followsTint = false
    private var applied: UIColor??

    init() {
        super.init(effect: nil)
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(tint: UIColor?, followsTint: Bool) {
        fixedTint = tint
        self.followsTint = followsTint
        apply()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        if followsTint { apply() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // The inherited tint is known only once the view joins SwiftUI's hierarchy.
        if followsTint { apply() }
    }

    private func apply() {
        let tint = followsTint ? tintColor : fixedTint
        guard applied != .some(tint) else { return }
        applied = .some(tint)
        effect = TWGlassStyle(tint: nil, interactive: true).effect(tint: tint)
    }
}

/// Applies UIKit changes with the SwiftUI transaction's animation, or immediately without one.
@MainActor struct TWGlassAnimation {
    typealias Animate = @MainActor (() -> Void, (() -> Void)?) -> Void
    private let animate: Animate?

    init() { animate = nil }

    /// `animate` is the representable context's, which bridges the SwiftUI animation to UIKit.
    init(_ transaction: Transaction, animate: @escaping Animate) {
        self.animate = transaction.animation == nil || transaction.disablesAnimations ? nil : animate
    }

    func perform(_ changes: @escaping () -> Void, completion: (() -> Void)? = nil) {
        if let animate {
            animate(changes, completion)
        } else {
            UIView.performWithoutAnimation(changes)
            completion?()
        }
    }
}
#endif
