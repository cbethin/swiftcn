import SwiftUI
import SwiftCN

@main struct SwiftCNShowcaseApp: App {
    @State private var store: ShowcaseStore
    init() {
        // UI tests use their own store, without clearing the user's demo data.
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let defaults = UserDefaults(suiteName: "dev.swiftcn.showcase.tests")!
            if ProcessInfo.processInfo.arguments.contains("--reset-test-data") { defaults.removePersistentDomain(forName: "dev.swiftcn.showcase.tests") }
            _store = State(initialValue: ShowcaseStore(defaults: defaults))
        } else { _store = State(initialValue: ShowcaseStore()) }
    }
    var body: some Scene { WindowGroup { ShowcaseHome(store: store) } }
}
struct ShowcaseHome: View {
    let store: ShowcaseStore
    @State private var selected: DemoApp?
    @AppStorage("showcase.dark") private var dark = false
    var body: some View {
        NavigationStack {
            Page {
                PageHeading(eyebrow: "Made with SwiftCN", title: "Small apps.\nBig possibilities.", subtitle: "Four little worlds. Native at heart.")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 18)], spacing: 18) {
                    ForEach(DemoApp.allCases) { app in
                        Button { selected = app } label: {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: app.symbol).font(.system(size: 32, weight: .light))
                                        .tw("text-primary p-3 bg-accent rounded-[18]")
                                    Spacer()
                                    Image(systemName: "arrow.up.right").tw("text-mutedForeground")
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(app.title).font(.system(.title, design: .serif)).tw("font-semibold")
                                    Text(app.subtitle).tw("text-sm text-mutedForeground")
                                }
                                HStack(spacing: 6) {
                                    Text(app.rawValue == "daylight" ? "PLAN" : app.rawValue == "ledger" ? "SPEND" : app.rawValue == "fieldnotes" ? "REFLECT" : "EXPLORE")
                                    Spacer()
                                    Text("OPEN APP"); Image(systemName: "arrow.right")
                                }.tracking(1.5).tw("text-xs text-primary")
                            }
                        }.buttonStyle(.tw("p-6 bg-surface rounded-[28] border w-full"))
                            .twTheme(app.theme).tint(app.accent)
                            .accessibilityIdentifier("launch-\(app.rawValue)")
                    }
                }
                Surface {
                    HStack(alignment: .top, spacing: 16) {
                        Image("SwiftCNBird").resizable().scaledToFit().frame(width: 40, height: 40).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Simple pieces. Real apps.").tw("font-semibold")
                            Text("Native navigation, editable components, and a few .tw classes. Your changes stay on this device.")
                                .tw("text-sm text-mutedForeground")
                        }
                    }
                    CNSwitch("Dark appearance", isOn: $dark)
                }
            }.navigationTitle("SwiftCN").navigationBarTitleDisplayMode(.inline)
        }.twTheme(DemoApp.daylight.theme).tint(DemoApp.daylight.accent)
            .preferredColorScheme(dark ? .dark : .light)
            .fullScreenCover(item: $selected) { app in
                DemoRoot(app: app, store: store) { selected = nil }
                    .preferredColorScheme(dark ? .dark : .light)
            }
    }
}
struct DemoRoot: View {
    let app: DemoApp
    let store: ShowcaseStore
    let exit: () -> Void
    var body: some View {
        Group {
            switch app {
            case .daylight: DaylightApp(store: store, exit: exit)
            case .ledger: LedgerApp(store: store, exit: exit)
            case .fieldnotes: FieldnotesApp(store: store, exit: exit)
            case .roam: RoamApp(store: store, exit: exit)
            }
        }.sheetSourceSpace().twTheme(app.theme).tint(app.accent)
            .alert("Could not save", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.saveError = nil } })) {
                Button("OK") { store.saveError = nil }
            } message: { Text(store.saveError ?? "") }
    }
}
