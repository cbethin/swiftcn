#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Component composition", .serialized)
@MainActor
struct ComponentRenderingTests {
    @Test func nativeEditorBindingAndIdentitySurviveValidationChanges() throws {
        let model = ComponentModel()
        let (host, window) = host(ComponentEditor(model: model), width: 320)
        defer { window.contentView = nil }
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        #expect(editor.stringValue == "hello")
        editor.stringValue = "edited"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        settle(host)
        #expect(model.text == "edited")
        model.invalid = true
        settle(host)
        let updated = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        #expect(updated === editor)
        #expect(updated.stringValue == "edited")
        #expect(Set(model.identities).count == 1)
    }

    @Test func toggleDelegatesTheOriginalBindingAndDisabledEnvironment() throws {
        let model = ComponentModel()
        let probe = ToggleBaseProbe()
        let (host, window) = host(Toggle("Updates", isOn: Binding(get: { model.on }, set: { model.on = $0 }))
            .toggleStyle(.tw("toggle", base: ProbeToggleStyle(probe: probe))).disabled(true), width: 320)
        defer { window.contentView = nil }
        let binding = try #require(probe.binding)
        #expect(!binding.wrappedValue)
        #expect(probe.enabled == false)
        binding.wrappedValue = true
        settle(host)
        #expect(model.on)
        #expect(probe.binding?.wrappedValue == true)
    }

    @Test func labelAdapterKeepsTheChosenNativeBase() throws {
        let native = try image(Label("Workspace", systemImage: "folder").labelStyle(.titleOnly))
        let styled = try image(Label("Workspace", systemImage: "folder").labelStyle(.tw("", base: .titleOnly)))
        #expect(native.size == styled.size)
        #expect(native.tiffRepresentation == styled.tiffRepresentation)
    }

    @Test func addedClassesKeepPartDefaultsAndLocalValuesWin() throws {
        let image = try image(CNCardContent("p-2") { Color.red.frame(width: 10, height: 10) })
        #expect(image.size.height == 26)
        let probe = ComponentFontProbe()
        let (host, window) = host(CNCardTitle("bg-accent") { ComponentFontReader(probe: probe) }
            .twRules { $0.named["card-title"] = .font(.headline) }, width: 320)
        defer { window.contentView = nil }
        settle(host)
        #expect(probe.font == .headline)
    }

    @Test func validationIsScopedToEachField() {
        let probe = ValidationProbe()
        let (host, window) = host(CNFieldGroup {
            CNField(isInvalid: true) { ValidationReader(id: "invalid", probe: probe) }
            CNField { ValidationReader(id: "valid", probe: probe) }
        }, width: 320)
        defer { window.contentView = nil }
        settle(host)
        #expect(probe.values["invalid"] == true)
        #expect(probe.values["valid"] == false)
    }

    @Test(arguments: [ColorScheme.light, .dark], [320, 720])
    func visualComposition(scheme: ColorScheme, width: Int) throws {
        var heights: [CGFloat] = []
        for largeText in [false, true] {
            let (host, window) = host(ComponentVisualFixture()
                .environment(\.colorScheme, scheme)
                .environment(\.dynamicTypeSize, largeText ? .accessibility3 : .large), width: CGFloat(width))
            defer { window.contentView = nil }
            host.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
            settle(host)
            #expect(host.bounds.width == CGFloat(width))
            heights.append(host.bounds.height)
            let image = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: image)
            let data = try #require(image.representation(using: .png, properties: [:]))
            let directory = URL(fileURLWithPath: "artifacts/components", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let name = "components-\(scheme == .dark ? "dark" : "light")-\(width)-\(largeText ? "large" : "standard").png"
            try data.write(to: directory.appendingPathComponent(name))
        }
        // macOS may keep native font metrics unchanged under Dynamic Type environments.
        #expect(heights.allSatisfy { $0 > 0 && $0.isFinite })
    }

    private func host<V: View>(_ view: V, width: CGFloat) -> (NSHostingView<some View>, NSWindow) {
        let host = NSHostingView(rootView: view.frame(width: width))
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        settle(host)
        return (host, window)
    }

    private func settle(_ host: NSView) {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.06))
        if let hosting = host as? any NSHostingSizing { hosting.resizeToContent() }
    }

    private func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
    private func image<V: View>(_ view: V) throws -> NSImage {
        try #require(ImageRenderer(content: view).nsImage)
    }
}

@MainActor private protocol NSHostingSizing { func resizeToContent() }
extension NSHostingView: NSHostingSizing {
    fileprivate func resizeToContent() { setFrameSize(fittingSize); layoutSubtreeIfNeeded() }
}

@MainActor @Observable private final class ComponentModel {
    var text = "hello"
    var invalid = false
    var on = false
    var identities: [UUID] = []
}

private struct ComponentEditor: View {
    let model: ComponentModel
    var body: some View {
        CNCard {
            CNCardContent {
                CNField(isInvalid: model.invalid) {
                    CNFieldLabel("Email")
                    TextField("Email", text: Binding(get: { model.text }, set: { model.text = $0 }))
                        .textFieldStyle(.tw())
                    ComponentIdentity(model: model)
                    if model.invalid { CNFieldError("Check this value.") }
                }
            }
        }
    }
}

private struct ComponentIdentity: View {
    let model: ComponentModel
    @State private var identity = UUID()
    var body: some View { Color.clear.frame(height: 1).onAppear { model.identities.append(identity) } }
}

@MainActor private final class ToggleBaseProbe {
    var binding: Binding<Bool>?
    var enabled: Bool?
}
private struct ProbeToggleStyle: ToggleStyle {
    let probe: ToggleBaseProbe
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        probe.binding = configuration.$isOn
        probe.enabled = enabled
        return Toggle(configuration).toggleStyle(.checkbox)
    }
}
@MainActor private final class ComponentFontProbe { var font: Font? }
private struct ComponentFontReader: View {
    let probe: ComponentFontProbe
    @Environment(\.font) private var font
    var body: some View { Text("Title").onAppear { probe.font = font } }
}
@MainActor private final class ValidationProbe { var values: [String: Bool] = [:] }
private struct ValidationReader: View {
    let id: String
    let probe: ValidationProbe
    @Environment(\.twFieldInvalid) private var invalid
    var body: some View { Text(id).onAppear { probe.values[id] = invalid } }
}

private struct ComponentVisualFixture: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        CNCard {
            CNCardHeader {
                CNCardTitle { Label("Your workspace", systemImage: "folder").labelStyle(.tw("", base: .titleAndIcon)) }
                CNCardDescription("Native editing, validation, and reusable parts.")
            }
            CNCardContent {
                CNFieldGroup {
                    CNField {
                        CNFieldLabel("Name").accessibilityHidden(true)
                        TextField("Name", text: .constant("Charles")).textFieldStyle(.tw())
                        CNFieldDescription("Shown on your profile.")
                    }
                    CNField(isInvalid: true) {
                        CNFieldLabel("Email").accessibilityHidden(true)
                        TextField("Email", text: .constant("charles")).textFieldStyle(.tw(state: .init(isFocused: true)))
                        CNFieldError("Enter a complete email address.")
                    }
                    CNField {
                        CNFieldLabel("Password").accessibilityHidden(true)
                        SecureField("Password", text: .constant("secret")).textFieldStyle(.tw()).disabled(true)
                    }
                    Toggle("Product updates", isOn: .constant(true)).toggleStyle(.tw(base: .switch))
                    Toggle("Disabled", isOn: .constant(false)).toggleStyle(.tw()).disabled(true)
                }
            }
            CNCardFooter {
                Button("Save") {}.buttonStyle(.tw("button-primary"))
                Button("Cancel") {}.buttonStyle(.tw("button-outline"))
            }
        }
        .padding(16)
        .background(TWTheme.standard.color(.background, scheme: scheme))
    }
}
#endif
