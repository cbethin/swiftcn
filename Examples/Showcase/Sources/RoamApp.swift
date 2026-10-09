import SwiftUI
import SwiftCN

struct RoamApp: View {
    @Bindable var store: ShowcaseStore
    let exit: () -> Void
    @State private var creating = false
    @State private var selected: UUID?
    @Environment(\.horizontalSizeClass) private var sizeClass
    var body: some View {
        // Keep native widths unconstrained so Duo can align both panes with the hinge.
        NavigationSplitView {
            List(selection: $selected) {
                VStack(alignment: .leading, spacing: 16) {
                    PageHeading(eyebrow: "Somewhere beyond the everyday", title: "Go somewhere good.", subtitle: "Your journeys, all in one place.")
                    CNButton("Plan a trip", classes: "w-full") { creating = true }.accessibilityIdentifier("new-trip")
                        .sourceSheet(isPresented: $creating) { TripEditor(store: store) }
                }.collectionRow()
                ForEach(store.data.trips.sorted { $0.date < $1.date }) { trip in
                    NavigationLink(value: trip.id) {
                        VStack(alignment: .leading, spacing: 0) {
                            LandscapeArt(symbol: trip.symbol).frame(height: 100)
                            VStack(alignment: .leading, spacing: 10) {
                                Text(trip.date.formatted(.dateTime.month(.wide).day())).tw("text-xs font-medium text-primary")
                                Text(trip.title).font(.system(.title3, design: .serif)).tw("font-semibold text-foreground")
                                Text(trip.subtitle).tw("text-sm text-mutedForeground")
                                Label("\(trip.activities.count) little plans", systemImage: "map").tw("text-xs text-primary")
                            }.tw("p-4 w-full")
                        }.tw("w-full bg-surface rounded-[24] border")
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }.collectionRow().accessibilityIdentifier("trip-\(trip.id)")
                }
                if store.data.trips.isEmpty { EmptyMessage(symbol: "map", title: "Where next?", message: "Your next little adventure starts with a name.").collectionRow() }
            }.collectionStyle().modifier(DemoToolbar(app: .roam, exit: exit))
        } detail: {
            if let selected { TripDetail(store: store, id: selected) { self.selected = nil }.id(selected) }
            else { Page { EmptyMessage(symbol: "map", title: "Room for an adventure", message: "Choose a journey to plan your stops and pack the essentials.") } }
        }
            .onChange(of: sizeClass, initial: true) { _, value in
                if value == .regular && selected == nil { selected = store.data.trips.sorted { $0.date < $1.date }.first?.id }
            }
    }
}
/// A lightweight, local illustration, with no network or image loading dependency.
private struct LandscapeArt: View {
    let symbol: String
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: scheme == .dark ? [Color(red: 0.12, green: 0.23, blue: 0.27), Color(red: 0.21, green: 0.36, blue: 0.37)] : [Color(red: 0.80, green: 0.87, blue: 0.83), Color(red: 0.94, green: 0.90, blue: 0.79)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(red: 0.98, green: 0.86, blue: 0.60).opacity(0.8))
                    .frame(width: 64, height: 64).position(x: geometry.size.width * 0.74, y: 48)
                Ellipse().fill(Color(red: 0.38, green: 0.55, blue: 0.49)).frame(width: geometry.size.width * 1.3, height: 180)
                    .position(x: geometry.size.width * 0.25, y: 170)
                Ellipse().fill(Color(red: 0.25, green: 0.43, blue: 0.40)).frame(width: geometry.size.width * 1.1, height: 150)
                    .position(x: geometry.size.width * 0.88, y: 190)
                Image(systemName: symbol).font(.system(size: 40, weight: .ultraLight)).foregroundStyle(.white.opacity(0.8))
                    .position(x: geometry.size.width * 0.25, y: 84)
            }.clipped()
        }.accessibilityHidden(true)
    }
}
private struct TripDetail: View {
    @Bindable var store: ShowcaseStore
    let id: UUID
    let deleted: () -> Void
    @State private var section = "Itinerary"
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var adding = false
    @State private var deleting = false
    @Environment(\.dismiss) private var dismiss
    private var index: Int? { store.data.trips.firstIndex { $0.id == id } }
    var body: some View {
        Page {
            if let index {
                let trip = store.data.trips[index]
                LandscapeArt(symbol: trip.symbol).frame(height: sizeClass == .regular ? 100 : 180).clipShape(RoundedRectangle(cornerRadius: 24))
                PageHeading(eyebrow: "Your next chapter", title: trip.title, subtitle: trip.subtitle)
                CNDatePicker("Departure", selection: Binding(get: { store.data.trips.first { $0.id == id }?.date ?? Date() }, set: { date in
                    if let index = self.index { store.data.trips[index].date = date }
                }))
                Picker("Trip section", selection: $section) { Text("Itinerary").tag("Itinerary"); Text("Packing").tag("Packing") }.pickerStyle(.segmented)
                if section == "Itinerary" {
                    Surface {
                        SectionHeading(title: "Leave room for detours", detail: "\(trip.activities.count) stops")
                        ForEach(trip.activities) { activity in
                            HStack(spacing: 12) {
                                Text(activity.time).monospacedDigit().tw("text-xs text-primary w-[48]")
                                CNCheckbox(isOn: activityBinding(activity.id)) { Text(activity.title).strikethrough(activity.done).tw("text-sm") }
                                Menu { Button("Remove stop", role: .destructive) { if let index = self.index { store.data.trips[index].activities.removeAll { $0.id == activity.id } } } } label: {
                                    Image(systemName: "ellipsis").tw("min-w-[44] min-h-[44] text-mutedForeground")
                                }.accessibilityLabel("Actions for \(activity.title)")
                            }
                        }
                        CNButton("Add a stop", variant: .outline) { adding = true }.accessibilityIdentifier("add-stop")
                            .sourceSheet(isPresented: $adding) { TripItemEditor(store: store, tripID: id, packing: false) }
                    }
                } else {
                    Surface {
                        SectionHeading(title: "The essentials", detail: "\(trip.packing.filter(\.packed).count)/\(trip.packing.count) packed")
                        ForEach(trip.packing) { item in
                            CNCheckbox(isOn: packingBinding(item.id)) { Text(item.title).tw("text-sm") }
                                .accessibilityIdentifier("packing-\(item.title)")
                        }
                        CNButton("Add an essential", variant: .outline) { adding = true }
                            .sourceSheet(isPresented: $adding) { TripItemEditor(store: store, tripID: id, packing: true) }
                    }
                }
            }
        }.navigationTitle("Your trip").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                CNButton(variant: .ghost, size: .icon) { deleting = true } label: { Image(systemName: "trash") }.accessibilityLabel("Delete trip")
            } }
            .confirmationDialog("Delete this trip?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete trip", role: .destructive) { store.data.trips.removeAll { $0.id == id }; deleted(); dismiss() }
            }
    }
    private func activityBinding(_ activityID: UUID) -> Binding<Bool> {
        Binding(get: { store.data.trips.first { $0.id == id }?.activities.first { $0.id == activityID }?.done ?? false }, set: { done in
            if let index, let row = store.data.trips[index].activities.firstIndex(where: { $0.id == activityID }) { store.data.trips[index].activities[row].done = done }
        })
    }
    private func packingBinding(_ itemID: UUID) -> Binding<Bool> {
        Binding(get: { store.data.trips.first { $0.id == id }?.packing.first { $0.id == itemID }?.packed ?? false }, set: { packed in
            if let index, let row = store.data.trips[index].packing.firstIndex(where: { $0.id == itemID }) { store.data.trips[index].packing[row].packed = packed }
        })
    }
}
private struct TripEditor: View {
    let store: ShowcaseStore
    @State private var title = ""
    @State private var subtitle = ""
    @State private var date = Date()
    var body: some View {
        EditorSheet(title: "Somewhere new", canSave: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            store.data.trips.append(.init(title: title.trimmingCharacters(in: .whitespacesAndNewlines), subtitle: subtitle, symbol: "mountain.2", date: date, activities: [], packing: [.init(title: "Passport"), .init(title: "Charger"), .init(title: "Walking shoes")]))
            return true
        } content: {
            CNField { CNFieldLabel("Where to?"); CNInput("Trip name", text: $title).accessibilityIdentifier("trip-title") }
            CNField { CNFieldLabel("A little description"); CNInput("What are you looking forward to?", text: $subtitle) }
            CNDatePicker("Departure", selection: $date)
        }
    }
}
private struct TripItemEditor: View {
    let store: ShowcaseStore
    let tripID: UUID
    let packing: Bool
    @State private var title = ""
    @State private var time = "10:00"
    var body: some View {
        EditorSheet(title: packing ? "An essential" : "A little plan", canSave: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            guard let index = store.data.trips.firstIndex(where: { $0.id == tripID }), !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            if packing { store.data.trips[index].packing.append(.init(title: title)) }
            else { store.data.trips[index].activities.append(.init(title: title, time: time)) }
            return true
        } content: {
            CNField { CNFieldLabel(packing ? "What to bring" : "What to do"); CNInput("Name", text: $title) }
            if !packing { CNField { CNFieldLabel("Time or a little note"); CNInput("10:00", text: $time) } }
        }
    }
}
