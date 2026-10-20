import SwiftUI
import SwiftCN
#if os(macOS)
import AppKit
#endif

@main struct SwiftCNComponentGalleryApp: App {
    @AppStorage(GalleryPreferences.darkKey) private var dark = false
    init() {
        #if os(macOS)
        // Native panels inherit the app appearance before SwiftUI installs their content.
        NSApplication.shared.appearance = NSAppearance(named:
            UserDefaults.standard.bool(forKey: GalleryPreferences.darkKey) ? .darkAqua : .aqua)
        if let iconURL = Bundle.main.url(forResource: "SwiftCNAppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
        #endif
    }
    var body: some Scene {
        #if os(macOS)
        WindowGroup("SwiftCN Component Gallery") {
            ComponentGalleryView(dark: $dark).cnWindowContent().modifier(GalleryAppearanceSync(dark: dark))
        }
            .cnWindowStyle()
            .defaultSize(width: 1280, height: 860)
        Settings { GallerySettingsView(dark: $dark).modifier(GalleryAppearanceSync(dark: dark)) }
            .windowResizability(.contentSize)
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

#if os(macOS)
/// Both scenes observe the same preference; only a changed appearance reaches AppKit.
struct GalleryAppearanceSync: ViewModifier {
    let dark: Bool
    func body(content: Content) -> some View {
        content.onChange(of: dark, initial: true) { _, dark in
            let name: NSAppearance.Name = dark ? .darkAqua : .aqua
            if NSApplication.shared.appearance?.name != name {
                NSApplication.shared.appearance = NSAppearance(named: name)
            }
        }
    }
}
#endif
