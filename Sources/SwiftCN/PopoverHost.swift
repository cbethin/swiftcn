import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Place this at the window or screen root so popovers can extend beyond scrolling children.
public struct CNPopoverHost<Content: View>: View {
    private let content: Content
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.layoutDirection) private var direction
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.environment(\.cnPopoverHostAvailable, true)
            .overlayPreferenceValue(CNPopoverAnchorPreference.self) { requests in
                GeometryReader { geometry in
                    let visible = requests.filter(\.isPresented)
                    CNPopoverPointerLayer(holes: requests.map { geometry[$0.anchor] }, active: !visible.isEmpty, presentationIDs: visible.map(\.id),
                                          onDeactivate: { for request in visible { request.presentation.wrappedValue = false } }) {
                        ZStack(alignment: .topLeading) {
                            if !visible.isEmpty {
                                Color.clear
                                    .contentShape(CNPopoverBackdrop(holes: requests.map { geometry[$0.anchor] }), eoFill: true)
                                    .onTapGesture { for request in visible { request.presentation.wrappedValue = false } }
                                    .accessibilityHidden(true)
                                    .transition(.identity)
                            }
                            ForEach(requests) { request in
                                let anchor = geometry[request.anchor]
                                let bounds = CNPlacementRegions.preferred(in: geometry.cnPlacementRegions(layoutDirection: direction),
                                    near: CGPoint(x: anchor.midX, y: anchor.midY))
                                let edge = request.edge
                                let placementDirection = direction
                                let hostWidth = geometry.size.width
                                if request.isPresented {
                                    // Constrain the native viewport before requesting its ideal size.
                                    // The content keeps one identity as the host resizes.
                                    CNPopoverViewport(content: request.content,
                                        maximumSize: CGSize(width: max(0, bounds.width - 16), height: max(0, bounds.height - 16)))
                                        .alignmentGuide(.leading) { size in
                                            let x = CNPopoverPosition.origin(anchor: anchor,
                                                popup: CGSize(width: size.width, height: size.height),
                                                bounds: bounds, edge: edge, direction: placementDirection).x
                                            // Placement bounds are physical; the leading guide is logical.
                                            return placementDirection == .leftToRight ? -x : x + size.width - hostWidth
                                        }
                                        .alignmentGuide(.top) { size in
                                            -CNPopoverPosition.origin(anchor: anchor,
                                                popup: CGSize(width: size.width, height: size.height),
                                                bounds: bounds, edge: edge, direction: placementDirection).y
                                        }
                                        .accessibilityElement(children: .contain)
                                        .accessibilityAction(.escape) { request.presentation.wrappedValue = false }
                                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                }
                            }
                        }
                        // This full-window layer must not track hover over the
                        // native controls beneath it, including trigger holes.
                        .modifier(TWValueAnimationModifier(style: .classes("popover-motion"),
                            value: visible.map(\.id), tracksHover: false))
                        .onChange(of: visible.map(\.id)) { old, new in
                            guard let newest = new.first(where: { !old.contains($0) }) else { return }
                            for request in visible where request.id != newest { request.presentation.wrappedValue = false }
                        }
                        .onChange(of: isEnabled) { _, enabled in
                            if !enabled { for request in visible { request.presentation.wrappedValue = false } }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            // Nested hosts consume their own anchors.
            .transformPreference(CNPopoverAnchorPreference.self) { $0 = [] }
    }
}
private struct CNPopoverViewport<Content: View>: View {
    let content: Content
    let maximumSize: CGSize
    @State private var contentSize: CGSize?
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            content.fixedSize()
                .onGeometryChange(for: CGSize.self, of: { $0.size }) { contentSize = $0 }
        }
        // Preserve rounded shadows when no scrolling is needed. Oversized
        // content must still clip to its viewport, including after resizing.
        .scrollClipDisabled(contentSize.map { $0.width <= maximumSize.width && $0.height <= maximumSize.height } ?? false)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: maximumSize.width, maxHeight: maximumSize.height)
        .fixedSize()
    }
}
#if os(macOS)
// Native containers have separate hosting views. Pass trigger clicks through at
// the AppKit boundary, before SwiftUI's backdrop content shape can run.
private struct CNPopoverPointerLayer<Content: View>: NSViewRepresentable {
    let holes: [CGRect]
    let active: Bool
    let presentationIDs: [UUID]
    let onDeactivate: () -> Void
    @ViewBuilder let content: () -> Content
    func makeNSView(context: Context) -> CNPopoverHostingView {
        CNPopoverHostingView(rootView: AnyView(CNPopoverEnvironmentRoot(content: content(), environment: context.environment)))
    }
    func updateNSView(_ view: CNPopoverHostingView, context: Context) {
        let opening = active && presentationIDs != view.presentationIDs
        view.holes = holes
        view.active = active
        view.presentationIDs = presentationIDs
        view.onDeactivate = onDeactivate
        withTransaction(context.transaction) {
            view.rootView = AnyView(CNPopoverEnvironmentRoot(content: content(), environment: context.environment))
        }
        if opening, let window = view.window {
            window.makeFirstResponder(nil)
            window.makeFirstResponder(view)
        }
    }
}
private struct CNPopoverEnvironmentRoot<Content: View>: View {
    let content: Content
    let environment: EnvironmentValues
    // Copy public appearance values, not the originating hosting view's private
    // focus dispatch state. Forwarding the whole environment breaks arrow keys.
    var body: some View {
        content.transformEnvironment(\.self) { values in
            values.cnPresentationAppearance(from: environment)
            values.isEnabled = environment.isEnabled
            values.openURL = environment.openURL
            values.cnPopoverHostAvailable = true
        }
    }
}
private final class CNPopoverHostingView: NSHostingView<AnyView> {
    var holes: [CGRect] = []
    var active = false
    var presentationIDs: [UUID] = []
    var onDeactivate: () -> Void = {}
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        NotificationCenter.default.removeObserver(self, name: NSWindow.didResignKeyNotification, object: window)
        super.viewWillMove(toWindow: newWindow)
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            NotificationCenter.default.addObserver(self, selector: #selector(windowResigned),
                name: NSWindow.didResignKeyNotification, object: window)
        }
    }
    @objc private func windowResigned(_ notification: Notification) { onDeactivate() }
    override func cancelOperation(_ sender: Any?) {
        if active { onDeactivate() }
        else { super.cancelOperation(sender) }
    }
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        guard active, bounds.contains(local), !holes.contains(where: { $0.contains(local) }) else { return nil }
        return super.hitTest(point)
    }
}
#else
private struct CNPopoverPointerLayer<Content: View>: View {
    let holes: [CGRect]
    let active: Bool
    let presentationIDs: [UUID]
    let onDeactivate: () -> Void
    @ViewBuilder let content: () -> Content
    var body: some View { content() }
}
#endif
extension View {
    public func cnPopoverHost() -> some View { CNPopoverHost { self } }

    /// An in-tree popover keeps its trigger clickable during entry and exit.
    public func cnPopover<Popup: View>(isPresented: Binding<Bool>, arrowEdge: Edge = .top,
                                      @ViewBuilder content: @escaping () -> Popup) -> some View {
        modifier(CNAnchoredPopoverModifier(presentation: isPresented, edge: arrowEdge, popup: content))
    }
}
private struct CNAnchoredPopoverModifier<Popup: View>: ViewModifier {
    @Environment(\.cnPopoverHostAvailable) private var hosted
    @State private var id = UUID()
    let presentation: Binding<Bool>
    let edge: Edge
    let popup: () -> Popup
    private func anchored(_ content: Content) -> some View {
        content.anchorPreference(key: CNPopoverAnchorPreference.self, value: .bounds) { anchor in
            [CNPopoverAnchorRequest(id: id, anchor: anchor, edge: edge,
                                    isPresented: presentation.wrappedValue, presentation: presentation,
                                    content: AnyView(popup()))]
        }
        .onDisappear { presentation.wrappedValue = false }
        .onKeyPress(.escape) {
            guard presentation.wrappedValue else { return .ignored }
            presentation.wrappedValue = false
            return .handled
        }
    }
    @ViewBuilder func body(content: Content) -> some View {
        if hosted { anchored(content) }
        else {
            content.popover(isPresented: presentation, arrowEdge: edge) {
                popup().presentationCompactAdaptation(.popover)
            }
        }
    }
}
private struct CNPopoverAnchorRequest: Identifiable {
    let id: UUID
    let anchor: Anchor<CGRect>
    let edge: Edge
    let isPresented: Bool
    let presentation: Binding<Bool>
    let content: AnyView
}
private struct CNPopoverAnchorPreference: PreferenceKey {
    static var defaultValue: [CNPopoverAnchorRequest] { [] }
    static func reduce(value: inout [CNPopoverAnchorRequest], nextValue: () -> [CNPopoverAnchorRequest]) { value += nextValue() }
}
private struct CNPopoverHostAvailableKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    fileprivate var cnPopoverHostAvailable: Bool {
        get { self[CNPopoverHostAvailableKey.self] }
        set { self[CNPopoverHostAvailableKey.self] = newValue }
    }
}
private struct CNPopoverBackdrop: Shape {
    var holes: [CGRect]
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        for hole in holes { path.addRect(hole) }
        return path
    }
}
// Pure placement also covers small windows and all preferred sides.
enum CNPopoverPosition {
    static func origin(anchor: CGRect, popup: CGSize, bounds: CGRect, edge: Edge,
                       direction: LayoutDirection = .leftToRight) -> CGPoint {
        let gap: CGFloat = 6
        let margin: CGFloat = 8
        var x = anchor.minX
        var y = anchor.maxY + gap
        let physicalEdge: Edge = direction == .rightToLeft ? (edge == .leading ? .trailing : edge == .trailing ? .leading : edge) : edge
        switch physicalEdge {
        case .bottom:
            y = anchor.minY - gap - popup.height
            if y < bounds.minY + margin { y = anchor.maxY + gap }
        case .leading:
            x = anchor.maxX + gap; y = anchor.minY
            if x + popup.width > bounds.maxX - margin { x = anchor.minX - gap - popup.width }
        case .trailing:
            x = anchor.minX - gap - popup.width; y = anchor.minY
            if x < bounds.minX + margin { x = anchor.maxX + gap }
        default:
            if y + popup.height > bounds.maxY - margin { y = anchor.minY - gap - popup.height }
        }
        return CGPoint(x: max(bounds.minX + margin, min(x, bounds.maxX - margin - popup.width)),
                       y: max(bounds.minY + margin, min(y, bounds.maxY - margin - popup.height)))
    }
}
