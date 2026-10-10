#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Composable command and toast content", .serialized)
@MainActor
struct ComposableContentTests {
    @Test func customCommandLabelsKeepNativeActivationFilteringAndTheEditor() async throws {
        let model = ContentSlotModel()
        let controller = NSHostingController(rootView: CommandSlotHarness(model: model))
        let window = window(controller)
        defer { window.orderOut(nil); window.contentViewController = nil; model.contexts.removeAll() }
        let host = controller.view
        try await settle(host)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        try click(window, host: host, frame: #require(model.frames["archive"]))
        try await settle(host)
        #expect(model.selection == nil && model.actions.isEmpty)
        let identity = try #require(model.identities["mobile"])
        try click(window, host: host, frame: #require(model.frames["mobile"]))
        try await settle(host)
        #expect(model.selection == "mobile" && model.actions == ["mobile"])
        #expect(model.selectedLabels["mobile"] == true)
        #expect(model.identities["mobile"] == identity)
        editor.stringValue = "Design"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        try await settle(host)
        #expect(model.query == "Design")
        #expect(model.frames["mobile"] == nil && model.frames["design"] != nil)
        model.query = "No match"
        try await settle(host)
        #expect(model.frames["empty"] != nil && model.frames["design"] == nil)
        model.query = ""
        try await settle(host)
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
    }

    @Test func customToastControlsPauseDeadlinesAndSurviveDeckExpansion() async throws {
        let model = ContentSlotModel()
        let toast = CNToast(title: "Draft", duration: 0.7)
        model.toasts = [toast]
        let controller = NSHostingController(rootView: ToastSlotHarness(model: model))
        let window = window(controller)
        defer { window.orderOut(nil); window.contentViewController = nil; model.contexts.removeAll() }
        let host = controller.view
        try await settle(host)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        let context = try #require(model.contexts[toast.id])
        context.focus.wrappedValue = model.editorID
        try await settle(host)
        #expect(context.focus.wrappedValue == model.editorID)
        #expect(editor.currentEditor() != nil && window.firstResponder === editor.currentEditor())
        editor.stringValue = "Unfinished draft"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        try await Task.sleep(for: .milliseconds(800))
        #expect(model.toasts.map(\.id) == [toast.id], "A focused custom editor must pause its toast's deadline.")
        model.toasts[0].message = "Updated while reading"
        try await settle(host)
        context.dismiss()
        #expect(model.toasts.count == 1, "An older content context must not dismiss an updated toast.")
        model.toasts.append(CNToast(title: "Second", duration: nil))
        model.expanded = true
        try await settle(host)
        #expect(descendants(host).compactMap { $0 as? NSTextField }.contains { $0 === editor })
        #expect(model.draft == "Unfinished draft")
        let frame = try #require(model.frames[toast.id.uuidString])
        #expect(host.bounds.contains(CGPoint(x: frame.midX, y: frame.midY)), "Action frame: \(frame), host: \(host.bounds)")
        try click(window, host: host, frame: frame)
        try await settle(host)
        #expect(model.actions == ["undo"])
        #expect(!model.toasts.contains { $0.id == toast.id })
        #expect(model.toasts.count == 1, "A custom action dismisses only its own toast.")
    }

    private func window<V: View>(_ controller: NSHostingController<V>) -> NSWindow {
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 420, height: 440),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        return window
    }
    private func click(_ window: NSWindow, host: NSView, frame: CGRect) throws {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        var hit = host.hitTest(host.convert(center, to: host.superview))
        while let view = hit {
            if let button = view as? NSButton {
                // Before macOS 26, AppKit buttons track the mouse modally, which synthesized events never end.
                // SwiftUI's AppKit-backed buttons on macOS 26 and later take synthesized events; their activation
                // API stops this CLI fixture's main run loop.
                if #available(macOS 26, *) { break }
                if button.isEnabled { button.performClick(nil) }
                return
            }
            hit = view.superview
        }
        let point = host.convert(center, to: nil)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try #require(NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0))
            window.sendEvent(event)
        }
    }
    private func settle(_ host: NSView) async throws {
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(120))
        host.layoutSubtreeIfNeeded()
    }
    private func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
}

@MainActor @Observable private final class ContentSlotModel {
    var query = ""
    var selection: String?
    var draft = "Initial draft"
    var toasts: [CNToast] = []
    var expanded = false
    let editorID = UUID()
    @ObservationIgnored var actions: [String] = []
    @ObservationIgnored var frames: [String: CGRect] = [:]
    @ObservationIgnored var identities: [String: UUID] = [:]
    @ObservationIgnored var selectedLabels: [String: Bool] = [:]
    @ObservationIgnored var contexts: [UUID: CNToastContentContext] = [:]
}
private struct CommandSlotHarness: View {
    @Bindable var model: ContentSlotModel
    var body: some View {
        CNCommand([CNOption("design", title: "Design"), CNOption("archive", title: "Archived", isDisabled: true),
                   CNOption("mobile", title: "Mobile")], selection: $model.selection, query: $model.query,
                  classes: "h-[300]", onSelect: { model.actions.append($0) })
            .itemContent { option, selected in
                CommandSlotLabel(model: model, option: option, selected: selected)
            } empty: {
                Text("Custom empty state").modifier(ContentSlotFrame(model: model, key: "empty"))
            }
            .coordinateSpace(name: "slot-host")
    }
}
private struct CommandSlotLabel: View {
    let model: ContentSlotModel
    let option: CNOption<String>
    let selected: Bool
    @State private var identity = UUID()
    var body: some View {
        HStack { Text(option.title); Spacer(); if selected { Text("Chosen") } }
            .modifier(ContentSlotFrame(model: model, key: option.id))
            .onAppear { model.identities[option.id] = identity }
            .onChange(of: selected, initial: true) { _, value in model.selectedLabels[option.id] = value }
    }
}
private struct ToastSlotHarness: View {
    @Bindable var model: ContentSlotModel
    var body: some View {
        CNToastHost(toasts: $model.toasts, isExpanded: $model.expanded) {
            Text("Background").frame(maxWidth: .infinity, maxHeight: .infinity)
        }
            .toastContent { context in
                VStack(alignment: .leading, spacing: 8) {
                    Text(context.toast.title)
                    TextField("Draft", text: $model.draft)
                        .focused(context.focus, equals: model.editorID)
                        .accessibilityFocused(context.accessibilityFocus, equals: model.editorID)
                    context.action(action: { model.actions.append("undo"); context.dismiss() }) {
                        Text("Undo").modifier(ContentSlotFrame(model: model, key: context.toast.id.uuidString))
                    }
                }
                .onAppear { model.contexts[context.toast.id] = context }
            }
            .coordinateSpace(name: "slot-host")
            .twRules(.init(named: ["feedback-motion": "animate-none"]))
    }
}
private struct ContentSlotFrame: ViewModifier {
    let model: ContentSlotModel
    let key: String
    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named("slot-host")) }) { model.frames[key] = $0 }
            .onDisappear { model.frames[key] = nil }
    }
}
#endif
