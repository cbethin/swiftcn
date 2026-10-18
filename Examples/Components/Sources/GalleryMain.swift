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
        if let iconURL = Bundle.main.url(forResource: "SwiftCNAppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
        #endif
    }
    var body: some Scene {
        #if os(macOS)
        WindowGroup("SwiftCN Component Gallery") { ComponentGalleryView(dark: $dark) }
            .windowStyle(.hiddenTitleBar)
            .defaultSize(width: 1280, height: 860)
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
