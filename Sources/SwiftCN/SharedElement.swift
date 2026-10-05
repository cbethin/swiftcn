import SwiftUI

extension View {
    /// Pair native geometry within an application-owned namespace.
    /// Apply before a fixed frame to interpolate size, or after styling to match a whole surface.
    public func twShared<ID: Hashable>(
        _ id: ID, in namespace: Namespace.ID,
        properties: MatchedGeometryProperties = .frame,
        anchor: UnitPoint = .center, isSource: Bool = true
    ) -> some View {
        modifier(TWSharedElementModifier(id: id, namespace: namespace,
            properties: properties, anchor: anchor, isSource: isSource))
    }
}

private struct TWSharedElementModifier<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID
    let properties: MatchedGeometryProperties
    let anchor: UnitPoint
    let isSource: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.transaction { transaction in
            if reduceMotion { transaction.animation = nil }
        } body: { element in
            element.matchedGeometryEffect(id: id, in: namespace,
                properties: properties, anchor: anchor, isSource: isSource)
        }
    }
}
