#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Catalog native controls", .serialized)
@MainActor
struct CatalogNativeRenderingTests {
    @Test(arguments: [0, 1, 2])
    func resizableReflowPreservesItsNativeEditor(configuration: Int) throws {
        let model = ResizeControlModel()
        let controller = NSHostingController(rootView: ResizeControlHarness(model: model,
            vertical: configuration == 2, rtl: configuration == 1))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 600, height: 240)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentViewController = controller
        defer { window.contentViewController = nil }
        settle(host)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        editor.stringValue = "resize draft"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        for split in [0.36, 0.70, 0.15, 0.85, 0.35] {
            model.fraction = split; settle(host)
            #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        }
        window.setContentSize(NSSize(width: 480, height: 200)); settle(host)
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        #expect(model.text == "resize draft")
    }
    @Test func skeletonPreservesTheEditorAndDraftWhenLoadingChanges() throws {
        let model = LoadingControlModel()
        let (host, window) = host(SkeletonControlHarness(model: model))
        defer { window.contentView = nil }
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        #expect(!editor.isEnabled)
        model.loading = false; settle(host)
        #expect(editor.isEnabled)
        editor.stringValue = "unfinished loading draft"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        model.loading = true; settle(host)
        model.loading = false; settle(host)
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        #expect(model.text == "unfinished loading draft")
        #expect(Set(model.identities).count == 1)
    }
    @Test func fixedLoadingPhasesMoveTheRingWithoutMovingInactiveViews() throws {
        let model = LoadingControlModel()
        let (host, window) = host(SpinnerControlHarness(model: model))
        defer { window.contentView = nil }
        let first = try pixels(host)
        model.phase = 0.65; settle(host)
        #expect(try pixels(host) != first)
        model.paused = true; settle(host)
        let paused = try pixels(host)
        model.phase = 0.15; settle(host)
        #expect(try pixels(host) == paused, "An inactive cn-spin slot must stay neutral, including in frozen previews.")
        #expect(descendants(host).allSatisfy { !($0 is NSProgressIndicator) })
    }
    @Test func tableSelectionAndHorizontalReflowPreserveEditableCells() throws {
        let model = LoadingControlModel()
        let controller = NSHostingController(rootView: TableControlHarness(model: model))
        let host = controller.view
        host.frame = CGRect(x: 0, y: 0, width: 600, height: 180)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentViewController = controller
        defer { window.contentViewController = nil }
        settle(host)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        editor.stringValue = "draft invoice"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        model.selected = true; window.setContentSize(NSSize(width: 180, height: 180)); settle(host)
        #expect(abs(host.bounds.width - 180) < 1, "Resize the owning window so AppKit does not restore the old host width.")
        let scroll = try #require(descendants(host).compactMap { $0 as? NSScrollView }.first)
        #expect(try #require(scroll.documentView).frame.width > scroll.contentSize.width)
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        #expect(model.text == "draft invoice")
    }
    private func pixels(_ host: NSView) throws -> Data {
        host.layoutSubtreeIfNeeded()
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        return try #require(bitmap.representation(using: .png, properties: [:]))
    }
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
    @Test func appendingAToastPreservesExistingDeadlinesAndTheEditor() async throws {
        let model = CatalogControlModel()
        let first = CNToast(title: "First", duration: 0.9)
        let persistent = CNToast(title: "Persistent", duration: nil)
        model.toasts = [first]
        let (host, window) = host(CNToastHost(toasts: Binding(get: { model.toasts }, set: { model.toasts = $0 })) {
            CNInput("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
                .frame(height: 180, alignment: .top)
        })
        defer { window.contentView = nil }
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        #expect(window.makeFirstResponder(editor))
        let responder = window.firstResponder
        try await Task.sleep(for: .milliseconds(400))
        #expect(model.toasts.map(\.id) == [first.id])
        model.toasts.append(persistent); settle(host)
        try await Task.sleep(for: .milliseconds(550)); settle(host)
        #expect(model.toasts.map(\.id) == [persistent.id], "Appending must not restart another toast's lifetime.")
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        #expect(window.firstResponder === responder, "Notifications must not take focus from the editor.")
        let replacement = CNToast(id: persistent.id, title: "Updated", duration: 0.2)
        model.toasts = [replacement]; settle(host)
        try await Task.sleep(for: .milliseconds(300)); settle(host)
        #expect(model.toasts.isEmpty, "Updating one toast must replace its own deadline.")
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
    }
    @Test func expandingTheToastDeckPausesDeadlinesUntilReadingEnds() async throws {
        let model = CatalogControlModel()
        model.toasts = [CNToast(title: "First", duration: 0.2), CNToast(title: "Second", duration: 0.2)]
        model.toastsExpanded = true
        let (host, window) = host(CNToastHost(toasts: Binding(get: { model.toasts }, set: { model.toasts = $0 }),
                                           isExpanded: Binding(get: { model.toastsExpanded }, set: { model.toastsExpanded = $0 })) {
            Text("Editor").frame(height: 180)
        })
        defer { window.contentView = nil }
        try await Task.sleep(for: .milliseconds(400)); settle(host)
        #expect(model.toasts.count == 2)
        model.toastsExpanded = false; settle(host)
        try await Task.sleep(for: .milliseconds(350)); settle(host)
        #expect(model.toasts.isEmpty)
    }
    @Test(arguments: [false, true], [false, true])
    func toastStackBoundsItsViewportAndReflowsOnResize(dark: Bool, large: Bool) async throws {
        let model = CatalogControlModel()
        model.toasts = (0..<8).map { CNToast(title: "Notification \($0)", message: "A longer message that wraps on small screens.", duration: nil) }
        let controller = NSHostingController(rootView: CNToastHost(toasts: Binding(get: { model.toasts }, set: { model.toasts = $0 }),
                                                                 isExpanded: Binding(get: { model.toastsExpanded }, set: { model.toastsExpanded = $0 })) {
            CNInput("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .environment(\.colorScheme, dark ? .dark : .light)
        .environment(\.dynamicTypeSize, large ? .accessibility3 : .large)
        .background(TWTheme.standard.color(.background, scheme: dark ? .dark : .light))
        .transaction { $0.disablesAnimations = true })
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 240, height: 180),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        controller.view.frame = window.contentLayoutRect
        window.contentViewController = controller
        defer { window.contentViewController = nil }
        let host = controller.view
        settle(host)
        let scroll = try #require(descendants(host).compactMap { $0 as? NSScrollView }.first)
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        let viewport = scroll.convert(scroll.bounds, to: host)
        #expect(viewport.minX >= -1 && viewport.maxX <= 241)
        #expect(viewport.minY >= -1 && viewport.maxY <= 181)
        let document = try #require(scroll.documentView)
        let deckHeight = document.bounds.height
        try captureToastStack(host, name: "toast-deck-\(dark ? "dark" : "light")-\(large ? "large" : "standard")")
        model.toastsExpanded = true; settle(host)
        #expect(document.bounds.height > scroll.contentSize.height)
        #expect(document.bounds.height > deckHeight * 2, "The collapsed deck must overlap cards instead of arranging a vertical stack.")
        scroll.contentView.scroll(to: CGPoint(x: 0, y: document.bounds.maxY - scroll.contentSize.height))
        scroll.reflectScrolledClipView(scroll.contentView)
        #expect(abs(scroll.documentVisibleRect.maxY - document.bounds.maxY) < 2)
        try captureToastStack(host, name: "toast-stack-compact-\(dark ? "dark" : "light")-\(large ? "large" : "standard")")
        model.toasts.remove(at: 3); settle(host)
        window.setContentSize(NSSize(width: 480, height: 720)); settle(host)
        #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
        #expect(scroll.bounds.width <= 361)
        #expect(model.toasts.count == 7)
        try captureToastStack(host, name: "toast-stack-expanded-\(dark ? "dark" : "light")-\(large ? "large" : "standard")")
    }
    private func captureToastStack(_ host: NSView, name: String) throws {
        guard let path = ProcessInfo.processInfo.environment["SWIFTCN_COMPOSITION_ARTIFACTS"] else { return }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try pixels(host).write(to: directory.appendingPathComponent(name + ".png"))
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
@MainActor @Observable private final class ResizeControlModel {
    var fraction = 0.35
    var text = "initial draft"
}
private struct ResizeControlHarness: View {
    let model: ResizeControlModel
    let vertical: Bool
    let rtl: Bool
    var body: some View {
        CNResizable(fraction: Binding(get: { model.fraction }, set: { model.fraction = $0 }),
                    axis: vertical ? .vertical : .horizontal) {
            CNInput("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
        } second: { Text("Editor").frame(maxWidth: .infinity, maxHeight: .infinity) }
        .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
    }
}
@MainActor @Observable private final class LoadingControlModel {
    var loading = true
    var text = "initial draft"
    var phase = 0.15
    var paused = false
    var selected = false
    @ObservationIgnored var identities: [UUID] = []
}
private struct SkeletonControlHarness: View {
    let model: LoadingControlModel
    var body: some View {
        CNSkeleton(isLoading: model.loading) { LoadingEditorProbe(model: model) }.cnLoadingPhase(model.phase)
    }
}
private struct LoadingEditorProbe: View {
    let model: LoadingControlModel
    @State private var identity = UUID()
    var body: some View {
        model.identities.append(identity)
        return CNInput("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
    }
}
private struct SpinnerControlHarness: View {
    let model: LoadingControlModel
    var body: some View {
        HStack {
            CNSpinner(classes: model.paused ? "cn-spin-[0] w-8 h-8" : "w-8 h-8")
            Text("This stays still").tw("text-sm")
        }.cnLoadingPhase(model.phase)
    }
}
private struct TableControlHarness: View {
    let model: LoadingControlModel
    var body: some View {
        CNTable {
            CNTableRow { CNTableHead("Draft"); CNTableHead("Amount") }
            CNTableRow(isSelected: model.selected) {
                CNTableCell("w-[180]") { CNInput("Draft", text: Binding(get: { model.text }, set: { model.text = $0 })) }
                CNTableCell("$250.00", classes: "w-[160]", alignment: .trailing)
            }
        }
    }
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
    var toasts: [CNToast] = []
    var toastsExpanded = false
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
