import SwiftUI
#if os(macOS)
import AppKit
#endif

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
    /// Reserve room for window controls. Use `cnWindowStyle()` on Window and WindowGroup
    /// for the initial presentation; Settings scenes need only this content modifier.
    @ViewBuilder public func cnWindowContent() -> some View {
        #if os(macOS)
        ignoresSafeArea(.container, edges: .top)
            .environment(\.cnIntegratedWindow, true)
            .background { CNWindowChromeBridge().frame(width: 0, height: 0) }
        #else
        self
        #endif
    }
}

#if os(macOS)
/// Settings does not honor WindowGroup's window-style modifier. Configure only the
/// window that hosts this root, and restore its original chrome when the root leaves.
private struct CNWindowChromeBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> CNWindowChromeView { CNWindowChromeView() }
    func updateNSView(_ view: CNWindowChromeView, context: Context) { view.attach() }
    static func dismantleNSView(_ view: CNWindowChromeView, coordinator: ()) { view.invalidate() }
}

private final class CNWindowChromeView: NSView {
    private weak var controlledWindow: NSWindow?
    private var active = true

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        attach()
        // SwiftUI can finish setting up a Settings window after attaching its content.
        DispatchQueue.main.async { [weak self] in self?.attach() }
    }

    func attach() {
        guard active else { return }
        if controlledWindow !== window {
            detach()
            controlledWindow = window
        }
        if let window { CNWindowChromeLease.acquire(window, owner: ObjectIdentifier(self)) }
    }

    func detach() {
        if let controlledWindow { CNWindowChromeLease.release(controlledWindow, owner: ObjectIdentifier(self)) }
        controlledWindow = nil
    }

    func invalidate() {
        active = false
        detach()
    }
}

@MainActor private final class CNWindowChromeLease {
    private static var windows: [ObjectIdentifier: CNWindowChromeLease] = [:]
    private weak var window: NSWindow?
    private var owners: Set<ObjectIdentifier> = []
    private let titleVisibility: NSWindow.TitleVisibility
    private let transparent: Bool
    private let separator: NSTitlebarSeparatorStyle
    private let fullSize: Bool

    private init(_ window: NSWindow) {
        self.window = window
        titleVisibility = window.titleVisibility
        transparent = window.titlebarAppearsTransparent
        separator = window.titlebarSeparatorStyle
        fullSize = window.styleMask.contains(.fullSizeContentView)
    }

    static func acquire(_ window: NSWindow, owner: ObjectIdentifier) {
        windows = windows.filter { $0.value.window != nil }
        let key = ObjectIdentifier(window)
        let lease = windows[key] ?? CNWindowChromeLease(window)
        windows[key] = lease
        lease.owners.insert(owner)
        if window.titleVisibility != .hidden { window.titleVisibility = .hidden }
        if !window.titlebarAppearsTransparent { window.titlebarAppearsTransparent = true }
        if window.titlebarSeparatorStyle != .none { window.titlebarSeparatorStyle = .none }
        if !window.styleMask.contains(.fullSizeContentView) { window.styleMask.insert(.fullSizeContentView) }
    }

    static func release(_ window: NSWindow, owner: ObjectIdentifier) {
        let key = ObjectIdentifier(window)
        guard let lease = windows[key] else { return }
        lease.owners.remove(owner)
        guard lease.owners.isEmpty else { return }
        windows.removeValue(forKey: key)
        window.titleVisibility = lease.titleVisibility
        window.titlebarAppearsTransparent = lease.transparent
        window.titlebarSeparatorStyle = lease.separator
        if !lease.fullSize { window.styleMask.remove(.fullSizeContentView) }
    }
}
#endif

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
