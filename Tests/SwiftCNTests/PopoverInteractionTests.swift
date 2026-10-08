#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Popover pointer interaction", .serialized)
@MainActor
struct PopoverInteractionTests {
    @Test(arguments: [false, true])
    func datePickerCentersItsCalendarOnTheInputAndKeepsTheTriggerClickable(rtl: Bool) async throws {
        let model = DatePickerPopoverModel()
        let controller = NSHostingController(rootView: VStack {
            CNDatePicker("Delivery date", selection: Binding(get: { model.date }, set: { model.date = $0 }))
                .frame(width: 320)
                .background { GeometryReader { geometry in
                    Color.clear.preference(key: PointerTriggerBounds.self,
                        value: geometry.frame(in: .named("pointer-root")))
                } }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .coordinateSpace(name: "pointer-root")
            .onPreferenceChange(PointerTriggerBounds.self) { model.inputBounds = $0 }
            .cnPopoverHost().environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 800, height: 500),
                              styleMask: [.titled], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(controller.view, seconds: 0.2)
        let input = try #require(model.inputBounds)
        let trigger = NSPoint(x: rtl ? input.minX + 28 : input.maxX - 28, y: input.maxY - 18)
        let point = controller.view.convert(trigger, to: nil)
        try click(window, at: point)
        try await settle(controller.view, seconds: 0.3)
        let scroll = try #require(descendants(controller.view).compactMap { $0 as? NSScrollView }.first)
        let viewport = scroll.convert(scroll.bounds, to: controller.view)
        #expect(abs(viewport.midX - input.midX) < 1, "The calendar must center on the whole input, not its icon.")
        try click(window, at: point)
        // Wait for native exit rendering instead of assuming a fixed frame deadline.
        for _ in 0..<20 {
            if descendants(controller.view).compactMap({ $0 as? NSScrollView }).isEmpty { break }
            try await settle(controller.view, seconds: 0.05)
        }
        #expect(descendants(controller.view).compactMap { $0 as? NSScrollView }.isEmpty,
                "Anchoring the whole input must keep the calendar button clickable while open.")
    }
    @Test(arguments: [false, true])
    func popupShadowEscapesOnlyWhenContentFits(oversized: Bool) async throws {
        let controller = NSHostingController(rootView: VStack {
            CNPopover(isPresented: .constant(true)) {
                Color.white.frame(width: oversized ? 520 : 120, height: oversized ? 620 : 60)
                    .shadow(color: .black.opacity(0.8), radius: 8)
            } label: { Text("Open") }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 1, green: 0, blue: 1))
            .cnPopoverHost())
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 300, height: 220),
                              styleMask: [.titled], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(controller.view, seconds: 0.3)
        let scroll = try #require(descendants(controller.view).compactMap { $0 as? NSScrollView }.first)
        let viewport = scroll.convert(scroll.bounds, to: controller.view)
        let sample = CGRect(x: viewport.minX - 3, y: viewport.midY, width: 1, height: 1)
        let bitmap = try #require(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
        if let directory = ProcessInfo.processInfo.environment["SWIFTCN_POPOVER_ARTIFACTS"],
           let png = bitmap.representation(using: .png, properties: [:]) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("viewport-\(oversized).png"))
        }
        let scale = CGFloat(bitmap.pixelsWide) / controller.view.bounds.width
        let y = controller.view.isFlipped ? sample.midY : controller.view.bounds.height - sample.midY
        let color = try #require(bitmap.colorAt(x: Int(sample.midX * scale), y: Int(y * scale))?.usingColorSpace(.sRGB))
        let canvas = try #require(bitmap.colorAt(x: 0, y: bitmap.pixelsHigh - 1)?.usingColorSpace(.sRGB))
        if oversized {
            #expect(abs(color.redComponent - canvas.redComponent) < 0.01 &&
                    abs(color.greenComponent - canvas.greenComponent) < 0.01 &&
                    abs(color.blueComponent - canvas.blueComponent) < 0.01,
                    "Popup content must not paint outside an oversized viewport.")
        } else {
            #expect(color.redComponent < canvas.redComponent - 0.015 && color.blueComponent < canvas.blueComponent - 0.015,
                    "A fitting popup's shadow must extend beyond the rectangular scroll viewport.")
        }
    }
    @Test(arguments: [false, true])
    func oversizedPopoverScrollsWithinTheHostAndPreservesItsEditorOnResize(rtl: Bool) async throws {
        let model = PopoverViewportModel()
        let controller = NSHostingController(rootView: PopoverViewportHarness(model: model)
            .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 300, height: 220),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(controller.view, seconds: 0.3)
        let scroll = try #require(descendants(controller.view).compactMap { $0 as? NSScrollView }.first)
        let editor = try #require(descendants(scroll).compactMap { $0 as? NSTextField }.first)
        let viewport = scroll.convert(scroll.bounds, to: controller.view)
        #expect(viewport.minX >= 7 && viewport.maxX <= 293)
        #expect(viewport.minY >= 7 && viewport.maxY <= 213)
        let document = try #require(scroll.documentView)
        #expect(document.bounds.width > scroll.contentSize.width && document.bounds.height > scroll.contentSize.height)
        scroll.contentView.scroll(to: CGPoint(x: document.bounds.maxX - scroll.contentSize.width,
                                              y: document.bounds.maxY - scroll.contentSize.height))
        scroll.reflectScrolledClipView(scroll.contentView)
        #expect(abs(scroll.documentVisibleRect.maxY - document.bounds.maxY) < 2, "The final menu rows must be reachable.")
        model.draft = "Persistent popup draft"
        window.setContentSize(CGSize(width: 640, height: 720))
        try await settle(controller.view, seconds: 0.2)
        #expect(descendants(controller.view).compactMap { $0 as? NSTextField }.first === editor)
        #expect(editor.stringValue == model.draft)
        #expect(scroll.contentSize.width > 500 && scroll.contentSize.height > 600)
        #expect(scroll.contentSize.width < 624 && scroll.contentSize.height < 704, "Short content keeps its intrinsic size.")
    }
    private func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
    @Test(arguments: [false, true])
    func popoverBuilderChildrenHaveSeparateVerticalFrames(rtl: Bool) async throws {
        let model = PopoverChildFrameModel()
        let controller = NSHostingController(rootView: PopoverBuilderHarness(model: model)
            .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 600, height: 400)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(host, seconds: 0.2)
        let first = try #require(model.frames["Title"])
        let second = try #require(model.frames["Description"])
        #expect(first.maxY < second.minY, "View-builder children must stack instead of overlapping.")
        let trigger = try #require(model.frames["Details"])
        #expect(abs(first.midX - trigger.midX) < 25, "The popup must stay near its edge-aligned trigger in either layout direction.")
    }
    @Test(arguments: [false, true])
    func repeatedTriggerClicksReverseAnUnfinishedTransition(nativeContainer: Bool) async throws {
        let model = PopoverPointerModel()
        let controller = NSHostingController(rootView: PopoverPointerHarness(model: model, nativeContainer: nativeContainer))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 900, height: 600)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(host, seconds: 0.1)
        let bounds = try #require(model.triggerBounds)
        let point = host.convert(NSPoint(x: bounds.midX, y: bounds.midY), to: nil)
        for expected in [true, false, true, false, true, false] {
            try click(window, at: point)
            try await settle(host, seconds: 0.025) // Reverse well before the 150 ms recipe finishes.
            #expect(model.presented == expected, "Every physical trigger click must toggle presentation.")
        }
        try await settle(host, seconds: 0.25)
        #expect(!model.presented, "An old animation must not reopen the popover.")
        #expect(model.darkAppearance && model.customRules, "Popup appearance must retain the root's theme and rules.")
        for expected in [true, false, true, false] {
            try click(window, at: point)
            try await settle(host, seconds: 0.025)
            #expect(model.presented == expected)
        }
        try await settle(host, seconds: 0.25)
        #expect(!model.presented, "Repeated reversals must finish closed without a stale reopening.")
    }
    private func click(_ window: NSWindow, at point: NSPoint) throws {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try #require(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0))
            window.sendEvent(event)
        }
    }
    private func settle(_ host: NSView, seconds: TimeInterval) async throws {
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .seconds(seconds))
    }
}
@MainActor @Observable private final class DatePickerPopoverModel {
    var date = Date(timeIntervalSince1970: 1_760_054_400)
    var inputBounds: CGRect?
}
@MainActor @Observable private final class PopoverChildFrameModel {
    var frames: [String: CGRect] = [:]
}
private struct PopoverBuilderHarness: View {
    let model: PopoverChildFrameModel
    private func row(_ title: String) -> some View {
        Text(title).frame(width: 160, height: 24)
            .background { GeometryReader { geometry in
                Color.clear.preference(key: PopoverChildFrames.self, value: [title: geometry.frame(in: .global)])
            } }
            .onPreferenceChange(PopoverChildFrames.self) { model.frames.merge($0) { _, new in new } }
    }
    var body: some View {
        VStack(alignment: .leading) {
            CNPopover(isPresented: .constant(true)) { row("Title"); row("Description") } label: { row("Details") }
            Spacer()
        }.frame(width: 600, height: 400, alignment: .topLeading).cnPopoverHost()
    }
}
private struct PopoverChildFrames: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
@MainActor @Observable private final class PopoverPointerModel {
    var presented = false
    var triggerBounds: CGRect?
    var darkAppearance = false
    var customRules = false
}
private struct PopoverPointerHarness: View {
    let model: PopoverPointerModel
    let nativeContainer: Bool
    private var controls: some View {
        VStack(alignment: .leading, spacing: 0) {
            CNDropdownMenu("Actions", isPresented: Binding(get: { model.presented }, set: { model.presented = $0 })) {
                CNDropdownMenuItem("Rename", action: {})
                CNDropdownMenuItem("Duplicate", action: {})
                PopoverAppearanceProbe(model: model)
            }.frame(width: 160, height: 40)
                .background { GeometryReader { geometry in
                    Color.clear.preference(key: PointerTriggerBounds.self, value: geometry.frame(in: .named("pointer-root")))
                } }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    var body: some View {
        Group {
            if nativeContainer {
                ScrollView { controls }
            } else { controls }
        }
        .frame(width: 900, height: 600)
        .coordinateSpace(name: "pointer-root")
        .onPreferenceChange(PointerTriggerBounds.self) { model.triggerBounds = $0 }
        .cnPopoverHost()
        .environment(\.colorScheme, .dark)
        .twRules { $0.named["pointer-fixture"] = TWStyle() }
    }

}
private struct PopoverAppearanceProbe: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.twRules) private var rules
    let model: PopoverPointerModel
    var body: some View {
        Color.clear.frame(width: 0, height: 0).accessibilityHidden(true).onAppear {
            model.darkAppearance = scheme == .dark
            model.customRules = rules.named["pointer-fixture"] != nil
        }
    }
}
private struct PointerTriggerBounds: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue(); if !next.isEmpty { value = next }
    }
}
@MainActor @Observable private final class PopoverViewportModel { var draft = "Popup draft" }
private struct PopoverViewportHarness: View {
    @Bindable var model: PopoverViewportModel
    var body: some View {
        VStack {
            CNPopover(isPresented: .constant(true)) {
                VStack {
                    TextField("Draft", text: $model.draft).textFieldStyle(.plain)
                    ForEach(0..<20) { index in Text("Menu row \(index)").frame(height: 24) }
                }.frame(width: 520, height: 620)
            } label: { Text("Open") }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).cnPopoverHost()
    }
}
#endif
