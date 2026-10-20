#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Segmented composition", .serialized)
@MainActor
struct SegmentedControlTests {
    @Test(arguments: [LayoutDirection.leftToRight, .rightToLeft])
    func navigationSkipsDisabledOptionsAndKeepsLabelsAndDraft(direction: LayoutDirection) throws {
        let model = SegmentTestModel()
        let host = NSHostingView(rootView: SegmentFixture(model: model).environment(\.layoutDirection, direction))
        host.setFrameSize(NSSize(width: 500, height: 180))
        let window = NSWindow(contentRect: host.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        settle(host)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first { $0.placeholderString == "Draft" })
        editor.stringValue = "Keep this draft"
        let identities = model.identities
        #expect(identities.count == 4)
        let context = try #require(model.context)
        #expect(context.tabStop == AnyHashable(0))
        // An offscreen host has no active focus scene. Native arrow-key focus is covered by the gallery UI test.
        context.select(AnyHashable(0))
        settle(host)
        #expect(context.navigate(AnyHashable(0), .rightArrow) == .handled)
        settle(host)
        #expect(model.selection == (direction == .leftToRight ? 2 : 3))
        #expect(model.context?.navigate(AnyHashable(model.selection), .leftArrow) == .handled)
        settle(host)
        #expect(model.selection == 0)
        #expect(model.context?.navigate(AnyHashable(0), .upArrow) == .handled)
        settle(host)
        #expect(model.selection == 3)
        #expect(model.identities == identities)
        #expect(descendants(host).contains { $0 === editor })
        #expect(editor.stringValue == "Keep this draft")
        model.enabled = false
        settle(host)
        #expect(model.context?.navigate(AnyHashable(3), .downArrow) == .ignored)
        #expect(model.selection == 3)
    }

    @Test func customGroupAndSidebarLabelsRetainTheirContent() {
        let model = SegmentTestModel()
        let view = CustomLabelFixture(model: model)
        let host = NSHostingView(rootView: view)
        host.setFrameSize(NSSize(width: 500, height: 160))
        let window = NSWindow(contentRect: host.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        settle(host)
        let identities = model.identities
        #expect(identities.count == 3)
        model.multiSelection = [0, 1]
        model.collapsed = true
        settle(host)
        #expect(model.identities == identities, "Custom option and sidebar content must keep its state.")
        #expect(host.fittingSize.width > 0 && host.fittingSize.height > 0)
    }

    private func settle(_ host: NSView) {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.08))
        host.layoutSubtreeIfNeeded()
    }
    private func descendants(_ view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }
}

@MainActor @Observable private final class SegmentTestModel {
    var selection = 0
    var enabled = true
    var draft = "Original"
    var multiSelection: Set<Int> = []
    var collapsed = false
    @ObservationIgnored var context: CNSegmentedContext?
    @ObservationIgnored var identities: [Int: UUID] = [:]
}

private struct SegmentFixture: View {
    let model: SegmentTestModel
    var body: some View {
        VStack {
            CNSegmentedControl(selection: Binding(get: { model.selection }, set: { model.selection = $0 })) {
                ForEach(0..<4) { value in
                    CNSegment(value) {
                        HStack { Text("Option \(value)"); SegmentIdentity(model: model, value: value) }
                    }.disabled(value == 1)
                }
                SegmentContextReader(model: model).frame(width: 0, height: 0)
            }.disabled(!model.enabled).controlSize(.small)
            TextField("Draft", text: Binding(get: { model.draft }, set: { model.draft = $0 })).textFieldStyle(.plain)
        }
    }
}

private struct SegmentIdentity: View {
    let model: SegmentTestModel
    let value: Int
    @State private var id = UUID()
    var body: some View { Color.clear.frame(width: 1, height: 1).onAppear { model.identities[value] = id } }
}

private struct SegmentContextReader: NSViewRepresentable {
    let model: SegmentTestModel
    @Environment(\.cnSegmentedContext) private var context
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ nsView: NSView, context: Context) { model.context = self.context }
}
#endif

#if os(macOS)
private struct CustomLabelFixture: View {
    let model: SegmentTestModel
    var body: some View {
        VStack {
            CNToggleGroup([CNOption(0, title: "Design"), CNOption(1, title: "Mobile", isDisabled: true)],
                          selection: Binding(get: { model.multiSelection }, set: { model.multiSelection = $0 })) { option in
                HStack { Text(option.title); Text("Custom badge"); SegmentIdentity(model: model, value: option.id) }
            }
            CNSidebarMenuButton(isSelected: model.collapsed, action: {}) { context in
                HStack {
                    Label(context.isCollapsed ? "Compact label" : "Custom row", systemImage: "star")
                    SegmentIdentity(model: model, value: 99)
                }
            }.environment(\.cnSidebarContext, CNSidebarContext(isCollapsed: model.collapsed))
        }
    }
}
#endif
