import SwiftUI

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
/// Reading position stays unchanged by default. The host explicitly opts into following new messages.
public struct CNMessageScroller<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    private let followNewMessages: Bool
    private let classes: TWClasses
    private let content: (Data.Element) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public init(_ data: Data, followNewMessages: Bool = false, classes: TWClasses = "",
                @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; self.followNewMessages = followNewMessages; self.classes = classes; self.content = content
    }
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(data) { item in content(item).id(item.id) }
                }
            }.defaultScrollAnchor(.bottom).tw(cn("scroll-area", classes))
                .onChange(of: data.last?.id) { _, id in
                    guard followNewMessages, let id else { return }
                    withAnimation(reduceMotion ? nil : .smooth) { proxy.scrollTo(id, anchor: .bottom) }
                }
        }
    }
}
/// Native scroll paging with a binding to the stable item ID. Size the viewport with classes.
public struct CNCarousel<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    @Binding private var selection: Data.Element.ID?
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
        selection = ids[min(ids.count - 1, max(0, index + delta))]
    }
}
