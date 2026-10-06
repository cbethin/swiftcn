#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Catalog native controls", .serialized)
@MainActor
struct CatalogNativeRenderingTests {
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
@MainActor @Observable private final class CatalogControlModel {
    var text = "hello"
    var invalid = false
    var large = false
    var on = false
    var answers: [String: CNAnswer] = [:]
    var index = 0
    var submissions = 0
    var toast: CNToast? = nil
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
