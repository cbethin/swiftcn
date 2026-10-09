import SwiftUI
import SwiftCN

private struct SheetSourceSpace: Equatable {
    var midX: CGFloat?
    var divisionX: CGFloat?
}

private extension EnvironmentValues {
    @Entry var sheetSourceSpace = SheetSourceSpace()
}

private enum SheetSide { case automatic, leading, trailing }

private struct SheetSourceHost: ViewModifier {
    @State private var space = SheetSourceSpace()
    func body(content: Content) -> some View {
        content.environment(\.sheetSourceSpace, space)
            .onGeometryChange(for: SheetSourceSpace.self) { proxy in
                let bounds = proxy.frame(in: .global)
                let division = proxy.cnDivisionRegions.first { $0.height > $0.width }
                // Keyboard height and vertical scrolling do not change a sheet's side.
                return SheetSourceSpace(midX: bounds.midX, divisionX: division.map { bounds.minX + $0.midX })
            } action: { space = $0 }
    }
}

private struct NativeSheetSide: ViewModifier {
    let side: SheetSide
    @ViewBuilder func body(content: Content) -> some View {
        #if canImport(SwiftUI, _version: 8.0.85.27)
        if #available(iOS 27.0, *) {
            content.presentationPlacement(side == .leading ? .leading : side == .trailing ? .trailing : .automatic)
        } else { content }
        #else
        content
        #endif
    }
}

/// Measure the trigger in the enclosing window, rather than its local split column.
private struct SheetSourceAnchor<Trigger: View, Presentation: View>: View {
    let trigger: Trigger
    let presentation: (Trigger, SheetSide) -> Presentation
    @Environment(\.sheetSourceSpace) private var space
    @Environment(\.layoutDirection) private var direction
    @State private var midX: CGFloat?
    private var side: SheetSide {
        guard let midX, let windowMidX = space.midX else { return .automatic }
        let left = midX < (space.divisionX ?? windowMidX)
        return left == (direction == .leftToRight) ? .leading : .trailing
    }
    var body: some View {
        presentation(trigger, side)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).midX } action: { midX = $0 }
    }
}

extension View {
    /// Install at the app root so triggers share one window coordinate space.
    func sheetSourceSpace() -> some View { modifier(SheetSourceHost()) }

    /// Attach to the button that opens the native sheet, not the whole split view.
    func sourceSheet<Sheet: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Sheet) -> some View {
        SheetSourceAnchor(trigger: self) { trigger, side in
            trigger.sheet(isPresented: isPresented) { content().modifier(NativeSheetSide(side: side)) }
        }
    }

    func sourceSheet<Item: Identifiable, Sheet: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Sheet) -> some View {
        SheetSourceAnchor(trigger: self) { trigger, side in
            trigger.sheet(item: item) { content($0).modifier(NativeSheetSide(side: side)) }
        }
    }
}
