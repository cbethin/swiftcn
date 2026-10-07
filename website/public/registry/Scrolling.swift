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
    @State private var readingAnchor = CNMessageReadingAnchor<Data.Element.ID>()
    public init(_ data: Data, followNewMessages: Bool = false, scrollRevision: Int = 0,
                position: Binding<Data.Element.ID?>? = nil, isAtBottom: Binding<Bool>? = nil,
                classes: TWClasses = "", @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; self.followNewMessages = followNewMessages; self.scrollRevision = scrollRevision
        self.position = position; bottomState = isAtBottom; self.classes = classes; self.content = content
    }
    public var body: some View {
        GeometryReader { viewport in
            let viewportHeight = viewport.size.height
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(data) { item in
                            content(item).id(item.id).background {
                                if !followNewMessages && item.id == (position?.wrappedValue ?? localPosition) {
                                    Color.clear.onGeometryChange(for: CGRect.self, of: { $0.frame(in: .scrollView(axis: .vertical)) }) { frame in
                                        guard readingAnchor.frame == nil || readingAnchor.firstID == data.first?.id else { return }
                                        readingAnchor.firstID = data.first?.id
                                        readingAnchor.targetID = item.id
                                        readingAnchor.frame = frame
                                    }
                                }
                            }
                        }
                    }.scrollTargetLayout()
                    Color.clear.frame(height: 1)
                        .id(bottomID)
                        .onGeometryChange(for: CNMessageEndGeometry.self, of: {
                            CNMessageEndGeometry(bottom: $0.frame(in: .scrollView(axis: .vertical)).maxY,
                                                 height: $0.bounds(of: .scrollView(axis: .vertical))?.height ?? viewportHeight)
                        }) { end in
                            if let bottomState {
                                let atBottom = end.bottom <= end.height + 24 && end.bottom >= 0
                                if bottomState.wrappedValue != atBottom { bottomState.wrappedValue = atBottom }
                            }
                            if followNewMessages && end.bottom.isFinite && end.bottom > end.height + 1 {
                                scrollToLatest(proxy)
                            }
                        }
                }
                .scrollPosition(id: position ?? $localPosition, anchor: followNewMessages ? .bottom : .top)
                .defaultScrollAnchor(followNewMessages ? .bottom : (position?.wrappedValue == nil ? .top : nil))
                .tw("scroll-area")
                .onAppear {
                    if followNewMessages { scrollToLatest(proxy) }
                    else { restoreReadingTarget(proxy, height: viewportHeight) }
                    readingAnchor.hasAppeared = true
                }
                .onChange(of: data.first?.id) { _, _ in
                    if followNewMessages { scrollToLatest(proxy) }
                    else { restoreReadingTarget(proxy, height: viewportHeight) }
                    readingAnchor.firstID = data.first?.id
                }
                .onChange(of: followNewMessages) { _, follow in if follow { scrollToLatest(proxy) } }
                .onChange(of: scrollRevision) { _, _ in if followNewMessages { scrollToLatest(proxy) } }
                .onChange(of: data.last?.id) { _, _ in if followNewMessages { scrollToLatest(proxy) } }
                .onChange(of: viewport.size) { _, _ in if followNewMessages { scrollToLatest(proxy) } }
            }
        }.tw(classes)
    }
    private func restoreReadingTarget(_ proxy: ScrollViewProxy, height: CGFloat) {
        guard let target = position?.wrappedValue ?? localPosition else { return }
        let frame = readingAnchor.hasAppeared && readingAnchor.targetID == target ? readingAnchor.frame : nil
        let available = height - (frame?.height ?? 0)
        let anchor = UnitPoint(x: 0.5, y: available > 1 ? (frame?.minY ?? 0) / available : 0)
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { proxy.scrollTo(target, anchor: anchor) }
    }
    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        guard !data.isEmpty else { return }
        // Streaming and keyboard layout changes must not enqueue competing animations.
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { proxy.scrollTo(bottomID, anchor: .bottom) }
    }
}
// One visible target stores its pixel offset without invalidating body during scrolling.
@MainActor private final class CNMessageReadingAnchor<ID> {
    var hasAppeared = false
    var firstID: ID?
    var targetID: ID?
    var frame: CGRect?
}
private struct CNMessageEndGeometry: Equatable {
    let bottom: CGFloat
    let height: CGFloat
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
