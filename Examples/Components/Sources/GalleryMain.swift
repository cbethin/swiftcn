import SwiftUI
import SwiftCN

@main struct SwiftCNComponentGalleryApp: App {
    var body: some Scene {
        WindowGroup("SwiftCN Component Gallery") { ComponentGalleryView() }
        #if os(macOS)
            .defaultSize(width: 1040, height: 760)
        #endif
    }
}

struct ComponentGalleryView: View {
    @State private var selection: CNComponentGallery? = .button
    @State private var query = ""
    @State private var dark = false
    var body: some View {
        NavigationSplitView {
            List(CNComponentGallery.allCases.filter { query.isEmpty || $0.title.localizedStandardContains(query) }, selection: $selection) { component in
                Text(component.title).tag(component)
            }.searchable(text: $query).navigationTitle("64 native components")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CNButtonGroup {
                        CNTypography(LocalizedStringKey(selection?.title ?? "Components"), style: .title)
                        Spacer()
                        CNSwitch("Dark appearance", isOn: $dark)
                    }
                    if let selection {
                        selection.example.id(selection).tw("p-6 w-full")
                        GalleryCodePanel(source: selection.source).id(selection)
                    }
                }.tw("p-6 w-full")
            }.tw("bg-background")
        }.preferredColorScheme(dark ? .dark : .light).cnPopoverHost()
    }
}
