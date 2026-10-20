import SwiftUI

struct TWContainerShapeContext {
    let space: Namespace.ID
    let outline: TWSurfaceShape
}

extension EnvironmentValues {
    @Entry var twContainerShapeContext: TWContainerShapeContext? = nil
}

/// Resolve inset artwork in the nearest rounded surface's coordinate space.
/// Only decoration uses the geometry reader; editor layout and identity stay intact.
struct TWContainerRelativeSurface<Content: View>: View {
    @Environment(\.twContainerShapeContext) private var container
    private let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        GeometryReader { geometry in
            if let container, let bounds = geometry.bounds(of: .named(container.space)) {
                // Recreate the enclosing native shape around the artwork. SwiftUI then
                // computes the inset corners, including asymmetric padding and placement.
                content.frame(width: geometry.size.width, height: geometry.size.height)
                    .padding(.leading, -bounds.minX).padding(.top, -bounds.minY)
                    .frame(width: bounds.width, height: bounds.height, alignment: .topLeading)
                    .containerShape(container.outline)
                    .offset(x: bounds.minX, y: bounds.minY)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                    .environment(\.layoutDirection, .leftToRight)
            } else {
                content
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
