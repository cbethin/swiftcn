import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Adaptive surfaces")
struct AdaptiveSurfacePolicyTests {
    @Test(arguments: [TWAppearance.automatic, .glass, .solid], [false, true])
    func policySelectsOneFillForEachRole(appearance: TWAppearance, compatibility: Bool) {
        for supportsGlass in [false, true] {
            for reduceTransparency in [false, true] {
                let context = TWSurfaceContext(appearance: appearance, supportsGlass: supportsGlass,
                                               requiresCompatibility: compatibility, reduceTransparency: reduceTransparency)
                let fallback: TWSurfaceFill = reduceTransparency ? .solid : .material
                // Explicit classes override the policy.
                #expect(context.fill(for: .solid) == .solid)
                #expect(context.fill(for: .glass) == (supportsGlass ? .glass : fallback))
                let floatingGlass = supportsGlass && (appearance == .glass || appearance == .automatic && !compatibility)
                #expect(context.fill(for: .floating) == (floatingGlass ? .glass : appearance == .solid ? .solid : fallback))
            }
        }
    }

    @Test func accessibilityNeverChangesTheNativeControlStyle() {
        for appearance in [TWAppearance.automatic, .glass, .solid] {
            for role in [TWSurfaceRole.floating, .solid, .glass] {
                let standard = TWSurfaceContext(appearance: appearance, supportsGlass: true)
                let reduced = TWSurfaceContext(appearance: appearance, supportsGlass: true, reduceTransparency: true)
                #expect(standard.usesGlass(role) == reduced.usesGlass(role))
            }
        }
    }

    @Test func sheetsKeepTheSystemAppearanceOnlyWhereTheSystemDrawsGlass() {
        #expect(TWSurfaceContext(supportsGlass: true).keepsSystemPresentation)
        #expect(!TWSurfaceContext(supportsGlass: false).keepsSystemPresentation)
        #expect(!TWSurfaceContext(appearance: .solid, supportsGlass: true).keepsSystemPresentation)
        #expect(!TWSurfaceContext(supportsGlass: true, requiresCompatibility: true).keepsSystemPresentation)
        #expect(TWSurfaceContext(appearance: .glass, supportsGlass: true, requiresCompatibility: true).keepsSystemPresentation)
    }

    @Test func surfaceClassesResolveToOneRoleAndLocalClassesWin() {
        #expect(resolve("surface-floating").surface == .floating)
        #expect(resolve("surface-solid").surface == .solid)
        #expect(resolve("glass").surface == .glass)
        #expect(resolve("surface-floating glass surface-solid").surface == .solid)
        let rules = TWGlobalRules(view: .surfaceFloating)
        #expect(resolve("p-2", rules: rules).surface == .floating)
        #expect(resolve("surface-solid", rules: rules).surface == .solid)
        #expect(resolve("p-2").surface == nil)
    }

    @Test func glassVariantsResolveIndependently() throws {
        let resolved = resolve("glass-prominent glass-interactive glass-tint-destructive")
        #expect(resolved.surface == .glass)
        #expect(resolved.prominent)
        #expect(resolved.glassInteractive)
        #expect(resolved.glassTint == TWTheme.standard.color(.destructive, scheme: .light))
        let interpolated = TWStyleResolver.resolve("glass glass-tint-[\(Color.red)]", theme: .standard, scheme: .light, state: TWState())
        #expect(interpolated.glassTint == .red)
        #expect(resolve("hover:glass-interactive").glassInteractive == false)
        #expect(resolve("hover:glass-interactive", state: TWState(isHovered: true)).glassInteractive)
        #expect(throws: (any Error).self) { try TWStyle.parse("glass-tint-unknown") }
    }

    @Test func registeredModifiersNamedGlassKeepPrecedence() throws {
        var rules = TWGlobalRules()
        rules.modifiers["glass"] = .view { view, active in view.opacity(active ? 0.5 : 1) }
        let resolved = resolve("glass", rules: rules)
        #expect(resolved.surface == nil)
        #expect(resolved.nativeSlots.contains { $0.name == "glass" && $0.active })
    }

    private func resolve(_ classes: String, rules: TWGlobalRules = TWGlobalRules(), state: TWState = TWState()) -> TWResolvedStyle {
        TWStyleResolver.resolve(TWStyle(rules.view, .classes(classes)), theme: .standard, scheme: .light,
                                state: state, globalRules: rules)
    }
}

#if os(macOS)
import AppKit

@Suite("Adaptive surface rendering", .serialized)
@MainActor
struct AdaptiveSurfaceRenderingTests {
    @Test func solidSurfacesUseTheRequestedFillOnce() throws {
        let image = try render(surface("p-2 surface-solid bg-[#ff0000] rounded-none"), glass: true)
        let center = try pixel(image, x: image.width / 2, y: image.height / 2)
        #expect(center.red > 0.9 && center.green < 0.1 && center.alpha > 0.99)
    }

    @Test func fallbacksDoNotStackTheBackgroundColor() throws {
        // A material ignores bg-*: the surface resolves to one fill, not a tinted layer under a material.
        let image = try render(surface("p-2 surface-floating bg-[#ff0000] rounded-none"), glass: false)
        let center = try pixel(image, x: image.width / 2, y: image.height / 2)
        #expect(!(center.red > 0.9 && center.green < 0.1))
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func reduceTransparencyFallsBackToTheThemedSurface(scheme: ColorScheme) throws {
        let image = try render(surface("p-2 surface-floating rounded-none")
            .environment(\._accessibilityReduceTransparency, true), glass: false, scheme: scheme)
        let center = try pixel(image, x: image.width / 2, y: image.height / 2)
        let expected = try pixel(try render(Color.clear.frame(width: 40, height: 20)
            .background(TWTheme.standard.color(.surface, scheme: scheme)), glass: false, scheme: scheme), x: 20, y: 10)
        #expect(abs(center.red - expected.red) < 0.02 && abs(center.blue - expected.blue) < 0.02 && center.alpha > 0.99)
    }

    @Test func increaseContrastStrengthensTheFallbackEdge() throws {
        let view = surface("p-2 surface-floating rounded-none").environment(\._accessibilityReduceTransparency, true)
        let standard = try render(view, glass: false)
        let increased = try render(view.environment(\._colorSchemeContrast, .increased), glass: false)
        let edge = try pixel(standard, x: 0, y: standard.height / 2)
        let strong = try pixel(increased, x: 0, y: increased.height / 2)
        #expect(strong.red < edge.red - 0.05, "The increased-contrast edge must be darker than the standard edge.")
    }

    @Test func explicitBordersReplaceTheFallbackEdge() throws {
        let image = try render(surface("p-2 surface-floating border-2 border-[#0000ff] rounded-none")
            .environment(\._accessibilityReduceTransparency, true), glass: false)
        let edge = try pixel(image, x: 1, y: image.height / 2)
        #expect(edge.blue > 0.9 && edge.red < 0.1)
    }

    @Test func accessibilityAndPolicyChangesPreserveEditorsAndFocus() throws {
        let model = SurfaceModel()
        let (host, window) = host(SurfaceEditorProbe(model: model))
        defer { window.contentView = nil }
        let editor = try #require(descendants(host).compactMap { $0 as? NSTextField }.first)
        editor.stringValue = "draft in a floating surface"
        editor.delegate?.controlTextDidChange?(Notification(name: NSControl.textDidChangeNotification, object: editor))
        #expect(window.makeFirstResponder(editor))
        let responder = window.firstResponder
        let changes: [(Bool, TWAppearance, ColorSchemeContrast, Bool?)] = [
            (true, .automatic, .standard, nil), (true, .solid, .increased, nil), (false, .glass, .increased, false),
            (false, .automatic, .standard, true), (true, .automatic, .increased, false), (false, .automatic, .standard, nil),
        ]
        for (reduce, appearance, contrast, glass) in changes {
            model.reduceTransparency = reduce; model.appearance = appearance
            model.contrast = contrast; model.glass = glass
            settle(host)
            #expect(descendants(host).compactMap { $0 as? NSTextField }.first === editor)
            #expect(window.firstResponder === responder)
            #expect(model.text == "draft in a floating surface")
            #expect(Set(model.identities).count == 1)
        }
    }

    @Test(arguments: [nil, false] as [Bool?])
    func nativeButtonsKeepActivationAcrossRepeatedTaps(glass: Bool?) throws {
        let model = SurfaceModel()
        let (host, window) = host(NativeButtonProbe(model: model).environment(\.twGlassSupport, glass))
        defer { window.contentView = nil; window.orderOut(nil) }
        window.makeKeyAndOrderFront(nil)
        settle(host)
        for count in 1...12 {
            try click(window, host: host)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
            if count.isMultiple(of: 4) { model.reduceTransparency.toggle(); settle(host) }
        }
        settle(host)
        #expect(model.taps == 12)
        #expect(Set(model.identities).count == 1, "Accessibility changes must keep the native button's label.")
    }

    @Test func nativeButtonLabelsReceiveLayoutWithoutAnotherBackground() throws {
        // A red background class must not paint over the native control.
        let plain = try render(Button("Save") {}.buttonStyle(.twNative("glass")), glass: false)
        let styled = try render(Button("Save") {}.buttonStyle(.twNative("glass bg-[#ff0000] px-6")), glass: false)
        #expect(styled.width > plain.width)
        for x in stride(from: 0, to: styled.width, by: 2) {
            let sample = try pixel(styled, x: x, y: styled.height / 2)
            #expect(!(sample.red > 0.9 && sample.green < 0.1 && sample.blue < 0.1))
        }
    }

    @Test func interruptedGroupTransitionsSettleOnTheFinalState() throws {
        let model = SurfaceModel()
        let (host, window) = host(SurfaceGroupProbe(model: model))
        defer { window.contentView = nil }
        let collapsed = host.fittingSize.width
        for expanded in [true, false, true, false, true] {
            withAnimation(.smooth(duration: 0.4)) { model.expanded = expanded }
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.03))
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.6))
        settle(host)
        #expect(model.expanded)
        #expect(host.fittingSize.width > collapsed + 40)
        #expect(Set(model.identities).count == 1, "The persistent control must keep its identity while the group morphs.")
        withAnimation(.smooth(duration: 0.4)) { model.expanded = false }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.6))
        settle(host)
        #expect(abs(host.fittingSize.width - collapsed) < 1)
    }

    @Test(arguments: [nil, false] as [Bool?], [TWAppearance.automatic, .solid])
    func sheetBackgroundsDependOnlyOnSystemAndPolicy(glass: Bool?, appearance: TWAppearance) throws {
        let probe = PresentationProbe()
        _ = try render(PresentationReader(probe: probe).frame(width: 10, height: 10).twPresentationSurface()
            .environment(\.twAppearance, appearance), glass: glass)
        let systemGlass = glass ?? TWSurfaceContext.systemSupportsGlass
        #expect(probe.system == (systemGlass && appearance == .automatic && !TWSurfaceContext.systemRequiresCompatibility))
    }

    private func surface(_ classes: String) -> some View {
        Color.clear.frame(width: 40, height: 20).tw(classes)
    }

    private func render<V: View>(_ view: V, glass: Bool?, scheme: ColorScheme = .light) throws -> CGImage {
        let renderer = ImageRenderer(content: view.environment(\.twGlassSupport, glass).environment(\.colorScheme, scheme))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }

    private func pixel(_ image: CGImage, x: Int, y: Int) throws -> SurfacePixel {
        let context = try #require(CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        let index = (y * image.width + x) * 4
        let alpha = Double(bytes[index + 3]) / 255
        let divisor = max(alpha * 255, 1)
        return SurfacePixel(red: Double(bytes[index]) / divisor, green: Double(bytes[index + 1]) / divisor,
                            blue: Double(bytes[index + 2]) / divisor, alpha: alpha)
    }

    private func host<V: View>(_ view: V) -> (NSHostingView<AnyView>, NSWindow) {
        let host = NSHostingView(rootView: AnyView(view))
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        settle(host)
        return (host, window)
    }
    private func settle(_ view: NSView) { view.layoutSubtreeIfNeeded(); RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.08)) }
    private func click(_ window: NSWindow, host: NSView) throws {
        let center = CGPoint(x: host.bounds.midX, y: host.bounds.midY)
        var hit = host.hitTest(host.convert(center, to: host.superview))
        while let view = hit {
            if let button = view as? NSButton { button.performClick(nil); return }
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
    private func descendants(_ root: NSView) -> [NSView] { root.subviews.flatMap { [$0] + descendants($0) } }
}

private struct SurfacePixel { var red: Double; var green: Double; var blue: Double; var alpha: Double }

@MainActor @Observable private final class SurfaceModel {
    var text = ""
    var reduceTransparency = false
    var appearance = TWAppearance.automatic
    var contrast = ColorSchemeContrast.standard
    var glass: Bool?
    var expanded = false
    var taps = 0
    var identities: [UUID] = []
}

private struct SurfaceEditorProbe: View {
    let model: SurfaceModel
    var body: some View {
        VStack {
            TextField("Draft", text: Binding(get: { model.text }, set: { model.text = $0 }))
            IdentityProbe(model: model)
        }
        .frame(width: 240)
        .tw("p-4 surface-floating glass-interactive")
        .environment(\._accessibilityReduceTransparency, model.reduceTransparency)
        .environment(\._colorSchemeContrast, model.contrast)
        .environment(\.twGlassSupport, model.glass)
        .twAppearance(model.appearance)
    }
}

private struct IdentityProbe: View {
    let model: SurfaceModel
    @State private var identity = UUID()
    var body: some View {
        Color.clear.frame(width: 1, height: 1).onAppear { model.identities.append(identity) }
    }
}

private struct NativeButtonProbe: View {
    let model: SurfaceModel
    var body: some View {
        Button { model.taps += 1 } label: {
            HStack { Text("Tap"); IdentityProbe(model: model) }
        }
            .buttonStyle(.twNative("glass px-4 text-sm"))
            .environment(\._accessibilityReduceTransparency, model.reduceTransparency)
            .padding(8)
    }
}

private struct SurfaceGroupProbe: View {
    let model: SurfaceModel
    @Namespace private var namespace
    var body: some View {
        TWSurfaceGroup(spacing: 8) {
            HStack(spacing: 8) {
                IdentityProbe(model: model).frame(width: 44, height: 44)
                    .tw("surface-floating").twSurfaceID("primary", in: namespace)
                if model.expanded {
                    Color.clear.frame(width: 44, height: 44)
                        .tw("surface-floating").twSurfaceID("secondary", in: namespace)
                }
            }
        }
        .padding(8)
        .fixedSize()
    }
}

@MainActor private final class PresentationProbe { var system = false }
private struct PresentationReader: View {
    let probe: PresentationProbe
    @Environment(\.twSystemPresentation) private var system
    var body: some View {
        probe.system = system
        return Color.clear
    }
}
#endif
