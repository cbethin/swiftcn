#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Presentation and reading position", .serialized)
@MainActor
struct PresentationAndScrollingTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["CI"] == "true"
                   || UserDefaults.standard.integer(forKey: "AppleKeyboardUIMode") & 2 != 0,
                   "Requires macOS Keyboard navigation."), arguments: [false, true])
    func closingADialogRestoresOnlyItsOwnTriggerFocus(initiallyOpen: Bool) async throws {
        let model = DialogFocusProbeModel()
        model.open[0] = initiallyOpen
        let controller = NSHostingController(rootView: DialogFocusProbe(model: model))
        // A nonactivating panel gives the SwiftPM process a native key window without foregrounding an app.
        let window = NSPanel(contentRect: CGRect(x: 0, y: 0, width: 600, height: 480),
                             styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(controller.view)
        try #require(window.isKeyWindow, "The keyboard regression needs an active native key window.")
        try #require(NSApplication.shared.isFullKeyboardAccessEnabled,
                     "The keyboard regression needs macOS Keyboard navigation enabled.")
        for index in [0, 1, 0, 1] {
            model.open[index] = true
            try await settle(controller.view)
            model.open[index] = false
            try await settle(controller.view)
            let key = index == 0 ? " " : "\r"
            for type in [NSEvent.EventType.keyDown, .keyUp] {
                let event = try #require(NSEvent.keyEvent(with: type, location: .zero, modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                    context: nil, characters: key, charactersIgnoringModifiers: key, isARepeat: false,
                    keyCode: index == 0 ? 49 : 36))
                NSApplication.shared.sendEvent(event)
            }
            try await settle(controller.view)
            #expect(model.open[index], "Space and Return must activate the restored trigger.")
            #expect(!model.open[1 - index], "Keyboard activation must open only the focused dialog.")
            model.open[index] = false
            try await settle(controller.view)
        }
    }
    @Test func nativeDrawerDismissalRunsTheCallbackAndPreservesTheCaller() async throws {
        let model = NativeDrawerProbeModel()
        let controller = NSHostingController(rootView: NativeDrawerProbe(model: model))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 600, height: 480),
                              styleMask: [.titled], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        for _ in 0..<2 {
            model.open = true
            try await settle(controller.view, seconds: 0.6)
            let sheet = try #require(window.attachedSheet)
            let content = try #require(sheet.contentView)
            let editor = try #require(descendants(content).compactMap { $0 as? NSTextField }.first)
            #expect(editor.stringValue == model.draft)
            model.draft = "Persistent caller draft"
            model.detent = .large
            try await settle(content)
            #expect(descendants(content).compactMap { $0 as? NSTextField }.first === editor)
            #expect(editor.stringValue == model.draft)
            let close = try #require(model.close)
            close()
            try await settle(controller.view, seconds: 0.6)
            #expect(!model.open && window.attachedSheet == nil)
        }
        #expect(model.dismissals == 2)
        #expect(model.outerDismissals == 0)
    }
    @Test func nativeFormattedFieldSurvivesRecipeAndEnabledChanges() async throws {
        let model = NativeFieldProbeModel()
        let controller = NSHostingController(rootView: NativeFieldProbe(model: model))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 360, height: 240),
                              styleMask: [.titled], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(controller.view)
        let editor = try #require(descendants(controller.view).compactMap { $0 as? NSTextField }.first)
        #expect(editor.stringValue == "12.5")
        model.amount = 42.25; model.compact = true; model.disabled = true
        try await settle(controller.view)
        #expect(descendants(controller.view).compactMap { $0 as? NSTextField }.first === editor)
        #expect(editor.stringValue == "42.25" && !editor.isEnabled)
        model.disabled = false; model.compact = false
        try await settle(controller.view)
        #expect(descendants(controller.view).compactMap { $0 as? NSTextField }.first === editor)
        #expect(editor.isEnabled && model.amount == 42.25)
    }
    @Test func styledNativeSplitResizesWithoutReplacingTheEditor() async throws {
        let model = PresentationProbeModel()
        let controller = NSHostingController(rootView: NativeSplitProbe(model: model))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 640, height: 240),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(controller.view)
        let split = try #require(descendants(controller.view).compactMap { $0 as? NSSplitView }.first)
        let editor = try #require(descendants(controller.view).compactMap { $0 as? NSTextField }.first)
        let original = split.subviews[0].frame.width
        model.text = "Preserved split draft"
        for position in [320.0, 170.0, 350.0] {
            split.setPosition(position, ofDividerAt: 0)
            try await settle(controller.view)
            #expect(abs(split.subviews[0].frame.width - position) < 2)
            #expect(split.subviews[0].frame.width >= 160 && split.subviews[1].frame.width >= 220)
            #expect(descendants(controller.view).compactMap { $0 as? NSTextField }.first === editor)
        }
        #expect(abs(split.subviews[0].frame.width - original) > 20)
        window.setContentSize(NSSize(width: 520, height: 240))
        try await settle(controller.view)
        #expect(split.subviews[0].frame.width >= 160 && split.subviews[1].frame.width >= 220)
        #expect(editor.stringValue == "Preserved split draft")
    }
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
    @Test(arguments: [0, 1], [false, true])
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
@MainActor @Observable private final class DialogFocusProbeModel {
    var open = [false, false]
}
private struct DialogFocusProbe: View {
    let model: DialogFocusProbeModel
    var body: some View {
        HStack {
            ForEach(0..<2) { index in
                CNDialog(isPresented: Binding(get: { model.open[index] }, set: { model.open[index] = $0 })) {
                    Text("Dialog \(index)")
                } label: { Text("Open \(index)") }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .cnPresentationHost()
    }
}
private struct PresentationProbe: View {
    let model: PresentationProbeModel
    let kind: Int
    var body: some View {
        VStack {
            PresentationEnabledProbe { model.backgroundEnabled = $0 }
            if kind == 0 {
                CNDialog(isPresented: Binding(get: { model.open }, set: { model.open = $0 })) { popup } label: { Text("Open") }
            } else {
                CNSheet(isPresented: Binding(get: { model.open }, set: { model.open = $0 })) { popup } label: { Text("Open") }
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
@MainActor @Observable private final class NativeDrawerProbeModel {
    var open = false
    var detent = PresentationDetent.medium
    var draft = "Caller draft"
    var dismissals = 0
    var outerDismissals = 0
    @ObservationIgnored var close: (() -> Void)?
}
private struct NativeDrawerProbe: View {
    let model: NativeDrawerProbeModel
    var body: some View {
        CNDrawer(isPresented: Binding(get: { model.open }, set: { model.open = $0 }),
                 detents: [.medium, .large],
                 selection: Binding(get: { model.detent }, set: { model.detent = $0 }),
                 onDismiss: { model.dismissals += 1 }) {
            NativeDrawerDismissProbe(model: model)
        } label: { Text("Open drawer") }
            .environment(\.cnPresentationDismiss, { model.outerDismissals += 1 })
    }
}
private struct NativeDrawerDismissProbe: View {
    let model: NativeDrawerProbeModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.cnPresentationDismiss) private var customDismiss
    var body: some View {
        CNInput("Draft", text: Binding(get: { model.draft }, set: { model.draft = $0 }))
            .onAppear {
                model.close = { dismiss() }
                #expect(customDismiss == nil, "A native sheet must not inherit a custom panel dismissal.")
            }
    }
}
@MainActor @Observable private final class NativeFieldProbeModel {
    var amount = 12.5
    var compact = false
    var disabled = false
}
private struct NativeFieldProbe: View {
    let model: NativeFieldProbeModel
    private enum Field: Hashable { case amount }
    @FocusState private var focused: Field?
    var body: some View {
        TextField("Amount", value: Binding(get: { model.amount }, set: { model.amount = $0 }), format: .number)
            .textFieldStyle(.tw("input", state: .init(isFocused: focused == .amount)))
            .focused($focused, equals: .amount)
            .disabled(model.disabled)
            .twRules {
                if model.compact { $0.named["input"] = "px-3 py-1 min-h-[44] border rounded-lg bg-surface" }
            }
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
    }
}
private struct NativeSplitProbe: View {
    let model: PresentationProbeModel
    var body: some View {
        HSplitView {
            Text("Inspector").frame(maxWidth: .infinity, maxHeight: .infinity)
                .tw("min-w-[160] bg-surface")
            TextField("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
                .textFieldStyle(.tw("input"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tw("min-w-[220] bg-surface")
        }.tw("border rounded-lg")
    }
}
#endif
