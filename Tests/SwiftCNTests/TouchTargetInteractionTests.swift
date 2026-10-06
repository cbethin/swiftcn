#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Control activation surfaces", .serialized)
@MainActor
struct TouchTargetInteractionTests {
    @Test func paddedButtonsAndToggleRowsActivateOutsideTheirText() async throws {
        try await withHost { model, host, window in
            for key in ["button", "checkbox", "switch", "toggle"] {
                let rect = try #require(model.frames[key])
                try click(window, host: host, point: CGPoint(x: rect.maxX - 4, y: rect.midY))
                try await settle(host)
            }
            #expect(model.buttonActions == 1)
            #expect(model.checked)
            #expect(model.switched)
            #expect(model.toggled)
            // The native indicator must activate once, independently of the background surface.
            let checkbox = try #require(model.frames["checkbox"])
            try click(window, host: host, point: CGPoint(x: checkbox.minX + 8, y: checkbox.midY))
            try await settle(host)
            #expect(!model.checked)
            model.controlsEnabled = false
            try await settle(host)
            try click(window, host: host, point: CGPoint(x: checkbox.maxX - 4, y: checkbox.midY))
            try await settle(host)
            #expect(!model.checked, "The row surface must honor the same disabled environment as its native indicator.")
            let disabled = try #require(model.frames["disabled"])
            try click(window, host: host, point: CGPoint(x: disabled.maxX - 4, y: disabled.midY))
            try await settle(host)
            #expect(model.disabledActions == 0)
        }
    }

    @Test func tableWhitespaceSelectsWithoutDuplicatingNestedControlActions() async throws {
        try await withHost { model, host, window in
            let text = try #require(model.frames["table-text"])
            try click(window, host: host, point: CGPoint(x: text.maxX - 4, y: text.midY))
            try await settle(host)
            #expect(model.rowActions == 1)
            #expect(model.rowSelected)
            let check = try #require(model.frames["table-checkbox"])
            try click(window, host: host, point: CGPoint(x: check.midX, y: check.midY))
            try await settle(host)
            #expect(!model.rowSelected)
            #expect(model.rowActions == 1, "The checkbox handles its own event; row activation must not run too.")
            let action = try #require(model.frames["table-action"])
            try click(window, host: host, point: CGPoint(x: action.midX, y: action.midY))
            try await settle(host)
            #expect(model.cellActions == 1)
            #expect(model.rowActions == 1, "A nested button must retain its independent action.")
        }
    }

    @Test func disclosureWhitespaceAndNestedInputActionsAreInteractive() async throws {
        try await withHost { model, host, window in
            let disclosure = try #require(model.frames["disclosure"])
            try click(window, host: host, point: CGPoint(x: disclosure.midX, y: disclosure.midY))
            try await settle(host)
            #expect(model.expanded)
            let input = try #require(model.frames["input"])
            try click(window, host: host, point: CGPoint(x: input.maxX - 3, y: input.maxY - 3))
            try await settle(host)
            // Key-window focus is checked in the running app; this CLI host cannot become the active app.
            let child = try #require(model.frames["input-action"])
            try click(window, host: host, point: CGPoint(x: child.midX, y: child.midY))
            try await settle(host)
            #expect(model.inputActions == 1)
        }
    }

    private func withHost(_ operation: (HitAreaModel, NSView, NSWindow) async throws -> Void) async throws {
        let model = HitAreaModel()
        let controller = NSHostingController(rootView: HitAreaHarness(model: model))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 500, height: 680)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = controller
        window.makeKeyAndOrderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        try await settle(host)
        try await operation(model, host, window)
    }
    private func click(_ window: NSWindow, host: NSView, point: CGPoint) throws {
        let location = host.convert(point, to: nil)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = try #require(NSEvent.mouseEvent(with: type, location: location, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0))
            window.sendEvent(event)
        }
    }
    private func settle(_ host: NSView) async throws {
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(60))
    }
}

@MainActor @Observable private final class HitAreaModel {
    var frames: [String: CGRect] = [:]
    var buttonActions = 0
    var disabledActions = 0
    var checked = false
    var controlsEnabled = true
    var switched = false
    var toggled = false
    var rowSelected = false
    var rowActions = 0
    var cellActions = 0
    var expanded = false
    var inputFocused = false
    var inputActions = 0
}
private struct HitAreaHarness: View {
    @Bindable var model: HitAreaModel
    @State private var text = "Draft"
    @FocusState private var inputFocused: Bool
    @FocusState private var groupFocused: Bool
    private func measure<V: View>(_ view: V, _ key: String) -> some View {
        view.background { GeometryReader { geometry in
            Color.clear.preference(key: HitAreaFrames.self, value: [key: geometry.frame(in: .named("hit-root"))])
        } }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            measure(CNButton("Go", variant: .ghost, classes: "w-[280] h-[44]") { model.buttonActions += 1 }, "button")
            measure(CNCheckbox("Checkbox", isOn: $model.checked, classes: "w-[280] h-[44]").disabled(!model.controlsEnabled), "checkbox")
            measure(CNSwitch("Switch", isOn: $model.switched, classes: "w-[280] h-[44]"), "switch")
            measure(CNToggle("Toggle", isOn: $model.toggled, classes: "w-[280] h-[44]"), "toggle")
            measure(CNButton("Disabled", classes: "w-[280] h-[44]") { model.disabledActions += 1 }.disabled(true), "disabled")
            CNTable {
                CNTableRow(isSelected: model.rowSelected, onSelect: { model.rowActions += 1; model.rowSelected.toggle() }) {
                    CNTableCell { measure(CNCheckbox("", isOn: $model.rowSelected), "table-checkbox") }
                    measure(CNTableCell("Invoice", classes: "w-[140]"), "table-text")
                    CNTableCell { measure(CNButton("Open", variant: .ghost) { model.cellActions += 1 }, "table-action") }
                }
            }
            measure(CNCollapsible(isExpanded: $model.expanded) { Text("Content") } label: { Text("Details") }, "disclosure")
            measure(CNInput("Name", text: $text, focus: $inputFocused, classes: "w-[280] h-[52]"), "input")
            CNInputGroup(focus: $groupFocused) {
                CNInputGroupField("Name", text: $text)
                measure(CNButton("Submit", variant: .ghost) { model.inputActions += 1 }, "input-action")
            }
            Spacer()
        }.padding(20).frame(width: 500, height: 680, alignment: .topLeading)
            .coordinateSpace(name: "hit-root")
            .onPreferenceChange(HitAreaFrames.self) { model.frames.merge($0) { _, new in new } }
            .onChange(of: inputFocused) { _, value in model.inputFocused = value }
    }
}
private struct HitAreaFrames: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
#endif
