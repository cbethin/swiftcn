#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Catalog native controls", .serialized)
@MainActor
struct CatalogNativeRenderingTests {
    @Test(arguments: [false, true])
    func sidebarMotionReachesDetailAndHonorsGlobalOverrides(disableMotion: Bool) {
        let model = SidebarControlModel()
        let controller = NSHostingController(rootView:
            SidebarControlHarness(model: model, collapsible: .icon)
                .twRules(.init(named: ["sidebar-motion": disableMotion ? "animate-none" : "animate-smooth duration-250"])))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 800, height: 400)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        settle(host)
        model.animations.removeAll()
        model.context.toggle(); settle(host)
        if disableMotion || model.reduceMotion {
            #expect(model.animations.allSatisfy { $0 == nil })
        } else {
            #expect(model.animations.contains { $0 != nil }, "The sidebar must animate its detail layout transaction.")
        }
        #expect(Set(model.identities).count == 1)
    }
    @Test(arguments: [CNSidebarCollapsible.icon, .offcanvas, .none])
    func sidebarRetargetsWithoutReplacingTheDetailEditor(collapsible: CNSidebarCollapsible) throws {
        let model = SidebarControlModel()
        let controller = NSHostingController(rootView: SidebarControlHarness(model: model, collapsible: collapsible))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 800, height: 400)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentViewController = controller; window.orderFront(nil)
        defer { window.orderOut(nil); window.contentViewController = nil }
        settle(host)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        editor.stringValue = "unfinished draft"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        // Two actions can arrive before SwiftUI recomputes the environment context.
        model.context.toggle(); model.context.toggle()
        #expect(model.visibility == .all)
        settle(host)
        for expected in [false, true, false, true, false, true] {
            model.context.toggle()
            host.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.025))
            #expect(model.context.isPresented == (collapsible == .none || expected))
            #expect(model.context.canToggle == (collapsible != .none))
            #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        }
        #expect(model.text == "unfinished draft")
        #expect(Set(model.identities).count == 1)
    }
    @Test func compactSidebarStateDoesNotChangeDesktopVisibilityOrReplaceTheEditor() throws {
        let model = SidebarControlModel()
        let controller = NSHostingController(rootView: SidebarControlHarness(model: model, collapsible: .icon))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 800, height: 400)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentViewController = controller
        defer { window.contentViewController = nil }
        settle(host)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        model.visibility = .detailOnly; settle(host)
        #expect(model.context.isCollapsed)
        host.frame.size.width = 360; settle(host)
        #expect(model.context.isCompact && !model.context.isPresented && !model.context.isCollapsed)
        model.context.toggle(); settle(host)
        #expect(model.mobile && model.context.isPresented)
        #expect(model.visibility == .detailOnly)
        model.context.dismiss(); settle(host)
        #expect(!model.mobile)
        model.context.toggle(); settle(host)
        host.frame.size.width = 800; settle(host)
        #expect(!model.context.isCompact && model.context.isCollapsed && !model.mobile)
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        #expect(Set(model.identities).count == 1)
    }
    @Test func nativeTabsChangeSelectionWithoutReplacingTheirItems() throws {
        let model = CatalogControlModel()
        let view = CNTabs(selection: Binding(get: { model.tab }, set: { model.tab = $0 })) {
            Text("Account settings").tabItem { Text("Account") }.tag(0)
            Text("Security settings").tabItem { Text("Security") }.tag(1)
        }.frame(height: 180)
        let (host, window) = host(view)
        defer { window.contentView = nil }
        let tabs = try #require(descendants(host).compactMap { $0 as? NSTabView }.first)
        #expect(tabs.numberOfTabViewItems == 2)
        let account = tabs.tabViewItem(at: 0)
        let security = tabs.tabViewItem(at: 1)
        model.tab = 1
        settle(host)
        #expect(tabs.selectedTabViewItem === security)
        #expect(tabs.tabViewItem(at: 0) === account)
        tabs.selectTabViewItem(account)
        settle(host)
        #expect(model.tab == 0)
    }
    @Test func actionReflowKeepsTheSameNativeEditor() throws {
        let model = CatalogControlModel()
        let (host, window) = host(CatalogActionProbe(model: model))
        defer { window.contentView = nil }
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        let rowHeight = host.fittingSize.height
        editor.stringValue = "draft"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        model.narrow = true
        settle(host)
        let stacked = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        #expect(stacked === editor)
        #expect(model.text == "draft")
        #expect(host.fittingSize.height > rowHeight + 20)
    }
    @Test func inputKeepsTheEditorThroughValidationThemeAndClassChanges() throws {
        let model = CatalogControlModel()
        let (host, window) = host(CatalogInputProbe(model: model))
        defer { window.contentView = nil }
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        editor.stringValue = "edited"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        settle(host)
        #expect(model.text == "edited")
        model.invalid = true; model.large = true
        settle(host)
        let updated = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        #expect(updated === editor)
        #expect(updated.stringValue == "edited")
    }
    @Test func otpNormalizesTheActualNativePasteBinding() throws {
        let model = CatalogControlModel()
        model.text = ""
        let (host, window) = host(CNInputOTP(code: Binding(get: { model.text }, set: { model.text = $0 })))
        defer { window.contentView = nil }
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        editor.stringValue = "12 34-56789"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        settle(host)
        #expect(model.text == "123456")
        #expect(editor.stringValue == "123456")
    }
    @Test func replacingAToastCancelsThePreviousDeadline() async throws {
        let model = CatalogControlModel()
        model.toast = CNToast(title: "First", duration: 0.3)
        let (host, window) = host(CNToastHost(toast: Binding(get: { model.toast }, set: { model.toast = $0 })) { Text("Editor") })
        defer { window.contentView = nil }
        try await Task.sleep(for: .milliseconds(50))
        let replacement = CNToast(title: "Second", duration: nil)
        model.toast = replacement; settle(host)
        try await Task.sleep(for: .milliseconds(400))
        settle(host)
        #expect(model.toast?.id == replacement.id)
    }
    private func host<V: View>(_ view: V) -> (NSHostingView<AnyView>, NSWindow) {
        let host = NSHostingView(rootView: AnyView(view.frame(width: 400)))
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        settle(host)
        return (host, window)
    }
    private func settle(_ view: NSView) { view.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.08)) }
    private func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
}
@MainActor @Observable private final class SidebarControlModel {
    var visibility: NavigationSplitViewVisibility = .all
    var mobile = false
    var text = "initial draft"
    @ObservationIgnored var context = CNSidebarContext()
    @ObservationIgnored var identities: [UUID] = []
    @ObservationIgnored var animations: [Animation?] = []
    @ObservationIgnored var reduceMotion = false
}
private struct SidebarControlHarness: View {
    let model: SidebarControlModel
    let collapsible: CNSidebarCollapsible
    var body: some View {
        CNSidebar(visibility: Binding(get: { model.visibility }, set: { model.visibility = $0 }),
                  mobilePresented: Binding(get: { model.mobile }, set: { model.mobile = $0 }), collapsible: collapsible) {
            CNSidebarHeader { Text("Workspace") }
            CNSidebarContent { CNSidebarMenuButton("Overview", systemImage: "tray", action: {}) }
        } detail: { SidebarDetailControlProbe(model: model) }
    }
}
private struct SidebarDetailControlProbe: View {
    let model: SidebarControlModel
    @Environment(\.cnSidebarContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var identity = UUID()
    var body: some View {
        model.context = context
        model.reduceMotion = reduceMotion
        model.identities.append(identity)
        return CNInput("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
            .transaction { model.animations.append($0.animation) }
    }
}
@MainActor @Observable private final class CatalogControlModel {
    var text = "hello"
    var invalid = false
    var large = false
    var narrow = false
    var tab = 0
    var on = false
    var toast: CNToast? = nil
}
private struct CatalogActionProbe: View {
    let model: CatalogControlModel
    var body: some View {
        CNAdaptiveActionLayout {
            CNInput("Name", text: Binding(get: { model.text }, set: { model.text = $0 }), classes: "w-[120]")
            CNButton("Save workspace", action: {})
        }.frame(width: model.narrow ? 140 : 360)
    }
}
private struct CatalogInputProbe: View {
    let model: CatalogControlModel
    var body: some View {
        CNField(isInvalid: model.invalid) {
            CNInput("Name", text: Binding(get: { model.text }, set: { model.text = $0 }), classes: model.large ? "rounded-xl p-4" : "")
        }.twTheme(TWTheme(spacingUnit: model.large ? 5 : 4))
    }
}
#endif
