import SwiftUI
import SwiftCN

/// The divider alone owns its gesture; child scroll and control gestures remain native.
/// A normalized fraction supports persisted layout and accessible adjustment on both platforms.
public struct CNResizable<First: View, Second: View>: View {
    @Binding private var fraction: Double
    private let axis: Axis
    private let minimumFraction: Double
    private let classes: TWClasses
    private let first: First
    private let second: Second
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.layoutDirection) private var direction
    @Namespace private var coordinateSpace
    @GestureState private var isDragging = false
    @State private var drag: CNResizeDrag?
    @State private var dragInvalidated = false
    public init(fraction: Binding<Double>, axis: Axis = .horizontal, minimumFraction: Double = 0.15,
                classes: TWClasses = "", @ViewBuilder first: () -> First, @ViewBuilder second: () -> Second) {
        precondition(minimumFraction.isFinite && (0...0.5).contains(minimumFraction))
        _fraction = fraction; self.axis = axis; self.minimumFraction = minimumFraction; self.classes = classes
        self.first = first(); self.second = second()
    }
    public nonisolated static func clamp(_ value: Double, minimum: Double) -> Double {
        min(1 - minimum, max(minimum, value.isFinite ? value : 0.5))
    }
    public var body: some View {
        GeometryReader { geometry in
            let length = max(0, (axis == .horizontal ? geometry.size.width : geometry.size.height) - handleExtent)
            let split = Self.clamp(fraction, minimum: minimumFraction)
            let layout = axis == .horizontal ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            layout {
                first.frame(width: axis == .horizontal ? length * split : nil, height: axis == .vertical ? length * split : nil)
                handle(length: length)
                second.frame(width: axis == .horizontal ? length * (1 - split) : nil, height: axis == .vertical ? length * (1 - split) : nil)
            }.coordinateSpace(name: coordinateSpace)
                .onChange(of: geometry.size) { _, _ in invalidateDrag() }
        }.tw(cn("resizable", classes))
            .onChange(of: isDragging) { _, active in
                // GestureState also resets after system cancellation, which has no onEnded callback.
                if !active { drag = nil; dragInvalidated = false }
            }
            .onChange(of: isEnabled) { _, enabled in if !enabled { invalidateDrag() } }
            .onChange(of: axis) { _, _ in invalidateDrag() }
            .onChange(of: direction) { _, _ in invalidateDrag() }
    }
    private var handleExtent: CGFloat {
        #if os(macOS)
        12
        #else
        44
        #endif
    }
    private func handle(length: CGFloat) -> some View {
        ZStack {
            Color.clear
            Rectangle().tw(axis == .horizontal ? "resizable-handle w-[2]" : "resizable-handle h-[2]")
        }.frame(width: axis == .horizontal ? handleExtent : nil, height: axis == .vertical ? handleExtent : nil)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpace))
                .updating($isDragging) { _, active, transaction in
                    active = true
                    transaction.disablesAnimations = true
                }.onChanged { value in
                    guard isEnabled, length > 0, !dragInvalidated else { return }
                    // The containing split, rather than the moving divider, defines pointer coordinates.
                    // Capture the grab offset before publishing any binding change.
                    if drag == nil {
                        drag = CNResizeDrag(fraction: Self.clamp(fraction, minimum: minimumFraction),
                            start: position(value.startLocation, length: length), length: length)
                    }
                    update(at: value.location, length: length)
                }.onEnded { value in
                    if isEnabled && !dragInvalidated { update(at: value.location, length: length) }
                    drag = nil; dragInvalidated = false
                })
            .accessibilityElement().accessibilityLabel("Resize panels").accessibilityValue("\(Int(Self.clamp(fraction, minimum: minimumFraction) * 100)) percent")
            .accessibilityAdjustableAction { direction in
                guard isEnabled else { return }
                fraction = Self.clamp(Self.clamp(fraction, minimum: minimumFraction) +
                    (direction == .increment ? 0.05 : -0.05), minimum: minimumFraction)
            }
    }
    private func position(_ point: CGPoint, length: CGFloat) -> CGFloat {
        CNResizeDrag.position(point, axis: axis, direction: direction, length: length, handleExtent: handleExtent)
    }
    private func invalidateDrag() {
        if isDragging { dragInvalidated = true }
        drag = nil
    }
    private func update(at point: CGPoint, length: CGFloat) {
        guard let drag, length > 0 else { return }
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            fraction = drag.fraction(at: position(point, length: length), length: length, minimum: minimumFraction)
        }
    }
}

/// A pointer grab keeps its offset when the container or the divider moves.
struct CNResizeDrag {
    private let grabOffset: CGFloat
    static func position(_ point: CGPoint, axis: Axis, direction: LayoutDirection,
                         length: CGFloat, handleExtent: CGFloat) -> CGFloat {
        let coordinate = axis == .horizontal ? point.x : point.y
        let logical = axis == .horizontal && direction == .rightToLeft ? length + handleExtent - coordinate : coordinate
        return logical - handleExtent / 2
    }
    init(fraction: Double, start: CGFloat, length: CGFloat) {
        grabOffset = fraction * length - start
    }
    func fraction(at position: CGFloat, length: CGFloat, minimum: Double) -> Double {
        guard length.isFinite, length > 0, position.isFinite else { return 0.5 }
        return CNResizable<EmptyView, EmptyView>.clamp((position + grabOffset) / length, minimum: minimum)
    }
}
