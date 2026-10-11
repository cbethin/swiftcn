import SwiftUI

/// The corners of a glass piece, for SwiftUI's glass, UIKit's glass, and the solid fallback.
public enum TWGlassShape: Sendable, Hashable {
    case capsule
    /// A rounded rectangle. A radius larger than half the piece's height is clamped.
    case rounded(CGFloat)
    /// Separate radii for the top and bottom corners, as on a sheet.
    case edges(top: CGFloat, bottom: CGFloat)

    var shape: AnyShape {
        switch self {
        case .capsule: AnyShape(Capsule())
        case .rounded(let radius): AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        case .edges(let top, let bottom):
            AnyShape(UnevenRoundedRectangle(topLeadingRadius: top, bottomLeadingRadius: bottom,
                                            bottomTrailingRadius: bottom, topTrailingRadius: top, style: .continuous))
        }
    }
}

/// One glass shape in a `TWGlassCluster`, at a frame in the cluster's own coordinates.
public struct TWGlassPiece: Identifiable, Hashable, @unchecked Sendable {
    // The identifier is built only from `Hashable & Sendable` values.
    public var id: AnyHashable
    public var frame: CGRect
    public var shape: TWGlassShape
    public var tint: Color?
    /// Apple's touch and pointer response. SwiftUI keeps the touches, so UIKit's glass may not show it.
    public var interactive: Bool

    public init<ID: Hashable & Sendable>(id: ID, frame: CGRect, shape: TWGlassShape = .capsule,
                                         tint: Color? = nil, interactive: Bool = false) {
        self.id = AnyHashable(id)
        self.frame = frame
        self.shape = shape
        self.tint = tint
        self.interactive = interactive
    }
}

/// How UIKit glass follows frame changes in a `TWSurfaceGroup`. SwiftUI reports a group's frames on every animation
/// frame and gesture event, including `.offset` and `.scaleEffect`, so on iOS 27 both modes keep the glass on its content.
public enum TWGlassTracking: Sendable, Hashable {
    /// Bridges the SwiftUI transaction's animation to UIKit, so glass that appears or leaves materializes and dematerializes.
    case transaction
    /// Sets every frame as it arrives, and adds and removes glass at once, so UIKit never animates on top of frames
    /// that already change each frame. Choose it when your code drives the frames, as `twGlassFrames` does.
    case direct
}

extension EnvironmentValues {
    @Entry public var twGlassTracking: TWGlassTracking = .transaction
}

extension View {
    /// How UIKit glass in a `TWSurfaceGroup` follows frame changes. SwiftUI's glass follows its views itself.
    public func twGlassTracking(_ tracking: TWGlassTracking) -> some View {
        environment(\.twGlassTracking, tracking)
    }

    /// Draws glass behind the content at frames computed from `value` on every animation frame.
    /// SwiftUI interpolates `value` and calls `pieces` with it and the content's size each frame, and a gesture
    /// that sets `value` calls it on each event, so the glass follows exactly. Frames are in the content's coordinates.
    public func twGlassFrames<Value: VectorArithmetic & Sendable>(
        _ value: Value, spacing: CGFloat? = nil,
        pieces: @escaping (Value, CGSize) -> [TWGlassPiece]
    ) -> some View {
        modifier(TWGlassFramesModifier(animatableData: value, spacing: spacing, pieces: pieces))
    }
}

private struct TWGlassFramesModifier<Value: VectorArithmetic & Sendable>: ViewModifier, Animatable {
    nonisolated var animatableData: Value
    let spacing: CGFloat?
    let pieces: (Value, CGSize) -> [TWGlassPiece]

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                TWGlassCluster(spacing: spacing, pieces: pieces(animatableData, proxy.size))
            }
        }
    }
}

/// How a cluster draws. Reduce Transparency and the system choose it; the engine chooses the glass API.
enum TWGlassClusterRendering: Sendable, Hashable {
    case swiftUIGlass, uiKitGlass, material, solid

    static func resolve(_ context: TWSurfaceContext) -> Self {
        // Like glass buttons, clusters replace glass with the themed surface under Reduce Transparency.
        if context.reduceTransparency { return .solid }
        guard context.fill(for: .glass) == .glass else { return .material }
        switch context.engine {
        case .swiftUI: return .swiftUIGlass
        case .uiKit: return .uiKitGlass
        case .none: return .material
        }
    }
}

/// Glass shapes at frames the caller computes, drawn together so they blend within `spacing`.
/// The UIKit engine sets the frames directly in one `UIGlassContainerEffect`, adding and removing pieces by
/// identifier; the SwiftUI engine places `glassEffect` pieces in a `GlassEffectContainer`. Without glass, and under
/// Reduce Transparency, each piece is a themed fill with an edge. The cluster only draws: it takes no touches.
/// A repeated identifier draws once, with its first piece.
public struct TWGlassCluster: View {
    private let spacing: CGFloat?
    private let pieces: [TWGlassPiece]
    private let inputs = TWSurfaceInputs()
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init(spacing: CGFloat? = nil, pieces: [TWGlassPiece]) {
        self.spacing = spacing
        // ForEach needs unique identifiers, and the UIKit container keeps one view per identifier.
        var seen = Set<AnyHashable>()
        self.pieces = pieces.filter { seen.insert($0.id).inserted }
    }

    public var body: some View {
        rendered
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var rendered: some View {
        switch TWGlassClusterRendering.resolve(inputs.context) {
        case .uiKitGlass:
            #if os(iOS)
            if #available(iOS 26, *) {
                TWUIKitGlassContainer(spacing: spacing, tracking: .direct, group: nil, pieces: pieces.map {
                    TWGlassFrame(id: TWGlassPieceID(value: $0.id), slot: nil, frame: $0.frame,
                                 style: TWGlassStyle(tint: $0.tint, interactive: $0.interactive, shape: $0.shape))
                })
            } else {
                EmptyView()
            }
            #else
            EmptyView()
            #endif
        case .swiftUIGlass:
            if #available(iOS 26, macOS 26, *) {
                GlassEffectContainer(spacing: spacing) {
                    placed { piece in
                        Color.clear.glassEffect(.regular.tint(piece.tint).interactive(piece.interactive), in: piece.shape.shape)
                    }
                }
            } else {
                EmptyView()
            }
        case .material:
            placed { piece in fallback(piece, fill: AnyShapeStyle(.regularMaterial), edge: edge(material: true)) }
        case .solid:
            placed { piece in
                fallback(piece, fill: AnyShapeStyle(piece.tint ?? theme.color(.surface, scheme: scheme)), edge: edge(material: false))
            }
        }
    }

    private func placed<Piece: View>(@ViewBuilder _ piece: @escaping (TWGlassPiece) -> Piece) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(pieces) { item in
                piece(item)
                    .frame(width: max(0, item.frame.width), height: max(0, item.frame.height))
                    .offset(x: item.frame.minX, y: item.frame.minY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func fallback(_ piece: TWGlassPiece, fill: AnyShapeStyle, edge: Color) -> some View {
        piece.shape.shape.fill(fill).overlay(piece.shape.shape.stroke(edge, lineWidth: 1))
    }

    /// The same edge as surface fallbacks. Increase Contrast strengthens it.
    private func edge(material: Bool) -> Color {
        let color = theme.color(.border, scheme: scheme)
        return contrast == .increased ? theme.color(.input, scheme: scheme) : material ? color.opacity(0.7) : color
    }
}

/// Which pieces a glass container adds, keeps, and removes, by identifier, in the order they arrive.
/// A repeated identifier counts once.
struct TWGlassPieceDiff<ID: Hashable> {
    var inserted: [ID] = []
    var kept: [ID] = []
    var removed: [ID] = []

    init(current: some Collection<ID>, next: [ID]) {
        let existing = Set(current)
        var seen = Set<ID>()
        for id in next where seen.insert(id).inserted {
            if existing.contains(id) { kept.append(id) } else { inserted.append(id) }
        }
        removed = current.filter { !seen.contains($0) }
    }
}
