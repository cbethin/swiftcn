import AppKit
import SwiftUI
import SwiftCN

@main
struct CatalogLauncher {
    @MainActor static func main() throws {
        let arguments = CommandLine.arguments
        if let renderIndex = arguments.firstIndex(of: "--render"), arguments.indices.contains(renderIndex + 1) {
            let directory = URL(fileURLWithPath: arguments[renderIndex + 1], isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            NSApplication.shared.setActivationPolicy(.prohibited)
            for scheme in [ColorScheme.light, .dark] {
                let appearance = scheme == .dark ? "dark" : "light"
                try render(CatalogView(), scheme: scheme, name: "catalog-\(appearance).png", directory: directory)
                try render(ComponentPlayground().frame(width: 720, height: 820), scheme: scheme,
                           name: "components-\(appearance).png", directory: directory)
                try render(ArgumentPlayground().frame(width: 1040, height: 800), scheme: scheme,
                           name: "arguments-\(appearance).png", directory: directory)
                for expanded in [false, true] {
                    let layout = expanded ? "detail" : "compact"
                    try render(SharedElementPlayground(expanded: expanded).frame(width: 980, height: 820),
                        scheme: scheme, name: "shared-\(layout)-\(appearance).png", directory: directory)
                }
            }
            return
        }
        SwiftCNCatalogApp.main()
    }

    @MainActor private static func render<V: View>(_ view: V, scheme: ColorScheme,
                                                  name: String, directory: URL) throws {
        // A native host also captures AppKit-backed controls such as TextField.
        let host = NSHostingView(rootView: view
            .foregroundStyle(TWTheme.standard.color(.foreground, scheme: scheme))
            .background(TWTheme.standard.color(.background, scheme: scheme))
            .environment(\.demoMotionEnabled, false)
            .environment(\.colorScheme, scheme))
        host.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        host.setFrameSize(host.fittingSize)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { throw CatalogError.renderFailed }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw CatalogError.renderFailed }
        try data.write(to: directory.appendingPathComponent(name))
        print("Rendered \(name)")
    }
}

private enum CatalogError: Error { case renderFailed }

struct SwiftCNCatalogApp: App {
    var body: some Scene {
        WindowGroup("swiftcn Demo") { DemoView() }
            .defaultSize(width: 1040, height: 800)
            .windowResizability(.contentMinSize)
    }
}
