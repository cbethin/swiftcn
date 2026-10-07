import SwiftUI
import SwiftCN

public struct CNScrollArea<Content: View>: View {
    private let axes: Axis.Set
    private let indicators: Bool
    private let classes: TWClasses
    private let content: Content
    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, classes: TWClasses = "", @ViewBuilder content: () -> Content) {
        self.axes = axes; indicators = showsIndicators; self.classes = classes; self.content = content()
    }
    public var body: some View { ScrollView(axes, showsIndicators: indicators) { content }.tw(cn("scroll-area", classes)) }
}
/// Stable native scroll targets preserve reading position when history is prepended.
/// The host owns following policy. Bind isAtBottom to observe proximity to the end.
public struct CNMessageScroller<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    private let followNewMessages: Bool
    private let scrollRevision: Int
    private let position: Binding<Data.Element.ID?>?
    private let bottomState: Binding<Bool>?
    private let classes: TWClasses
    private let content: (Data.Element) -> Content
    @State private var localPosition: Data.Element.ID?
    @State private var bottomID = UUID()
    @Namespace private var scrollSpace
    public init(_ data: Data, followNewMessages: Bool = false, scrollRevision: Int = 0,
                position: Binding<Data.Element.ID?>? = nil, isAtBottom: Binding<Bool>? = nil,
                classes: TWClasses = "", @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; self.followNewMessages = followNewMessages; self.scrollRevision = scrollRevision
        self.position = position; bottomState = isAtBottom; self.classes = classes; self.content = content
    }
    public var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(data) { item in content(item).id(item.id) }
                    }.scrollTargetLayout()
                    Color.clear.frame(height: 1)
                        .id(bottomID)
                        .background(GeometryReader { marker in
                            Color.clear.preference(key: CNMessageBottomKey.self,
                                value: marker.frame(in: .named(scrollSpace)).maxY)
                        })
                }
                .coordinateSpace(name: scrollSpace)
                .scrollPosition(id: position ?? $localPosition, anchor: .top)
                .defaultScrollAnchor(followNewMessages && position?.wrappedValue == nil ? .bottom : .top)
                .tw("scroll-area")
                .onPreferenceChange(CNMessageBottomKey.self) { bottom in
                    if let bottomState {
                        let atBottom = bottom <= viewport.size.height + 24 && bottom >= 0
                        if bottomState.wrappedValue != atBottom { bottomState.wrappedValue = atBottom }
                    }
                    if followNewMessages && bottom.isFinite && bottom > viewport.size.height + 1 {
                        scrollToLatest(proxy)
                    }
                }
                .onChange(of: followNewMessages) { _, follow in if follow { scrollToLatest(proxy) } }
                .onChange(of: scrollRevision) { _, _ in if followNewMessages { scrollToLatest(proxy) } }
                .onChange(of: data.last?.id) { _, _ in if followNewMessages { scrollToLatest(proxy) } }
                .onChange(of: viewport.size) { _, _ in if followNewMessages { scrollToLatest(proxy) } }
            }
        }.tw(classes)
    }
    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        guard !data.isEmpty else { return }
        // Streaming and keyboard layout changes must not enqueue competing animations.
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { proxy.scrollTo(bottomID, anchor: .bottom) }
    }
}
private struct CNMessageBottomKey: PreferenceKey {
    static let defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
/// Native scroll paging with a binding to the stable item ID. Size the viewport with classes.
public struct CNCarousel<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    @Binding private var selection: Data.Element.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let classes: TWClasses
    private let content: (Data.Element) -> Content
    public init(_ data: Data, selection: Binding<Data.Element.ID?>, classes: TWClasses = "",
                @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; _selection = selection; self.classes = classes; self.content = content
    }
    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(data) { item in content(item).containerRelativeFrame(.horizontal).id(item.id) }
            }.scrollTargetLayout()
        }.scrollTargetBehavior(.paging).scrollPosition(id: $selection).tw(cn("carousel", classes))
            .onChange(of: data.map(\.id), initial: true) { _, ids in
                if let selection, !ids.contains(selection) { self.selection = ids.first }
            }
            .accessibilityAction(named: Text("Next page")) { move(1) }
            .accessibilityAction(named: Text("Previous page")) { move(-1) }
    }
    private func move(_ delta: Int) {
        let ids = data.map(\.id)
        guard !ids.isEmpty else { return }
        let index = selection.flatMap { ids.firstIndex(of: $0) } ?? 0
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
            selection = ids[min(ids.count - 1, max(0, index + delta))]
        }
    }
}
