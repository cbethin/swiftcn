import SwiftUI

/// Fits actions in a row, then stacks them when their natural widths do not fit.
/// The same child views remain in the layout; resizing does not replace controls.
public struct CNAdaptiveActionLayout: Layout {
    public var spacing: CGFloat
    public var verticalAlignment: HorizontalAlignment

    public init(spacing: CGFloat = 8, verticalAlignment: HorizontalAlignment = .leading) {
        self.spacing = spacing; self.verticalAlignment = verticalAlignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let layout = layout(width: proposal.width, subviews: subviews)
        var nativeCache = layout.makeCache(subviews: subviews)
        return layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &nativeCache)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = layout(width: bounds.width, subviews: subviews)
        var nativeCache = layout.makeCache(subviews: subviews)
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &nativeCache)
    }

    private func layout(width: CGFloat?, subviews: Subviews) -> AnyLayout {
        let ideal = subviews.reduce(CGFloat.zero) { $0 + $1.sizeThatFits(.unspecified).width }
            + spacing * CGFloat(max(0, subviews.count - 1))
        if let width, ideal > width {
            return AnyLayout(VStackLayout(alignment: verticalAlignment, spacing: spacing))
        }
        return AnyLayout(HStackLayout(alignment: .center, spacing: spacing))
    }
}
