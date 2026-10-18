import SwiftUI
import SwiftCN

struct GallerySearchResults {
    struct Group: Identifiable {
        let category: GalleryCategory
        let components: [CNComponentGallery]
        var id: GalleryCategory { category }
    }

    let query: String
    let groups: [Group]
    let components: [CNComponentGallery]
    let compositions: [CNNativeComposition]
    var count: Int { components.count + compositions.count }

    init(_ draft: String = "") {
        query = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = query
        components = CNComponentGallery.allCases.filter { $0.matches(query) }
        compositions = CNNativeComposition.allCases.filter {
            query.isEmpty || $0.title.localizedStandardContains(query)
                || "Native composition".localizedStandardContains(query)
        }
        let byCategory = Dictionary(grouping: components, by: \.category)
        groups = GalleryCategory.allCases.compactMap { category in
            byCategory[category].map { Group(category: category, components: $0) }
        }
    }
}

/// Draft edits only invalidate the input. The navigation list changes after a short pause.
struct GallerySearchField: View {
    @State private var query = ""
    var focus: FocusState<Bool>.Binding
    let reset: Int
    let onSearch: () -> Void
    let onFilter: (String) -> Void
    let onSubmit: (String) -> Void

    var body: some View {
        CNInputGroup("px-2 rounded-lg hover:border-foreground animate-smooth duration-120 motion-reduce:animate-none", focus: focus) {
            CNButton(variant: .ghost, size: .small, classes: "px-0", action: onSearch) {
                Image(systemName: "magnifyingglass").tw("text-mutedForeground")
            }.keyboardShortcut("k", modifiers: .command).accessibilityLabel("Search components")
            CNInputGroupField("Search components…", text: $query)
                .accessibilityIdentifier("gallery-search")
            if !query.isEmpty {
                CNButton(variant: .ghost, size: .small, classes: "px-0", action: clear) {
                    Image(systemName: "xmark.circle.fill").tw("text-mutedForeground")
                }.accessibilityLabel("Clear search")
            }
        }
        .task(id: query) {
            let draft = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !draft.isEmpty {
                do { try await Task.sleep(for: .milliseconds(120)) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            onFilter(draft)
        }
        .onSubmit { onSubmit(query) }
        .onChange(of: reset) { _, _ in clear() }
        .onKeyPress(.escape) {
            guard !query.isEmpty else { return .ignored }
            clear(); return .handled
        }
    }

    private func clear() {
        query = ""
        onFilter("")
    }
}
