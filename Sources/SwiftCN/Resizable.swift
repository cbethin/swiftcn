import SwiftUI

/// The divider alone owns its gesture; child scroll and control gestures remain native.
/// A normalized fraction supports persisted layout and accessible adjustment on both platforms.
public struct CNResizable<First: View, Second: View>: View {
    @Binding private var fraction: Double
    private let axis: Axis
    private let minimumFraction: Double
    private let classes: TWClasses
    private let first: First
    private let second: Second
    @GestureState private var dragStart: Double?
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
            }
        }.tw(cn("resizable", classes))
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
            .gesture(DragGesture().updating($dragStart) { _, start, _ in
                if start == nil { start = Self.clamp(fraction, minimum: minimumFraction) }
            }.onChanged { value in
                guard length > 0 else { return }
                let translation = axis == .horizontal ? value.translation.width : value.translation.height
                fraction = Self.clamp((dragStart ?? 0.5) + translation / length, minimum: minimumFraction)
            })
            .accessibilityElement().accessibilityLabel("Resize panels").accessibilityValue("\(Int(Self.clamp(fraction, minimum: minimumFraction) * 100)) percent")
            .accessibilityAdjustableAction { direction in
                fraction = Self.clamp(fraction + (direction == .increment ? 0.05 : -0.05), minimum: minimumFraction)
            }
    }
}
