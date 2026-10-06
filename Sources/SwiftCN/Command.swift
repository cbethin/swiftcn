import SwiftUI

public enum CNOptionSearch {
    public static func filter<ID>(_ options: [CNOption<ID>], query: String) -> [CNOption<ID>] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? options : options.filter {
            $0.title.localizedStandardContains(query) || ($0.detail?.localizedStandardContains(query) ?? false)
        }
    }
}

/// Search and choose stable values. Disabled options cannot activate by click or Return.
public struct CNCommand<ID: Hashable & Sendable>: View {
    private let options: [CNOption<ID>]
    @Binding private var selection: ID?
    private let classes: TWClasses
    private let onSelect: (ID) -> Void
    @State private var query = ""
    @State private var highlighted: ID?
    @FocusState private var searchFocused: Bool
    public init(_ options: [CNOption<ID>], selection: Binding<ID?>, classes: TWClasses = "", onSelect: @escaping (ID) -> Void = { _ in }) {
        self.options = options; _selection = selection; self.classes = classes; self.onSelect = onSelect
    }
    private var results: [CNOption<ID>] { CNOptionSearch.filter(options, query: query) }
    public var body: some View {
        let results = self.results
        VStack(alignment: .leading, spacing: 8) {
            CNInput("Search…", text: $query, focus: $searchFocused).onSubmit(activateHighlighted)
            if results.isEmpty { Text("No results").tw("p-3 text-sm text-mutedForeground") }
            List(selection: $highlighted) {
                ForEach(results) { option in
                    Button { activate(option) } label: {
                        HStack {
                            if let symbol = option.systemImage { Image(systemName: symbol).accessibilityHidden(true) }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                if let detail = option.detail { Text(detail).tw("text-xs text-mutedForeground") }
                            }
                            Spacer()
                            if selection == option.id { Image(systemName: "checkmark").accessibilityHidden(true) }
                        }
                    }.buttonStyle(.tw("command-item w-full")).disabled(option.isDisabled).tag(option.id)
                        .accessibilityAddTraits(selection == option.id ? .isSelected : [])
                }
            }.listStyle(.plain).scrollContentBackground(.hidden)
        }.tw(cn("command min-h-[220]", classes))
            .onChange(of: results.map(\.id), initial: true) { _, ids in
                if highlighted.map({ !ids.contains($0) }) ?? true { highlighted = results.first { !$0.isDisabled }?.id }
            }
            .onAppear { searchFocused = true }
        #if os(macOS)
            .onMoveCommand { direction in
                if direction == .down { move(1) }
                else if direction == .up { move(-1) }
            }
        #endif
    }
    private func activate(_ option: CNOption<ID>) {
        guard !option.isDisabled else { return }
        selection = option.id; onSelect(option.id)
    }
    private func activateHighlighted() {
        if let option = results.first(where: { $0.id == highlighted && !$0.isDisabled }) ?? results.first(where: { !$0.isDisabled }) {
            activate(option)
        }
    }
    private func move(_ delta: Int) {
        let enabled = results.filter { !$0.isDisabled }
        guard !enabled.isEmpty else { return }
        let index = highlighted.flatMap { id in enabled.firstIndex { $0.id == id } } ?? (delta > 0 ? -1 : enabled.count)
        highlighted = enabled[min(enabled.count - 1, max(0, index + delta))].id
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
