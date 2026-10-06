import SwiftUI
import SwiftCN

public enum CNOptionSearch {
    public static func filter<ID>(_ options: [CNOption<ID>], query: String) -> [CNOption<ID>] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? options : options.filter {
            $0.title.localizedStandardContains(query) || ($0.detail?.localizedStandardContains(query) ?? false)
        }
    }
}

/// Keyboard and pointer navigation share one enabled, stable option identity.
enum CNCommandNavigation {
    static func reconcile<ID>(_ options: [CNOption<ID>], highlighted: ID?) -> ID? {
        let enabled = options.filter { !$0.isDisabled }
        return enabled.first { $0.id == highlighted }?.id ?? enabled.first?.id
    }
    static func move<ID>(_ options: [CNOption<ID>], highlighted: ID?, direction: Int) -> ID? {
        let enabled = options.filter { !$0.isDisabled }
        guard !enabled.isEmpty else { return nil }
        let index = highlighted.flatMap { id in enabled.firstIndex { $0.id == id } }
        guard let index else { return direction > 0 ? enabled.first?.id : enabled.last?.id }
        return enabled[min(enabled.count - 1, max(0, index + (direction > 0 ? 1 : -1)))].id
    }
}

/// Pointer bookkeeping does not invalidate the view on every mouse movement.
@MainActor final class CNCommandPointer {
    private var location: CGPoint?
    func moved(to next: CGPoint) -> Bool {
        defer { location = next }
        return location != nil && location != next
    }
}

/// Search native buttons with one shared pointer/keyboard highlight and stable IDs.
public struct CNCommand<ID: Hashable & Sendable>: View {
    private let options: [CNOption<ID>]
    @Binding private var selection: ID?
    private let classes: TWClasses
    private let onSelect: (ID) -> Void
    @State private var query = ""
    @State private var highlighted: ID?
    @State private var pointer = CNCommandPointer()
    @Namespace private var pointerSpace
    @FocusState private var searchFocused: Bool
    public init(_ options: [CNOption<ID>], selection: Binding<ID?>, classes: TWClasses = "", onSelect: @escaping (ID) -> Void = { _ in }) {
        self.options = options; _selection = selection; self.classes = classes; self.onSelect = onSelect
    }
    private var results: [CNOption<ID>] { CNOptionSearch.filter(options, query: query) }
    public var body: some View {
        let results = self.results
        VStack(alignment: .leading, spacing: 0) {
            CNInputGroup("command-search", focus: $searchFocused) {
                Image(systemName: "magnifyingglass").tw("text-sm text-mutedForeground").accessibilityHidden(true)
                CNInputGroupField("Search…", text: $query).accessibilityLabel("Search commands")
                    .onSubmit(activateHighlighted)
            }
            CNSeparator()
            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        if results.isEmpty {
                            Text("No results found.").tw("w-full py-6 text-sm text-mutedForeground")
                        }
                        ForEach(results) { option in
                            Button { activate(option) } label: {
                                HStack(spacing: 10) {
                                    if let symbol = option.systemImage {
                                        Image(systemName: symbol).tw("w-[20] text-mutedForeground").accessibilityHidden(true)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(option.title).lineLimit(1)
                                        if let detail = option.detail {
                                            Text(detail).tw("text-xs text-mutedForeground").lineLimit(1)
                                        }
                                    }
                                    Spacer(minLength: 8)
                                    Image(systemName: "checkmark").tw("text-xs text-mutedForeground")
                                        .opacity(selection == option.id ? 1 : 0).accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.tw(cn("command-item w-full", highlighted == option.id ? "bg-accent" : "")))
                            .disabled(option.isDisabled).id(option.id)
                            .onContinuousHover(coordinateSpace: .named(pointerSpace)) { phase in
                                if case .active(let location) = phase {
                                    // Opening or scrolling beneath a stationary pointer must not replace keyboard focus.
                                    if pointer.moved(to: location) && !option.isDisabled { highlighted = option.id }
                                }
                            }
                            .accessibilityAddTraits(selection == option.id ? .isSelected : [])
                        }
                    }.tw("p-[6]")
                }
                .coordinateSpace(name: pointerSpace)
                .onChange(of: results, initial: true) { _, options in
                    highlighted = CNCommandNavigation.reconcile(options, highlighted: highlighted)
                    if let highlighted { scroll.scrollTo(highlighted) }
                }
                .onChange(of: highlighted) { _, id in if let id { scroll.scrollTo(id) } }
            }
        }.tw(cn("command min-h-[180]", classes))
            .onAppear { searchFocused = true }
            .onKeyPress(.downArrow) { move(1); return .handled }
            .onKeyPress(.upArrow) { move(-1); return .handled }
    }
    private func activate(_ option: CNOption<ID>) {
        guard !option.isDisabled else { return }
        selection = option.id; onSelect(option.id)
    }
    private func activateHighlighted() {
        if let id = CNCommandNavigation.reconcile(results, highlighted: highlighted),
           let option = results.first(where: { $0.id == id }) { activate(option) }
    }
    private func move(_ direction: Int) {
        highlighted = CNCommandNavigation.move(results, highlighted: highlighted, direction: direction)
    }
}
public struct CNCombobox<ID: Hashable & Sendable>: View {
    private let title: String
    private let options: [CNOption<ID>]
    @Binding private var selection: ID?
    private let classes: TWClasses
    @State private var isPresented = false
    public init(_ title: String, options: [CNOption<ID>], selection: Binding<ID?>, classes: TWClasses = "") {
        self.title = title; self.options = options; _selection = selection; self.classes = classes
    }
    public var body: some View {
        CNPopover(isPresented: $isPresented, classes: cn("combobox", classes)) {
            CNCommand(options, selection: $selection, classes: "w-[300] h-[320]") { _ in isPresented = false }
        } label: {
            HStack {
                Text(options.first { $0.id == selection }?.title ?? title)
                Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
            }
        }.accessibilityLabel(title).accessibilityValue(options.first { $0.id == selection }?.title ?? "No selection")
    }
}
