#if os(macOS)
import AppKit
import SwiftUI
import Observation
import Testing
@testable import SwiftCNComponentGallery

// Run separately: this probe changes the test process's native application appearance.
@Suite("Gallery native presentation appearance", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_GALLERY_APPEARANCE_TESTS"] == "1"))
@MainActor
struct GalleryAppearanceTests {
    @Test func firstPanelInheritsLightAppearanceBeforePresentation() throws {
        let app = NSApplication.shared
        let saved = app.appearance
        defer { app.appearance = saved }
        app.appearance = NSAppearance(named: .darkAqua)
        #expect(newPanelAppearance() == .darkAqua)
        _ = SwiftCNComponentGalleryApp()
        #expect(newPanelAppearance() == .aqua,
                "The first native panel must already be light before SwiftUI installs a preferred color scheme.")
    }

    @Test func galleryToggleUpdatesTheSourceOfFutureNativePanels() {
        let app = NSApplication.shared
        let saved = app.appearance
        defer { app.appearance = saved }
        _ = SwiftCNComponentGalleryApp()
        let model = GalleryAppearanceModel()
        let host = NSHostingView(rootView: ComponentGalleryView(dark: Binding(
            get: { model.dark }, set: { model.dark = $0 })))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        settle(host)
        #expect(newPanelAppearance() == .aqua)
        model.dark = true
        settle(host)
        #expect(newPanelAppearance() == .darkAqua)
        model.dark = false
        settle(host)
        #expect(newPanelAppearance() == .aqua)
    }

    private func newPanelAppearance() -> NSAppearance.Name? {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 280),
                            styleMask: [.titled], backing: .buffered, defer: false)
        return panel.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
    }
    private func settle<V: View>(_ host: NSHostingView<V>) {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        host.layoutSubtreeIfNeeded()
    }
}
@MainActor @Observable private final class GalleryAppearanceModel {
    var dark = false
}
#endif
