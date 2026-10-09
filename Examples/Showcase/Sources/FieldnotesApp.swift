import SwiftUI
import SwiftCN

struct FieldnotesApp: View {
    @Bindable var store: ShowcaseStore
    let exit: () -> Void
    @State private var query = ""
    @State private var favorites = false
    @State private var creating = false
    private var entries: [JournalEntry] {
        store.data.entries.filter { (!favorites || $0.starred) && (query.isEmpty || $0.title.localizedStandardContains(query) || $0.body.localizedStandardContains(query)) }
            .sorted { $0.date > $1.date }
    }
    @State private var selected: UUID?
    @Environment(\.horizontalSizeClass) private var sizeClass
    var body: some View {
        // Keep native widths unconstrained so Duo can align both panes with the hinge.
        NavigationSplitView {
            List(selection: $selected) {
                VStack(alignment: .leading, spacing: 18) {
                    PageHeading(eyebrow: "A place to return to", title: "Your pages.", subtitle: "A moment, a place, a person.")
                    CNButton("Write a little", variant: .outline, classes: "w-full") { creating = true }
                        .accessibilityIdentifier("new-entry")
                        .sourceSheet(isPresented: $creating) { JournalEditor(store: store, entry: nil) }
                    CNInputGroup { Image(systemName: "magnifyingglass").tw("text-mutedForeground"); CNInputGroupField("Search your notes", text: $query) }
                    HStack {
                        SectionHeading(title: favorites ? "Worth keeping" : "Your notebook", detail: "\(entries.count)")
                        CNButton(variant: .ghost, size: .icon) { favorites.toggle() } label: {
                            Image(systemName: favorites ? "star.fill" : "star")
                        }.accessibilityLabel(favorites ? "Show all entries" : "Show starred entries")
                    }
                }.collectionRow()
                ForEach(entries) { entry in
                    NavigationLink(value: entry.id) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                                Spacer()
                                if entry.starred { Image(systemName: "star.fill").tw("text-primary") }
                            }.tw("text-xs text-mutedForeground")
                            Text(entry.title).font(.system(.title3, design: .serif)).tw("font-medium text-foreground")
                            Text(entry.body).lineLimit(2).tw("text-sm text-mutedForeground")
                        }.tw("p-4 w-full bg-surface rounded-[20] border")
                    }.collectionRow().accessibilityIdentifier("entry-\(entry.id)")
                }
                if entries.isEmpty { EmptyMessage(symbol: "book", title: "A fresh page", message: "Write something new, or try a different search.").collectionRow() }
            }.collectionStyle().accessibilityIdentifier("notebook-collection")
                .modifier(DemoToolbar(app: .fieldnotes, exit: exit))
        } detail: {
            if let selected {
                JournalDetail(store: store, id: selected) { self.selected = nil }.id(selected)
            } else {
                Page { EmptyMessage(symbol: "book.pages", title: "A little space to reflect", message: "Choose a page from your notebook, or write something new.") }
            }
        }
            .onChange(of: sizeClass, initial: true) { _, value in
                if value == .regular && selected == nil { selected = entries.first?.id }
            }
    }
}

private struct JournalDetail: View {
    let store: ShowcaseStore
    let id: UUID
    let deleted: () -> Void
    @State private var editing = false
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    private var entry: JournalEntry? { store.data.entries.first { $0.id == id } }
    var body: some View {
        Page {
            if let entry {
                PageHeading(eyebrow: entry.date.formatted(date: .abbreviated, time: .omitted), title: entry.title, subtitle: entry.mood)
                Text(entry.body).font(.system(.body, design: .serif)).lineSpacing(8).textSelection(.enabled).tw("text-foreground w-full")
                CNSeparator()
                HStack {
                    CNButton(entry.starred ? "Starred" : "Keep this", variant: .outline) {
                        if let index = store.data.entries.firstIndex(where: { $0.id == id }) { store.data.entries[index].starred.toggle() }
                    }
                    Spacer()
                    CNButton("Edit", variant: .outline) { editing = true }
                        .sourceSheet(isPresented: $editing) { JournalEditor(store: store, entry: entry) }
                }
            }
        }.navigationTitle("A page from your life").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                CNButton(variant: .ghost, size: .icon) { deleting = true } label: { Image(systemName: "trash") }.accessibilityLabel("Delete entry")
            } }
            .confirmationDialog("Delete this entry?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete entry", role: .destructive) { store.data.entries.removeAll { $0.id == id }; deleted(); dismiss() }
            }
    }
}
private struct JournalEditor: View {
    let store: ShowcaseStore
    let entry: JournalEntry?
    @State private var title: String
    @State private var text: String
    @State private var mood: String
    init(store: ShowcaseStore, entry: JournalEntry?) {
        self.store = store; self.entry = entry
        _title = State(initialValue: entry?.title ?? ""); _text = State(initialValue: entry?.body ?? ""); _mood = State(initialValue: entry?.mood ?? "Peaceful")
    }
    var body: some View {
        EditorSheet(title: entry == nil ? "A fresh page" : "Edit your page", canSave: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            let saved = JournalEntry(id: entry?.id ?? UUID(), title: title.trimmingCharacters(in: .whitespacesAndNewlines), body: text, mood: mood, starred: entry?.starred ?? false, date: entry?.date ?? Date())
            if let index = store.data.entries.firstIndex(where: { $0.id == saved.id }) { store.data.entries[index] = saved }
            else { store.data.entries.insert(saved, at: 0) }
            return true
        } content: {
            CNField { CNFieldLabel("Give it a title"); CNInput("A moment worth keeping", text: $title).accessibilityIdentifier("entry-title") }
            Picker("How do you feel?", selection: $mood) {
                ForEach(["Peaceful", "Inspired", "Grateful", "Reflective"], id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.menu).tw("w-full")
            CNTextarea("Your entry", text: $text, classes: "min-h-[280]").accessibilityIdentifier("entry-body")
        }
    }
}
