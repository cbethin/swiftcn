#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCNComponentGallery

@Suite("Native split sizing", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_SPLIT_SIZING_TESTS"] == "1"))
@MainActor
struct NativeSplitSizingTests {
    @Test func splitExampleAllowsBothPanesToGrow() throws {
        try verifySizing(NativeSplitExample(), positions: [220, 550, 250], minimumDetail: 220)
    }

    @Test func navigationExampleAllowsAWideSidebar() throws {
        try verifySizing(NativeNavigationExample(), positions: [200, 500, 240], minimumDetail: 300)
    }

    private func verifySizing<V: View>(_ root: V, positions: [CGFloat], minimumDetail: CGFloat) throws {
        let controller = NSHostingController(rootView: root)
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 900, height: 560),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        settle(controller.view)
        let split = try #require(descendants(controller.view).compactMap { $0 as? NSSplitView }
            .first(where: { $0.isVertical && $0.arrangedSubviews.count == 2 }))
        let editor = try #require(descendants(controller.view).compactMap { $0 as? NSTextView }.first)
        editor.string = "A draft survives native pane resizing."
        editor.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: editor))
        window.makeFirstResponder(editor)

        for position in positions {
            split.setPosition(position, ofDividerAt: 0)
            settle(controller.view)
            #expect(abs(split.arrangedSubviews[0].frame.width - position) < 3,
                    "The real gallery example must resize beyond its intrinsic or default column width.")
            #expect(split.arrangedSubviews[1].frame.width >= minimumDetail - 1)
            #expect(descendants(controller.view).compactMap { $0 as? NSTextView }.first === editor)
            #expect(editor.string == "A draft survives native pane resizing.")
            #expect(window.firstResponder === editor)
        }
        window.setContentSize(NSSize(width: 640, height: 560))
        settle(controller.view)
        #expect(split.arrangedSubviews[1].frame.width >= minimumDetail - 1)
        #expect(editor.string == "A draft survives native pane resizing.")
    }

    private func settle(_ view: NSView) {
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        view.layoutSubtreeIfNeeded()
    }

    private func descendants(_ root: NSView) -> [NSView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}
#endif
