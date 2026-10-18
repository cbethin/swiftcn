#if os(macOS)
import AppKit
import Observation
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Integrated native window chrome", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_WINDOW_CHROME_TESTS"] == "1"))
@MainActor
struct WindowChromeTests {
    @Test(arguments: [LayoutDirection.leftToRight, .rightToLeft])
    func controlsStayClearOfNativeButtonsWhileSidebarChangesPreserveTheEditor(direction: LayoutDirection) throws {
        let model = WindowChromeModel()
        let controller = NSHostingController(rootView: WindowChromeHarness(model: model).cnWindowContent()
            .environment(\.layoutDirection, direction))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 800, height: 460),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.contentViewController = controller
        defer { window.contentViewController = nil }
        settle(controller.view)
        #expect(window.titleVisibility == .hidden)
        #expect(window.titlebarAppearsTransparent)
        #expect(window.titlebarSeparatorStyle == .none)
        #expect(window.styleMask.contains(.fullSizeContentView))
        let editor = try #require(descendants(controller.view).compactMap { $0 as? NSTextField }.first)
        editor.stringValue = "A working draft"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        for sidebarVisible in [false, true, false] {
            model.sidebarVisible = sidebarVisible
            window.setContentSize(NSSize(width: sidebarVisible ? 800 : 640, height: 460))
            settle(controller.view)
            let buttons = [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton]
                .compactMap(window.standardWindowButton)
            #expect(buttons.count == 3 && buttons.allSatisfy { !$0.isHidden })
            let controls = buttons.map { $0.convert($0.bounds, to: nil) }.reduce(CGRect.null) { $0.union($1) }
            let probe = try #require(model.editorProbe)
            #expect(probe.convert(probe.bounds, to: nil).minX > controls.maxX)
            let action = try #require(model.actionProbe)
            #expect(action.convert(action.bounds, to: nil).minX > controls.maxX)
            if sidebarVisible {
                let sidebar = try #require(model.sidebarProbe)
                #expect(sidebar.convert(sidebar.bounds, to: nil).maxY < controls.minY)
            }
            #expect(descendants(controller.view).compactMap { $0 as? NSTextField }.first === editor)
            #expect(editor.stringValue == "A working draft" && model.draft == "A working draft")
        }
    }

    @Test func overlappingRootsRestoreChromeOnlyAfterTheLastRootLeaves() {
        let originalMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 640, height: 460),
                              styleMask: originalMask, backing: .buffered, defer: false)
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.titlebarSeparatorStyle = .line
        let container = NSView(frame: window.contentView!.bounds)
        window.contentView = container
        let first = NSHostingView(rootView: Text("First").cnWindowContent())
        let second = NSHostingView(rootView: Text("Second").cnWindowContent())
        for root in [first, second] {
            root.frame = container.bounds
            container.addSubview(root)
        }
        settle(container)
        #expect(window.styleMask == originalMask.union(.fullSizeContentView))
        #expect(window.titleVisibility == .hidden)
        first.removeFromSuperview()
        settle(container)
        #expect(window.titleVisibility == .hidden)
        #expect(window.styleMask.contains(.fullSizeContentView))
        second.removeFromSuperview()
        settle(container)
        #expect(window.titleVisibility == .visible)
        #expect(!window.titlebarAppearsTransparent)
        #expect(window.titlebarSeparatorStyle == .line)
        #expect(window.styleMask == originalMask)
    }

    private func settle(_ view: NSView) {
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        view.layoutSubtreeIfNeeded()
    }

    private func descendants(_ root: NSView) -> [NSView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}

@MainActor @Observable private final class WindowChromeModel {
    var sidebarVisible = false
    var draft = "Project"
    @ObservationIgnored weak var editorProbe: NSView?
    @ObservationIgnored weak var actionProbe: NSView?
    @ObservationIgnored weak var sidebarProbe: NSView?
}

private struct WindowChromeHarness: View {
    @Bindable var model: WindowChromeModel
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        HStack(spacing: 0) {
            if model.sidebarVisible {
                VStack(spacing: 0) {
                    CNWindowControlsSpacer(axis: .vertical)
                    Text("Sidebar").frame(height: 44)
                        .background { WindowChromeProbe { model.sidebarProbe = $0 } }
                    Spacer()
                }.frame(width: 248)
            }
            VStack(spacing: 0) {
                CNWindowHeader(reservesWindowControls: !model.sidebarVisible || direction == .rightToLeft) {
                    HStack {
                        TextField("Project", text: $model.draft).frame(width: 160)
                            .background { WindowChromeProbe { model.editorProbe = $0 } }
                        Spacer()
                        Button("Action", action: {})
                            .background { WindowChromeProbe { model.actionProbe = $0 } }
                    }
                }
                Spacer()
            }
        }
    }
}

private struct WindowChromeProbe: NSViewRepresentable {
    let capture: (NSView) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        capture(view)
        return view
    }
    func updateNSView(_ view: NSView, context: Context) {}
}
#endif
