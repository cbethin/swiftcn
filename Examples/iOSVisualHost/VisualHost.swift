import SwiftUI
import UIKit

// Compiled with the copied library sources, so this host needs no Xcode project.
@main
struct SwiftCNVisualHost: App {
    private let arguments = CommandLine.arguments
    private var dark: Bool { arguments.contains("--dark") }
    private var large: Bool { arguments.contains("--large-text") }
    private var rulesScene: Bool { arguments.contains("--rules") }
    private var component: CNComponentGallery? {
        guard let index = arguments.firstIndex(of: "--component"), arguments.indices.contains(index + 1) else { return nil }
        return CNComponentGallery(rawValue: arguments[index + 1])
    }
    private var captureID: String {
        guard let index = arguments.firstIndex(of: "--capture-id"), arguments.indices.contains(index + 1) else { return "manual" }
        return arguments[index + 1]
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let component {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(component.title).tw("text-xl font-semibold")
                            component.previewExample
                        }.tw("p-5 w-full")
                    }.tw("bg-background")
                } else { IOSFixture(rulesScene: rulesScene) }
            }
                .preferredColorScheme(dark ? .dark : .light)
                .environment(\.dynamicTypeSize, large ? .accessibility3 : .large)
                .environment(\.layoutDirection, arguments.contains("--rtl") ? .rightToLeft : .leftToRight)
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
                .cnLoadingPhase(0.35)
                .transaction { $0.animation = nil }
                .task {
                    // Signal only after the native controls settle. The capture script polls this file.
                    try? await Task.sleep(for: .seconds(1))
                    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                          let window = scene.windows.first(where: \.isKeyWindow),
                          let view = window.rootViewController?.view else { return }
                    if component == .command {
                        // Static references exclude caret blinking and keyboard inset timing.
                        // The component still focuses normally in the interactive gallery.
                        window.endEditing(true)
                        try? await Task.sleep(for: .milliseconds(500))
                        view.layoutIfNeeded()
                    }
                    if component != nil {
                        stopIndicators(view)
                        view.layoutIfNeeded()
                        CATransaction.flush()
                    }
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = view.traitCollection.displayScale
                    format.preferredRange = .standard
                    let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).pngData { _ in
                        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
                    }
                    do {
                        try image.write(to: directory.appendingPathComponent("visual-snapshot.png"))
                        let metrics: [String: Any] = [
                            "width": view.bounds.width, "height": view.bounds.height,
                            "scale": view.traitCollection.displayScale,
                            "horizontalSizeClass": view.traitCollection.horizontalSizeClass.rawValue,
                            "verticalSizeClass": view.traitCollection.verticalSizeClass.rawValue,
                            "safeArea": ["top": view.safeAreaInsets.top, "left": view.safeAreaInsets.left,
                                         "bottom": view.safeAreaInsets.bottom, "right": view.safeAreaInsets.right]
                        ]
                        try JSONSerialization.data(withJSONObject: metrics, options: [.sortedKeys])
                            .write(to: directory.appendingPathComponent("visual-metrics.json"), options: .atomic)
                        try Data(captureID.utf8).write(to: directory.appendingPathComponent("visual-ready"), options: .atomic)
                    } catch { print("Visual capture failed: \(error)") }
                }
        }
    }
}

@MainActor private func stopIndicators(_ view: UIView) {
    if let image = view as? UIImageView,
       let first = image.animationImages?.first ?? image.image?.images?.first {
        // SwiftUI's circular progress view uses native animated image frames.
        image.stopAnimating()
        image.animationImages = nil
        image.highlightedAnimationImages = nil
        image.image = first
        image.layer.removeAllAnimations()
    }
    if let indicator = view as? UIActivityIndicatorView {
        indicator.hidesWhenStopped = false
        indicator.stopAnimating()
        freezeIndicatorLayers(indicator.layer)
    }
    for child in view.subviews { stopIndicators(child) }
}

@MainActor private func freezeIndicatorLayers(_ layer: CALayer) {
    // UIKit can leave a presentation frame behind after stopAnimating().
    // Read the native model layers at a fixed clock for static comparisons.
    layer.removeAllAnimations()
    layer.speed = 0
    layer.timeOffset = 0
    for child in layer.sublayers ?? [] { freezeIndicatorLayers(child) }
}

private struct IOSFixture: View {
    let rulesScene: Bool
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("swiftcn / iOS").tw("text-xl font-semibold")
                if rulesScene { rules } else { controls }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .foregroundStyle(theme.color(.foreground, scheme: scheme))
        .background(theme.color(.background, scheme: scheme))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Native controls and Dynamic Type").tw("text-lg")
            TextField("Name", text: .constant("Charles")).textFieldStyle(.plain)
                .tw("px-3 py-2 rounded-md border bg-surface")
            Button("String classes") {}.buttonStyle(.tw("button-primary w-full animate-spring duration-150"))
            Button("Typed utilities") {}.buttonStyle(.tw(.outlineButton, .fullWidth, .animation(.snappy)))
            Button("Disabled button") {}.buttonStyle(.tw("button-primary w-full animate-none")).disabled(true)
            Toggle("Notifications", isOn: .constant(true))
            Slider(value: .constant(0.6)).accessibilityLabel("Volume")
            Text("Native text grows. The card and button heights follow the content.")
                .tw("card text-base w-full")
        }
    }

    private var rules: some View {
        let brand = TWColor("brand")
        let customTheme = TWTheme(colors: [brand: TWAdaptiveColor(light: .indigo, dark: .mint)])
        let customRules = TWGlobalRules(named: [
            "brand-button": TWStyle(.primaryButton, .bg(brand), .rounded(.full), "animate-settle duration-250"),
            "card": TWStyle(TWStyle.defaultStyle(for: "card")!, .p(3), .radius(20))
        ], animations: ["settle": TWAnimation { .spring(duration: $0, bounce: 0.15) }])
        return VStack(alignment: .leading, spacing: 16) {
            Text("Global rules").tw("text-lg")
            Text("A global card").tw("card w-full")
            Button("Brand button") {}.buttonStyle(.tw("brand-button w-full"))
            Text("Local overrides").tw("card rounded-sm w-full")
            Text("Scoped rules").tw("card w-full").twRules {
                $0.named["card"] = .classes("p-3 rounded-none border-2 border-brand")
            }
            Text("Sibling keeps global rules").tw("card w-full")
        }.twTheme(customTheme).twRules(customRules)
    }
}
