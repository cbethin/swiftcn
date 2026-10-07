import SwiftUI
import SwiftCN

/// Install once at a window or screen root, outside scrolling and native containers.
/// Panels inherit the theme and rules without creating a second native window.
/// Place shared environment dependencies above the host; inject presenter-local dependencies inside panel content.
public struct CNPresentationHost<Content: View>: View {
    private let content: Content
    @State private var active: [UUID] = []
    @Environment(\.layoutDirection) private var direction
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.environment(\.cnPresentationHosted, true)
            .disabled(!active.isEmpty).accessibilityHidden(!active.isEmpty)
            .overlayPreferenceValue(CNPresentationRequests.self) { requests in
                GeometryReader { geometry in
                    ZStack {
                        ForEach(requests) { request in
                            let regions = geometry.cnPlacementRegions(layoutDirection: direction)
                            let placement = CNPlacementRegions.preferred(in: regions,
                                near: request.kind.preferredPoint(in: geometry.size, direction: direction))
                            CNPresentationPanel(request: request, size: geometry.size, placement: placement)
                                .transformEnvironment(\.self) { values in
                                    // Preserve public appearance without importing private focus dispatch state.
                                    values.cnPresentationAppearance(from: request.environment)
                                }
                        }
                    }.frame(width: geometry.size.width, height: geometry.size.height)
                        .onChange(of: requests.filter { $0.presentation.wrappedValue }.map(\.id)) { old, new in
                            guard let newest = new.first(where: { !old.contains($0) }) else { return }
                            for request in requests where request.id != newest && request.presentation.wrappedValue {
                                request.presentation.wrappedValue = false
                            }
                        }
                }
            }
            .onPreferenceChange(CNPresentationPresence.self) { active = $0 }
            .transformPreference(CNPresentationRequests.self) { $0 = [] }
            .transformPreference(CNPresentationPresence.self) { $0 = [] }
    }
}

extension View {
    public func cnPresentationHost() -> some View { CNPresentationHost { self } }
}

private enum CNPresentationKind {
    case dialog, sheet(Edge)
    func preferredPoint(in size: CGSize, direction: LayoutDirection) -> CGPoint {
        switch self {
        case .dialog: CGPoint(x: size.width / 2, y: size.height / 2)
        case .sheet(.top): CGPoint(x: size.width / 2, y: 0)
        case .sheet(.bottom): CGPoint(x: size.width / 2, y: size.height)
        case .sheet(let edge): CGPoint(x: (edge == .leading) == (direction == .leftToRight) ? 0 : size.width, y: size.height / 2)
        }
    }
    var recipe: TWClasses {
        switch self {
        case .dialog: "presentation-dialog"
        case .sheet: "presentation-sheet"
        }
    }
    var alignment: Alignment {
        switch self {
        case .dialog: .center
        case .sheet(.bottom): .bottom
        case .sheet(.top): .top
        case .sheet(.leading): .leading
        case .sheet: .trailing
        }
    }
}

private struct CNPresentationTrigger<Label: View, Popup: View>: View {
    @Binding var isPresented: Bool
    let kind: CNPresentationKind
    let classes: TWClasses
    let contentClasses: TWClasses
    @ViewBuilder let content: () -> Popup
    @ViewBuilder let label: () -> Label
    @Environment(\.cnPresentationHosted) private var hosted
    @Environment(\.self) private var environment
    @Environment(\.isEnabled) private var enabled
    @State private var id = UUID()
    @State private var restoreFocus = false
    @FocusState private var triggerFocused: Bool
    var body: some View {
        let trigger = Button(action: { isPresented = true }, label: label)
            .focusable().focusEffectDisabled().focused($triggerFocused)
            .buttonStyle(.tw(cn("button-outline", classes), state: .init(isFocused: triggerFocused)))
            .onKeyPress(keys: [.return, .space]) { _ in isPresented = true; return .handled }
            .onChange(of: isPresented, initial: true) { _, open in
                if open { restoreFocus = true; triggerFocused = false }
            }
            .task(id: enabled && restoreFocus && !isPresented) {
                guard enabled && restoreFocus && !isPresented else { return }
                // Let the closing panel release focus and the trigger rejoin the enabled focus scope.
                await Task.yield()
                guard !Task.isCancelled, enabled, restoreFocus, !isPresented else { return }
                triggerFocused = true; restoreFocus = false
            }
        if hosted {
            trigger.preference(key: CNPresentationRequests.self, value: [
                CNPresentationRequest(id: id, kind: kind, presentation: $isPresented, classes: contentClasses,
                                      environment: environment, content: AnyView(content()))
            ])
            .preference(key: CNPresentationPresence.self, value: isPresented ? [id] : [])
            .onDisappear { isPresented = false }
        } else {
            trigger.sheet(isPresented: $isPresented) {
                CNDialogContent(contentClasses, content: content)
            }
        }
    }
}

private struct CNPresentationRequest: Identifiable {
    let id: UUID
    let kind: CNPresentationKind
    let presentation: Binding<Bool>
    let classes: TWClasses
    let environment: EnvironmentValues
    let content: AnyView
}
private struct CNPresentationRequests: PreferenceKey {
    static var defaultValue: [CNPresentationRequest] { [] }
    static func reduce(value: inout [CNPresentationRequest], nextValue: () -> [CNPresentationRequest]) { value += nextValue() }
}
private struct CNPresentationPresence: PreferenceKey {
    static let defaultValue: [UUID] = []
    static func reduce(value: inout [UUID], nextValue: () -> [UUID]) { value += nextValue() }
}
private struct CNPresentationHostedKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    fileprivate var cnPresentationHosted: Bool {
        get { self[CNPresentationHostedKey.self] }
        set { self[CNPresentationHostedKey.self] = newValue }
    }
}

private struct CNPresentationPanel: View {
    let request: CNPresentationRequest
    let size: CGSize
    let placement: CGRect
    @State private var mounted = false
    @State private var contentHeight: CGFloat = 240
    @FocusState private var focused: Bool
    @Environment(\.layoutDirection) private var direction
    private var open: Bool { request.presentation.wrappedValue }
    private func close() { request.presentation.wrappedValue = false }
    private var hiddenOffset: CGSize {
        switch request.kind {
        case .dialog: .zero
        case .sheet(.bottom): CGSize(width: 0, height: size.height)
        case .sheet(.top): CGSize(width: 0, height: -size.height)
        case .sheet(let edge): CGSize(width: (edge == .leading) == (direction == .leftToRight) ? -size.width : size.width, height: 0)
        }
    }
    var body: some View {
        ZStack(alignment: request.kind.alignment) {
            Button(action: close) { Color.clear.tw("presentation-scrim") }
                .buttonStyle(.plain).frame(width: size.width, height: size.height).opacity(open ? 1 : 0)
                .accessibilityLabel("Dismiss presentation")
            if mounted {
                CNPopoverHost {
                    VStack(alignment: .leading, spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) { request.content }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                                    guard height > 0, abs(contentHeight - height) > 0.5 else { return }
                                    var transaction = Transaction(); transaction.disablesAnimations = true
                                    withTransaction(transaction) { contentHeight = height }
                                }
                        }
                        .frame(height: panelHeight == nil ? min(contentHeight, max(0, placement.height - 112)) : nil)
                    }
                    .frame(maxWidth: .infinity, maxHeight: panelHeight == nil ? nil : .infinity, alignment: .topLeading)
                    .tw(cn(request.kind.recipe, request.classes))
                }
                .frame(width: panelWidth, height: panelHeight)
                .padding(isEdgePanel ? 0 : 16)
                .transition(entryTransition)
                .scaleEffect(open || isEdgePanel ? 1 : 0.97)
                .opacity(open || isEdgePanel ? 1 : 0)
                .offset(x: open ? 0 : hiddenOffset.width, y: open ? 0 : hiddenOffset.height)
                .frame(width: placement.width, height: placement.height, alignment: request.kind.alignment)
                .position(x: placement.midX, y: placement.midY)
                .environment(\.cnPresentationDismiss, close)
                .disabled(!open)
                .accessibilityElement(children: .contain).accessibilityAddTraits(.isModal)
                .accessibilityAction(.escape, close)
                .focusable().focusEffectDisabled().focused($focused)
                .onKeyPress(.escape) { close(); return .handled }
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(open).accessibilityHidden(!open)
        .twAnimation("presentation-motion", value: open, tracksHover: false)
        .twAnimation("presentation-motion", value: mounted, tracksHover: false)
        .onChange(of: open, initial: true) { _, open in
            if open { mounted = true }
            focused = open
        }
    }
    private var entryTransition: AnyTransition {
        switch request.kind {
        case .dialog: .opacity.combined(with: .scale(scale: 0.97))
        case .sheet(let edge): .move(edge: edge)
        }
    }
    private var isEdgePanel: Bool { if case .sheet = request.kind { true } else { false } }
    private var panelWidth: CGFloat {
        switch request.kind {
        case .dialog: max(0, min(480, placement.width - 32))
        case .sheet(.top), .sheet(.bottom): placement.width
        case .sheet: min(400, placement.width)
        }
    }
    private var panelHeight: CGFloat? {
        switch request.kind {
        case .sheet(.leading), .sheet(.trailing): placement.height
        default: nil
        }
    }
}

/// A centered custom dialog. Install cnPresentationHost at the screen root.
/// Without a host, SwiftUI presents a native sheet.
public struct CNDialog<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let classes: TWClasses
    private let contentClasses: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(isPresented: Binding<Bool>, classes: TWClasses = "", contentClasses: TWClasses = "",
                @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        _isPresented = isPresented; self.classes = classes; self.contentClasses = contentClasses
        self.content = content; self.label = label()
    }
    public var body: some View {
        CNPresentationTrigger(isPresented: $isPresented, kind: .dialog, classes: classes,
                              contentClasses: contentClasses, content: content, label: { label })
    }
}

/// A custom edge panel. Leading and trailing edges follow the layout direction.
public struct CNSheet<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let edge: Edge
    private let classes: TWClasses
    private let contentClasses: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(isPresented: Binding<Bool>, edge: Edge = .trailing, classes: TWClasses = "", contentClasses: TWClasses = "",
                @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        _isPresented = isPresented; self.edge = edge; self.classes = classes; self.contentClasses = contentClasses
        self.content = content; self.label = label()
    }
    public var body: some View {
        CNPresentationTrigger(isPresented: $isPresented, kind: .sheet(edge), classes: classes,
                              contentClasses: contentClasses, content: content, label: { label })
    }
}

/// Styled content for a caller-owned sheet. Add scrolling and presentation modifiers at the sheet root.
public struct CNDrawerContent<Content: View>: View {
    private let classes: TWClasses
    private let spacing: CGFloat
    private let content: Content
    public init(_ classes: TWClasses = "", spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.classes = classes; self.spacing = spacing; self.content = content()
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw(cn("drawer", classes))
    }
}

/// A native sheet. SwiftUI owns detents, dragging, and dismissal.
public struct CNDrawer<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let classes: TWClasses
    private let contentClasses: TWClasses
    private let detents: Set<PresentationDetent>
    private let selection: Binding<PresentationDetent>?
    private let onDismiss: (() -> Void)?
    private let label: Label
    private let content: () -> Content
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme
    public init(isPresented: Binding<Bool>, classes: TWClasses = "", contentClasses: TWClasses = "",
                detents: Set<PresentationDetent> = [.medium, .large], selection: Binding<PresentationDetent>? = nil,
                onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        precondition(!detents.isEmpty, "Provide at least one sheet detent.")
        _isPresented = isPresented; self.classes = classes; self.contentClasses = contentClasses
        self.detents = detents; self.selection = selection; self.onDismiss = onDismiss
        self.content = content; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented = true }) { label }
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                if let selection {
                    sheetContent.presentationDetents(detents, selection: selection)
                } else {
                    sheetContent.presentationDetents(detents)
                }
            }
    }
    private var sheetContent: some View {
        CNPresentationHost {
            CNPopoverHost {
                ScrollView {
                    CNDrawerContent(contentClasses, content: content)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .environment(\.cnPresentationDismiss, nil)
        #if os(macOS)
            .frame(minWidth: 300, idealWidth: 420, minHeight: 240, idealHeight: 320)
        #endif
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.color(.surface, scheme: scheme))
        .preferredColorScheme(scheme)
    }
}

/// Alert buttons use native roles and placement. The operating system owns the alert surface.
public struct CNAlertDialog<Label: View, Actions: View, Message: View>: View {
    private let title: LocalizedStringKey
    @Binding private var isPresented: Bool
    private let classes: TWClasses
    private let label: Label
    private let actions: () -> Actions
    private let message: () -> Message
    public init(_ title: LocalizedStringKey, isPresented: Binding<Bool>, classes: TWClasses = "",
                @ViewBuilder actions: @escaping () -> Actions, @ViewBuilder message: @escaping () -> Message,
                @ViewBuilder label: () -> Label) {
        self.title = title; _isPresented = isPresented; self.classes = classes
        self.actions = actions; self.message = message; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented = true }) { label }
            .alert(title, isPresented: $isPresented, actions: actions, message: message)
    }
}
public struct CNDialogClose<Label: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.cnPresentationDismiss) private var closePresentation
    private let label: Label
    private let classes: TWClasses
    public init(_ classes: TWClasses = "", @ViewBuilder label: () -> Label) { self.classes = classes; self.label = label() }
    public init(_ title: LocalizedStringKey = "Close", classes: TWClasses = "") where Label == Text {
        self.classes = classes; self.label = Text(title)
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { if let closePresentation { closePresentation() } else { dismiss() } }) { label }.keyboardShortcut(.cancelAction)
    }
}
public struct CNPopover<Label: View, Content: View>: View {
    @Binding private var isPresented: Bool
    private let edge: Edge
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(isPresented: Binding<Bool>, arrowEdge: Edge = .top, classes: TWClasses = "",
                @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        _isPresented = isPresented; edge = arrowEdge; self.classes = classes; self.content = content; self.label = label()
    }
    public var body: some View {
        CNButton(variant: .outline, classes: classes, action: { isPresented.toggle() }) { label }
            .cnPopover(isPresented: $isPresented, arrowEdge: edge) {
                VStack(alignment: .leading, spacing: 8) { content() }.tw("popover")
            }
    }
}
/// Hover uses cancellable intent delays; activation pins the card for keyboard or touch use.
public struct CNHoverCard<Label: View, Content: View>: View {
    @State private var intent = CNHoverIntent()
    @State private var triggerHovered = false
    @State private var contentHovered = false
    private let openDelay: Duration
    private let closeDelay: Duration
    private let classes: TWClasses
    private let label: Label
    private let content: () -> Content
    public init(_ classes: TWClasses = "", openDelay: Duration = .milliseconds(200), closeDelay: Duration = .milliseconds(450),
                @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.classes = classes; self.openDelay = openDelay; self.closeDelay = closeDelay
        self.content = content; self.label = label()
    }
    private var hovering: Bool { triggerHovered || contentHovered }
    public var body: some View {
        let schedule = intent.schedule(hovering: hovering)
        CNButton(variant: .outline, classes: classes, action: { intent.activate(hovering: hovering) }) { label }
            .onHover { triggerHovered = $0 }
            .cnPopover(isPresented: Binding(get: { intent.isPresented }, set: { if !$0 { intent.dismiss(hovering: hovering) } })) {
                VStack(alignment: .leading, spacing: 8) { content() }
                    .tw("hover-card").onHover { contentHovered = $0 }
            }
            .onChange(of: intent.isPresented) { _, open in if !open { contentHovered = false } }
            .onChange(of: hovering) { _, hovered in if !hovered { intent.suppressed = false } }
            .task(id: schedule) {
                guard let schedule else { return }
                do { try await Task.sleep(for: schedule == .open ? openDelay : closeDelay) } catch { return }
                guard !Task.isCancelled, intent.schedule(hovering: hovering) == schedule else { return }
                intent.complete(schedule)
            }
    }
}
// Intent is separate from animation. Old delays cannot override explicit activation or dismissal.
struct CNHoverIntent {
    enum Schedule { case open, close }
    var isPresented = false
    var pinned = false
    var suppressed = false
    func schedule(hovering: Bool) -> Schedule? {
        if hovering && !isPresented && !suppressed { return .open }
        if !hovering && isPresented && !pinned { return .close }
        return nil
    }
    mutating func activate(hovering: Bool) {
        if isPresented && pinned { dismiss(hovering: hovering) }
        else { isPresented = true; pinned = true; suppressed = false }
    }
    mutating func dismiss(hovering: Bool) {
        isPresented = false; pinned = false; suppressed = hovering
    }
    mutating func complete(_ schedule: Schedule) {
        switch schedule {
        case .open: isPresented = true; pinned = false
        case .close: isPresented = false
        }
    }
}
public struct CNTooltip<Label: View>: View {
    private let text: LocalizedStringKey
    private let classes: TWClasses
    private let label: Label
    @State private var isPresented = false
    public init(_ text: LocalizedStringKey, classes: TWClasses = "", @ViewBuilder label: () -> Label) {
        self.text = text; self.classes = classes; self.label = label()
    }
    public var body: some View {
        #if os(macOS)
        label.help(Text(text)).tw(cn("tooltip", classes))
        #else
        CNPopover(isPresented: $isPresented, classes: classes) { Text(text).tw("tooltip") } label: { label }
        #endif
    }
}
