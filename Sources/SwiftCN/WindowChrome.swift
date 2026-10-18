import SwiftUI

private struct CNIntegratedWindowKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var cnIntegratedWindow: Bool {
        get { self[CNIntegratedWindowKey.self] }
        set { self[CNIntegratedWindowKey.self] = newValue }
    }
}

private enum CNWindowControlSpace {
    static let width: CGFloat = 88
    static let height: CGFloat = 28
}

#if os(macOS)
extension WindowGroup {
    /// Hide the native title bar while retaining the standard window buttons.
    /// Apply `cnWindowContent()` to the window's root view as well.
    public func cnWindowStyle() -> some Scene { windowStyle(.hiddenTitleBar) }
}

extension Window {
    /// Hide the native title bar while retaining the standard window buttons.
    /// Apply `cnWindowContent()` to the window's root view as well.
    public func cnWindowStyle() -> some Scene { windowStyle(.hiddenTitleBar) }
}
#endif

extension View {
    /// Extend content through a hidden macOS title bar. Other platforms keep their safe areas.
    /// Pair this with `cnWindowStyle()` on the scene and reserve room for window controls.
    @ViewBuilder public func cnWindowContent() -> some View {
        #if os(macOS)
        ignoresSafeArea(.container, edges: .top).environment(\.cnIntegratedWindow, true)
        #else
        self
        #endif
    }
}

/// A themed window header with space for native traffic lights.
/// Set `reservesWindowControls` to false when a sidebar occupies the physical left edge.
/// On macOS 15 and later, dragging the empty header background moves the window.
public struct CNWindowHeader<Content: View>: View {
    @Environment(\.cnIntegratedWindow) private var integrated
    @Environment(\.layoutDirection) private var direction
    private let reservesWindowControls: Bool
    private let height: CGFloat
    private let classes: TWClasses
    private let content: Content

    public init(reservesWindowControls: Bool = true, height: CGFloat = 58,
                classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        precondition(height.isFinite && height > 0)
        self.reservesWindowControls = reservesWindowControls
        self.height = height
        self.classes = classes
        self.content = content()
    }

    public var body: some View {
        content
            .padding(contentInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background { dragArea }
            .tw(cn("bg-surface", classes))
    }

    private var contentInsets: EdgeInsets {
        let left = integrated && reservesWindowControls ? CNWindowControlSpace.width : 20
        return EdgeInsets(top: 0, leading: direction == .leftToRight ? left : 20,
                          bottom: 0, trailing: direction == .rightToLeft ? left : 20)
    }

    @ViewBuilder private var dragArea: some View {
        #if os(macOS)
        if #available(macOS 15, *), integrated {
            Color.clear.contentShape(Rectangle()).gesture(WindowDragGesture())
        }
        #endif
    }
}

/// Reserve native window-control space in a custom sidebar or title bar.
/// This spacer collapses outside a root with `cnWindowContent()`, including on iOS.
/// Place a horizontal spacer on the physical left, including in right-to-left layouts.
public struct CNWindowControlsSpacer: View {
    @Environment(\.cnIntegratedWindow) private var integrated
    private let axis: Axis

    public init(axis: Axis = .horizontal) { self.axis = axis }

    public var body: some View {
        Color.clear
            .frame(width: integrated && axis == .horizontal ? CNWindowControlSpace.width : 0,
                   height: integrated && axis == .vertical ? CNWindowControlSpace.height : 0)
            .accessibilityHidden(true).allowsHitTesting(false)
    }
}
