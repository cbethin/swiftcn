#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Popover pointer interaction", .serialized)
@MainActor
struct PopoverInteractionTests {
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
#endif
