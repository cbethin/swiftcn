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
                // A native host also captures AppKit-backed controls such as TextField.
                let host = NSHostingView(rootView: CatalogView().environment(\.colorScheme, scheme))
                host.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
                host.setFrameSize(host.fittingSize)
                let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
                window.contentView = host
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
                guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
                    throw CatalogError.renderFailed
                }
                host.cacheDisplay(in: host.bounds, to: bitmap)
                guard let data = bitmap.representation(using: .png, properties: [:]) else { throw CatalogError.renderFailed }
                window.contentView = nil
                let name = scheme == .dark ? "catalog-dark.png" : "catalog-light.png"
                try data.write(to: directory.appendingPathComponent(name))
                print("Rendered \(name)")
            }
            return
        }
        SwiftCNCatalogApp.main()
    }
}

private enum CatalogError: Error { case renderFailed }

struct SwiftCNCatalogApp: App {
    var body: some Scene {
        WindowGroup("swiftcn") { CatalogView() }
            .windowResizability(.contentSize)
    }
}
