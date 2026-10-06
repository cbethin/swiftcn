#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Native composition pipeline", .serialized)
@MainActor
struct CompositionRenderingTests {
    @Test func modifierPhasesMatchNativeOrder() throws {
        let rules = TWGlobalRules(modifiers: [
            "inside": .view(phase: .content) { view, active in view.padding(active ? 7 : 0) },
            "outside": .view(phase: .decoration) { view, active in view.padding(active ? 7 : 0) }
        ])
        let text = Text("Order")
        try equal(text.tw("inside p-[5] bg-[#00f]").twRules(rules),
                  text.padding(7).padding(5).background(Color(red: 0, green: 0, blue: 1)), name: "content-phase")
        try equal(text.tw("outside p-[5] bg-[#00f]").twRules(rules),
                  text.padding(5).background(Color(red: 0, green: 0, blue: 1)).padding(7), name: "decoration-phase")
        // A second surface retains ordinary SwiftUI order.
        try equal(text.tw("p-[5]").tw("bg-[#00f]"), text.padding(5).background(Color(red: 0, green: 0, blue: 1)), name: "composed-surfaces")
    }

    @Test func targetFactoriesMatchNativeTextImageAndShape() throws {
        let rules = TWGlobalRules(modifiers: [
            "kern": .textValue(default: CGFloat.zero) { text, amount in text.kerning(amount) },
            "resize": .image { image, active in active ? image.resizable() : image },
            "trim": .shapeValue(default: CGFloat(1)) { shape, end in AnyShape(shape.trim(from: 0, to: end)) }
        ])
        let amount = CGFloat(2)
        try equal(Text("Native text").tw("kern-[\(amount)] p-[5]").twRules(rules),
                  Text("Native text").kerning(2).padding(5), name: "native-text")
        try equal(Image(systemName: "star.fill").tw("resize w-[60] h-[40]").twRules(rules),
                  Image(systemName: "star.fill").resizable().frame(width: 60, height: 40), name: "native-image")
        try equal(Circle().tw("trim-[0.6] w-[60] h-[60]").twRules(rules),
                  Circle().trim(from: 0, to: 0.6).frame(width: 60, height: 60), name: "native-shape")
        // An inherited registration must leave unrelated native sources alone.
        try equal(Text("Untouched").tw("p-0").twRules(rules), Text("Untouched"), name: "inactive-targets")
    }

    @Test func unsupportedTargetRejectsWholeSurface() {
        let rules = TWGlobalRules(modifiers: ["resize": .image { image, active in active ? image.resizable() : image }])
        let result = TWStyleResolver.resolve("resize p-8", theme: .standard, scheme: .light,
            state: .init(), globalRules: rules, target: .text)
        #expect(result.padding.top == 0)
        #expect(result.nativeSlots.allSatisfy { !$0.active })
    }

    @Test(arguments: ["kern-a", "kern-z"])
    func inactiveTextConflictsLeaveTheWinnerUnchanged(winner: String) throws {
        let rules = TWGlobalRules(modifiers: [
            "kern-a": .textValue(default: CGFloat.zero, conflictKey: "kerning") { $0.kerning($1) },
            "kern-z": .textValue(default: CGFloat.zero, conflictKey: "kerning") { $0.kerning($1) }
        ])
        // Both order positions must win, including a variant replacing a base class.
        try equal(Text("ABCDEFG").tw("\(winner)-[8]").twRules(rules),
                  Text("ABCDEFG").kerning(8), name: "text-conflict-\(winner)")
        try equal(Text("ABCDEFG").tw("kern-a-[2] hover:kern-z-[8]", state: .init(isHovered: true)).twRules(rules),
                  Text("ABCDEFG").kerning(8), name: "text-conflict-hover")
    }

    @Test func inactiveSourcesDoNotInstallAttributes() throws {
        let rules = TWGlobalRules(modifiers: [
            "italic": .text { text, active in active ? text.italic() : text.fontWeight(.regular) },
            "render": .imageValue(default: Image.TemplateRenderingMode.original) { $0.renderingMode($1) }
        ])
        try equal(Text("ABCDEFG").tw("font-bold").twRules(rules),
                  Text("ABCDEFG").tw("font-bold"), name: "inactive-text-attributes")
        try equal(Image(systemName: "star.fill").tw("text-[#f00]").twRules(rules),
                  Image(systemName: "star.fill").tw("text-[#f00]"), name: "inactive-image-attributes")
    }

    @Test(arguments: TWAnimationScope.allCases)
    func animationScopeAffectsOnlySelectedStages(scope: TWAnimationScope) {
        let model = ScopeModel()
        let recorder = ScopeRecorder()
        let rules = TWGlobalRules(modifiers: [
            "content-probe": .value(default: Int.zero, phase: .content) { view, amount in view.modifier(ScopeProbe(amount: Double(amount) * 20, phase: .content, recorder: recorder)) },
            "layout-probe": .value(default: Int.zero, phase: .layout) { view, amount in view.modifier(ScopeProbe(amount: Double(amount) * 20, phase: .layout, recorder: recorder)) },
            "decoration-probe": .value(default: Int.zero, phase: .decoration) { view, amount in view.modifier(ScopeProbe(amount: Double(amount) * 20, phase: .decoration, recorder: recorder)) },
            "effects-probe": .value(default: Int.zero, phase: .effects) { view, amount in view.modifier(ScopeProbe(amount: Double(amount) * 20, phase: .effects, recorder: recorder)) }
        ])
        let host = NSHostingView(rootView: ScopeHarness(model: model, recorder: recorder, scope: scope).twRules(rules).contentTransition(.opacity))
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        recorder.clear()
        model.active = true
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.8))
        for phase in TWModifierPhase.allCases {
            let expected = scope == .all || scope == .surface || (scope == .layout && phase == .layout) || (scope == .content && phase == .content)
            let samples = recorder.stages[phase] ?? []
            #expect(!samples.isEmpty)
            #expect(samples.contains { $0 > 0 && $0 < 20 } == (expected && !recorder.reduceMotion), "Scope \(scope), stage \(phase): \(samples)")
        }
        #expect(recorder.content.contains { $0 != nil } == (!recorder.reduceMotion))
        #expect(Set(recorder.identities).count == 1)
        #expect(recorder.contentTransitions.last == ((scope == .surface || scope == .layout) ? .identity : .opacity))
        // An unrelated state update must not enable explicitly watched scoped motion.
        if scope != .all {
            recorder.clear()
            model.unrelated = true
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
            #expect(recorder.stages.values.flatMap { $0 }.allSatisfy { abs($0 - 20) < 0.001 }, "Unrelated update: \(recorder.stages)")
            #expect(recorder.content.allSatisfy { $0 == nil })
        }
    }

    @Test(arguments: TWAnimationScope.allCases)
    func scopesWithoutPresetPreserveNativeCaller(scope: TWAnimationScope) {
        let model = ScopeModel()
        let recorder = ScopeRecorder()
        let host = NSHostingView(rootView: ScopeCallerHarness(model: model, recorder: recorder, scope: scope)
            .contentTransition(.opacity))
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        recorder.clear()
        let native = Animation.linear(duration: 0.2)
        withAnimation(native) { model.active = true }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        #expect(recorder.content.contains(native))
        #expect(recorder.content.allSatisfy { $0 == nil || $0 == native })
        #expect(recorder.contentTransitions.last == .opacity)
        #expect(Set(recorder.identities).count == 1)
    }

    private func equal<A: View, B: View>(_ actual: A, _ expected: B, name: String) throws {
        let a = try render(actual), b = try render(expected)
        if let path = ProcessInfo.processInfo.environment["SWIFTCN_COMPOSITION_ARTIFACTS"] {
            let directory = URL(fileURLWithPath: path, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for (label, image) in [("classes", a), ("native", b)] {
                let png = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
                try png.write(to: directory.appendingPathComponent("\(name)-\(label).png"))
            }
        }
        #expect(a.width == b.width && a.height == b.height)
        #expect(try pixels(a) == pixels(b))
    }
    private func render<V: View>(_ view: V) throws -> CGImage {
        let renderer = ImageRenderer(content: view.foregroundStyle(Color.black).environment(\.colorScheme, .light))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }
    private func pixels(_ image: CGImage) throws -> Data {
        let context = try #require(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Data(bytes: try #require(context.data), count: image.width * image.height * 4)
    }
}
@MainActor private final class ScopeModel: ObservableObject {
    @Published var active = false
    @Published var unrelated = false
}
@MainActor private final class ScopeRecorder {
    var stages: [TWModifierPhase: [Double]] = [:]
    var content: [Animation?] = []
    var identities: [UUID] = []
    var contentTransitions: [ContentTransition] = []
    var reduceMotion = false
    func clear() { stages.removeAll(); content.removeAll() }
}
private struct ScopeProbe: ViewModifier, Animatable {
    var amount: Double
    let phase: TWModifierPhase
    let recorder: ScopeRecorder
    nonisolated var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }
    func body(content: Content) -> some View {
        recorder.stages[phase, default: []].append(amount)
        return content.offset(x: amount)
    }
}
private struct ScopeHarness: View {
    @ObservedObject var model: ScopeModel
    let recorder: ScopeRecorder
    let scope: TWAnimationScope
    var body: some View {
        ScopeChild(active: model.active, unrelated: model.unrelated, recorder: recorder)
            .transaction { recorder.content.append($0.animation) }
            .tw("\(model.active ? "p-8 bg-primary" : "p-3 bg-accent") animate-smooth duration-200 content-probe-[\(model.active ? 1 : 0)] layout-probe-[\(model.active ? 1 : 0)] decoration-probe-[\(model.active ? 1 : 0)] effects-probe-[\(model.active ? 1 : 0)]",
                value: model.active, animationScope: scope)
    }
}
private struct ScopeCallerHarness: View {
    @ObservedObject var model: ScopeModel
    let recorder: ScopeRecorder
    let scope: TWAnimationScope
    var body: some View {
        ScopeChild(active: model.active, unrelated: model.unrelated, recorder: recorder)
            .transaction { recorder.content.append($0.animation) }
            .tw(model.active ? "p-8" : "p-3", value: model.active, animationScope: scope)
    }
}
private struct ScopeChild: View {
    let active: Bool
    let unrelated: Bool
    let recorder: ScopeRecorder
    @State private var identity = UUID()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.contentTransition) private var contentTransition
    var body: some View {
        recorder.identities.append(identity)
        recorder.reduceMotion = reduceMotion
        recorder.contentTransitions.append(contentTransition)
        return Text(unrelated ? "Other" : "Content").frame(width: active ? 60 : 40)
    }
}
#endif
