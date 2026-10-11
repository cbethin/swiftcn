import SwiftUI
import SwiftCN
#if os(macOS)
import AppKit
#endif

@main struct SwiftCNComponentGalleryApp: App {
    @State private var dark = false
    init() {
        #if os(macOS)
        // Native panels inherit the app appearance before SwiftUI installs their content.
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        #endif
    }
    var body: some Scene {
        #if os(macOS)
        WindowGroup("SwiftCN Component Gallery") { ComponentGalleryView(dark: $dark) }
            .defaultSize(width: 1040, height: 760)
        WindowGroup("Native navigation", id: "native-navigation") {
            NativeNavigationGalleryWindow(dark: dark)
        }.defaultSize(width: 840, height: 560)
        WindowGroup("Native arrangement", id: "native-arrangement") {
            NativeArrangementExample().preferredColorScheme(dark ? .dark : .light)
        }.defaultSize(width: 840, height: 560)
        #else
        WindowGroup("SwiftCN Component Gallery") { ComponentGalleryView(dark: $dark) }
        #endif
    }
}

struct ComponentGalleryView: View {
    @State private var selection: CNGallerySelection? = {
        #if DEBUG
        // UI tests start on a real example without changing its controls or interaction.
        if let route = ProcessInfo.processInfo.environment["SWIFTCN_UI_EXAMPLE"] {
            if route.hasPrefix("native:"), let example = CNNativeComposition(rawValue: String(route.dropFirst(7))) {
                return .native(example)
            }
            if let example = CNComponentGallery(rawValue: route) { return .component(example) }
        }
        #endif
        return .component(.button)
    }()
    @State private var query = ""
    @Binding var dark: Bool
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Components") {
                    ForEach(CNComponentGallery.allCases.filter { query.isEmpty || $0.title.localizedStandardContains(query) }) { component in
                        NavigationLink(value: CNGallerySelection.component(component)) { Text(component.title) }
                    }
                }
                Section("Native composition") {
                    ForEach(CNNativeComposition.allCases.filter { query.isEmpty || $0.title.localizedStandardContains(query) }) { composition in
                        NavigationLink(value: CNGallerySelection.native(composition)) { Text(composition.title) }
                    }
                }
            }.searchable(text: $query)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: .infinity)
                .navigationTitle("Swiftcn gallery")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CNButtonGroup {
                        CNTypography(LocalizedStringKey(selection?.title ?? "Components"), style: .title)
                        Spacer()
                        CNSwitch("Dark appearance", isOn: $dark)
                    }
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["SWIFTCN_UI_PROBE"] == "native-button-labels" {
                        NativeButtonLabelProbe()
                    }
                    #endif
                    if let selection {
                        selection.example.id(selection).tw("p-6 w-full")
                        GalleryCodePanel(source: selection.source).id(selection)
                    }
                }.tw("p-6 w-full")
            }.tw("bg-background")
        }.preferredColorScheme(dark ? .dark : .light).cnPopoverHost().cnPresentationHost()
        #if os(macOS)
            .onChange(of: dark, initial: true) { _, dark in
                NSApplication.shared.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
            }
        #endif
    }
}
