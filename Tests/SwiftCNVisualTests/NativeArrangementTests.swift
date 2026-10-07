#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCNComponentGallery

@Suite("Native arrangement state", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_ARRANGEMENT_TESTS"] == "1"))
@MainActor
struct NativeArrangementTests {
    @Test func resizingPreservesTheEditorDraftAndFocus() throws {
        let controller = NSHostingController(rootView: NativeArrangementExample())
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 840, height: 640),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        settle(controller.view)
        let editor = try #require(descendants(controller.view).compactMap { $0 as? NSTextView }.first)
        editor.string = "An unfinished arrangement draft"
        editor.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: editor))
        window.makeFirstResponder(editor)
        for width in [400.0, 840.0, 500.0, 900.0] {
            window.setContentSize(NSSize(width: width, height: 640))
            settle(controller.view)
            #expect(descendants(controller.view).compactMap { $0 as? NSTextView }.first === editor)
            #expect(editor.string == "An unfinished arrangement draft")
            #expect(window.firstResponder === editor)
        }
    }
    private func settle(_ view: NSView) {
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
    }
    private func descendants(_ root: NSView) -> [NSView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}
#endif
