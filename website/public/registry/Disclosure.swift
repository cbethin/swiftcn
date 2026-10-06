import SwiftUI
import SwiftCN

public struct CNCollapsible<Label: View, Content: View>: View {
    @Binding private var isExpanded: Bool
    private let classes: TWClasses
    private let label: Label
    private let content: Content
    public init(isExpanded: Binding<Bool>, classes: TWClasses = "", @ViewBuilder content: () -> Content,
                @ViewBuilder label: () -> Label) {
        _isExpanded = isExpanded; self.classes = classes; self.content = content(); self.label = label()
    }
    public var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) { content } label: { label }.tw(cn("collapsible", classes))
    }
}

public enum CNAccordionMode: Sendable { case single, multiple }
/// IDs belong to the caller. Reordering items does not change which disclosure is open.
public struct CNAccordion<Data: RandomAccessCollection, Label: View, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    @Binding private var expanded: Set<Data.Element.ID>
    private let mode: CNAccordionMode
    private let classes: TWClasses
    private let label: (Data.Element) -> Label
    private let content: (Data.Element) -> Content
    public init(_ data: Data, expanded: Binding<Set<Data.Element.ID>>, mode: CNAccordionMode = .multiple,
                classes: TWClasses = "", @ViewBuilder content: @escaping (Data.Element) -> Content,
                @ViewBuilder label: @escaping (Data.Element) -> Label) {
        self.data = data; _expanded = expanded; self.mode = mode; self.classes = classes
        self.label = label; self.content = content
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(data) { item in
                DisclosureGroup(isExpanded: Binding(get: { expanded.contains(item.id) }, set: { open in
                    if open { if mode == .single { expanded = [item.id] } else { expanded.insert(item.id) } }
                    else { expanded.remove(item.id) }
                })) { content(item) } label: { label(item) }.tw("accordion-item")
                CNSeparator()
            }
        }.tw(cn("accordion", classes))
    }
}
