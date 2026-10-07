#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Presentation and reading position", .serialized)
@MainActor
struct PresentationAndScrollingTests {
    @Test func longDialogContentUsesABoundedNativeViewport() async throws {
        let model = PresentationProbeModel()
        model.open = true; model.longContent = true
        let controller = NSHostingController(rootView: PresentationProbe(model: model, kind: 0))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 360, height: 400),
                              styleMask: [.titled], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(controller.view)
        let scroll = try #require(descendants(controller.view).compactMap { $0 as? NSScrollView }.first)
        let document = try #require(scroll.documentView)
        #expect(scroll.contentSize.height > 100 && scroll.contentSize.height < 400)
        #expect(document.bounds.height > scroll.contentSize.height * 3)
    }
    @Test(arguments: [0, 1, 2], [false, true])
    func panelsHaveDistinctPlacementAndReverseWithoutReplacingTheEditor(kind: Int, disableMotion: Bool) async throws {
        let model = PresentationProbeModel()
        let controller = NSHostingController(rootView: PresentationProbe(model: model, kind: kind)
            .twRules { $0.named["presentation-motion"] = disableMotion ? "animate-none" : "animate-spring duration-300" })
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 800, height: 600),
                              styleMask: [.titled], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        let host = controller.view
        try await settle(host)
        #expect(model.backgroundEnabled)
        model.open = true
        try await settle(host)
        #expect(!model.backgroundEnabled && model.popupEnabled)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        let frame = editor.convert(editor.bounds, to: host)
        let scroll = try #require(descendants(host).compactMap { $0 as? NSScrollView }.first)
        let viewport = scroll.convert(scroll.bounds, to: host)
        #expect(frame.intersection(viewport).height > 10, "The editor must be visible inside a nonzero viewport.")
        if kind == 0 { #expect(abs(frame.midX - 400) < 5) }
        if kind == 1 { #expect(frame.minX >= 390) }
        if kind == 2 { #expect(frame.midY > 450) }
        model.text = "a persistent draft"
        model.animations.removeAll()
        for open in [false, true, false, true] {
            model.open = open
            try await settle(host, seconds: 0.025)
            #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        }
        try await settle(host)
        #expect(model.text == "a persistent draft")
        if disableMotion || model.reduceMotion {
            #expect(model.animations.allSatisfy { $0 == nil })
        } else {
            #expect(model.animations.contains { $0 != nil }, "Presentation motion must reach the mounted content.")
        }
        let dismiss = try #require(model.dismiss)
        dismiss()
        try await settle(host)
        #expect(!model.open && model.backgroundEnabled)
    }
    @Test(arguments: [0.0, 13.0])
    func restoringAndPrependingHistoryKeepTheSameReadingTarget(partialOffset: CGFloat) async throws {
        let model = ScrollProbeModel()
        let controller = NSHostingController(rootView: ScrollProbe(model: model))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 400, height: 240),
                              styleMask: [.titled], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        let host = controller.view
        try await settle(host)
        #expect(model.position == 12)
        let scroll = try #require(descendants(host).compactMap { $0 as? NSScrollView }.first)
        #expect(abs(scroll.documentVisibleRect.minY - 12 * 48) < 2,
                "The native viewport must start at the requested target: \(scroll.documentVisibleRect).")
        if partialOffset > 0 {
            var origin = scroll.documentVisibleRect.origin; origin.y += partialOffset
            scroll.contentView.scroll(to: origin); scroll.reflectScrolledClipView(scroll.contentView)
            try await settle(host)
        }
        let original = scroll.documentVisibleRect.minY
        model.rows.insert(contentsOf: (-5..<0).map { ScrollProbeRow(id: $0) }, at: 0)
        try await settle(host)
        #expect(model.position == 12)
        let afterPrepend = scroll.documentVisibleRect.minY
        #expect(abs(afterPrepend - original - 5 * 48) < 2, "Original native offset: \(original); after prepend: \(afterPrepend)")
        model.rows.append(ScrollProbeRow(id: 100))
        try await settle(host)
        #expect(model.position == 12, "New messages must not pull a paused reader to the bottom.")
        model.revision += 1
        try await settle(host)
        #expect(model.position == 12, "Stream revisions must also respect paused following.")
        model.follow = true
        try await settle(host)
        let document = try #require(scroll.documentView)
        #expect(abs(scroll.documentVisibleRect.maxY - document.bounds.maxY) < 2, "Resuming following must reach the end.")
        model.latestHeight = 160; model.revision += 1
        try await settle(host)
        #expect(abs(scroll.documentVisibleRect.maxY - document.bounds.maxY) < 2, "Streaming growth must keep the end visible.")
        window.setContentSize(NSSize(width: 400, height: 180))
        try await settle(host)
        #expect(abs(scroll.documentVisibleRect.maxY - document.bounds.maxY) < 2,
                "Viewport changes must retain following: visible \(scroll.documentVisibleRect), document \(document.bounds).")

    }
    private func settle(_ host: NSView, seconds: Double = 0.4) async throws {
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .seconds(seconds))
        host.layoutSubtreeIfNeeded()
    }
    private func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
}
@MainActor @Observable private final class PresentationProbeModel {
    var open = false
    var text = "Draft"
    var longContent = false
    @ObservationIgnored var backgroundEnabled = true
    @ObservationIgnored var popupEnabled = false
    @ObservationIgnored var animations: [Animation?] = []
    @ObservationIgnored var reduceMotion = false
    @ObservationIgnored var dismiss: (() -> Void)?
}
private struct PresentationProbe: View {
    let model: PresentationProbeModel
    let kind: Int
    var body: some View {
        VStack {
            PresentationEnabledProbe { model.backgroundEnabled = $0 }
            if kind == 0 {
                CNDialog(isPresented: Binding(get: { model.open }, set: { model.open = $0 })) { popup } label: { Text("Open") }
            } else if kind == 1 {
                CNSheet(isPresented: Binding(get: { model.open }, set: { model.open = $0 })) { popup } label: { Text("Open") }
            } else {
                CNDrawer(isPresented: Binding(get: { model.open }, set: { model.open = $0 })) { popup } label: { Text("Open") }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .cnPresentationHost()
    }
    private var popup: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.longContent { ForEach(0..<100) { Text("Long dialog content \($0)") } }
            PresentationEditorProbe(model: model)
        }
    }
}
private struct PresentationEnabledProbe: View {
    @Environment(\.isEnabled) private var enabled
    let record: (Bool) -> Void
    var body: some View {
        record(enabled)
        return Text("Background")
    }
}
private struct PresentationEditorProbe: View {
    let model: PresentationProbeModel
    @Environment(\.isEnabled) private var enabled
    @Environment(\.cnPresentationDismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        model.popupEnabled = enabled; model.dismiss = dismiss; model.reduceMotion = reduceMotion
        return CNInput("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
            .transaction { model.animations.append($0.animation) }

    }
}
private struct ScrollProbeRow: Identifiable { let id: Int }
@MainActor @Observable private final class ScrollProbeModel {
    var rows = (0..<40).map { ScrollProbeRow(id: $0) }
    var position: Int? = 12
    var revision = 0
    var follow = false
    var latestHeight: CGFloat = 40
}
private struct ScrollProbe: View {
    let model: ScrollProbeModel
    var body: some View {
        CNMessageScroller(model.rows, followNewMessages: model.follow, scrollRevision: model.revision,
                          position: Binding(get: { model.position }, set: { model.position = $0 })) { row in
            Text("Message \(row.id)").frame(height: row.id == model.rows.last?.id ? model.latestHeight : 40)
        }
    }
}
#endif
