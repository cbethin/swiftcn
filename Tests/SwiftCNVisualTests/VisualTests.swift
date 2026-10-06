#if os(macOS)
import AppKit
import SwiftUI
import Testing
import SnapshotTesting
import SwiftCN

@Suite("Visual regression", .serialized,
       .enabled(if: ProcessInfo.processInfo.environment["SWIFTCN_VISUAL_MODE"] != nil))
@MainActor
struct VisualTests {
    @Test(arguments: [false, true], [320, 720])
    func matrix(dark: Bool, width: Int) throws {
        for largeText in [false, true] {
            for scene in VisualScene.allCases {
                let name = "\(scene.rawValue)-\(dark ? "dark" : "light")-\(width)-\(largeText ? "large-text" : "standard")"
                try snapshot(VisualFixture(scene: scene)
                    .environment(\.dynamicTypeSize, largeText ? .accessibility3 : .large),
                    dark: dark, width: width, name: name)
            }
        }
    }

    @Test(arguments: [false, true])
    func rightToLeft(dark: Bool) throws {
        try snapshot(VisualFixture(scene: .controls).environment(\.layoutDirection, .rightToLeft),
                     dark: dark, width: 320, name: "controls-\(dark ? "dark" : "light")-rtl")
    }

    private func snapshot<V: View>(_ view: V, dark: Bool, width: Int, name: String) throws {
        let environment = ProcessInfo.processInfo.environment
        let record = environment["SWIFTCN_VISUAL_MODE"] == "record"
        let directory = try #require(environment["SWIFTCN_SNAPSHOT_DIRECTORY"])
        let theme = TWTheme.standard
        let host = NSHostingView(rootView: view
            .frame(width: CGFloat(width))
            .background(theme.color(.background, scheme: dark ? .dark : .light))
            .environment(\.colorScheme, dark ? .dark : .light))
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        // Never auto-record a missing baseline in verification mode.
        let failure = withSnapshotTesting(record: record ? .all : .never) {
            verifySnapshot(of: host as NSView, as: savingVisualDiffs(.image, name: name),
                           named: name, snapshotDirectory: directory, testName: "matrix")
        }
        if record {
            #expect(FileManager.default.fileExists(atPath: "\(directory)/matrix.\(name).png"))
        } else if let failure {
            Issue.record("\(name): \(failure)")
        }
    }
}

private enum VisualScene: String, CaseIterable { case buttons, controls, utilities, globalRules }

private struct VisualFixture: View {
    let scene: VisualScene
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("swiftcn / \(scene.rawValue)").font(.headline)
            switch scene {
            case .buttons: buttons
            case .controls: controls
            case .utilities: utilities
            case .globalRules: globalRules
              }
        }
        .foregroundStyle(theme.color(.foreground, scheme: scheme))
        .padding(24)
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(["button-primary", "button-secondary", "button-outline", "button-destructive"], id: \.self) { name in
                Text(name).font(.caption)
                // State previews exercise the same resolver without synthetic gesture recognition.
                ForEach(0..<5) { index in
                    let states: [TWState] = [.init(), .init(isHovered: true), .init(isFocused: true),
                                             .init(isPressed: true), .init(isDisabled: true)]
                    let labels = ["Rest", "Hover", "Focus", "Press", "Disabled"]
                    Text(labels[index]).tw("\(name) focus:border-2 focus:border-primary animate-spring duration-150", state: states[index])
                  }
              }
            Button("Native activation") {}.buttonStyle(.tw("button-primary animate-spring duration-150"))
            Button("Native disabled") {}.buttonStyle(.tw("button-primary animate-none")).disabled(true)
            Button("Typed style") {}.buttonStyle(.tw(.primaryButton, .px(6), .animation(.snappy)))
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Native controls").tw("text-xl font-semibold")
            TextField("Name", text: .constant("Charles")).textFieldStyle(.plain)
                .tw("px-3 py-2 rounded-md bg-surface border")
            TextField("Disabled field", text: .constant("Read only"))
                .tw("px-3 py-2 border disabled:opacity-40").disabled(true)
            Toggle("Notifications", isOn: .constant(true))
            Toggle("Disabled toggle", isOn: .constant(false)).disabled(true)
            Slider(value: .constant(0.6)).accessibilityLabel("Volume")
            Text("Directional spacing").tw("ps-6 pe-2 py-2 border bg-accent w-full")
            VStack(alignment: .leading, spacing: 8) {
                Text("Native composition").tw("text-lg font-semibold")
                Text("A card keeps its real TextField, Toggle, and Button behavior.")
                Button("Save") {}.buttonStyle(.tw("button-outline"))
              }.tw("card w-full")
        }
    }

    private var utilities: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(["xs", "sm", "base", "lg", "xl", "2xl", "3xl"], id: \.self) { size in
                Text("Text \(size)").tw("text-\(size)")
              }
            Text("Last edge wins").tw("p-6 px-2 pt-1 rounded-lg border-2 border-primary bg-accent")
            Text("Fractional scale").tw("px-2.5 py-1.5 rounded-full bg-primary text-primary-foreground")
            Text("Shadow and opacity").tw("p-4 bg-surface rounded-xl shadow-lg opacity-80")
            Rectangle().frame(height: 32).tw("p-2").foregroundStyle(
                LinearGradient(colors: [.orange, .purple], startPoint: .leading, endPoint: .trailing))
            Text("Inherited title").tw("px-2").font(.title).foregroundStyle(.purple)
        }
    }

    private var globalRules: some View {
        let brand = TWColor("brand")
        let brandTheme = TWTheme(spacingUnit: 5, colors: [brand: TWAdaptiveColor(light: .indigo, dark: .mint)],
                                radii: [.lg: 22])
        let rules = TWGlobalRules(view: .text(.sm), button: .minH(48), named: [
            "brand-button": TWStyle(.primaryButton, .bg(brand), "animate-settle duration-250 delay-50"),
            "card": TWStyle(TWStyle.defaultStyle(for: "card")!, .rounded(.xl), .p(3))
        ], animations: ["settle": TWAnimation { .spring(duration: $0, bounce: 0.15) }])
        return VStack(alignment: .leading, spacing: 16) {
            Text("Default card").tw("card w-full")
            VStack(alignment: .leading, spacing: 12) {
                Text("Global card override").tw(.card, .fullWidth)
                Button("Custom named class") {}.buttonStyle(.tw("brand-button"))
                Text("Local radius wins").tw("card rounded-sm w-full")
                Text("Scoped override").tw("card w-full").twRules {
                    $0.named["card"] = .classes("p-2 border-2 border-brand rounded-none")
                  }
                Text("Sibling keeps global card").tw("card w-full")
              }.twTheme(brandTheme).twRules(rules)
        }
    }
}
#endif
