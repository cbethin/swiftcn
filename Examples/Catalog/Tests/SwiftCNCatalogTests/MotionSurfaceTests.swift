import AppKit
import SwiftUI
import SwiftCN
import Testing
@testable import SwiftCNCatalog

@Suite("Motion demo geometry", .serialized)
@MainActor
struct MotionSurfaceTests {
    @Test func expansionAndCollapseInterpolateActualCardSize() throws {
        try check(preset: "linear", expectsMotion: true)
    }

    @Test func noneChangesSizeImmediately() throws {
        try check(preset: "none", expectsMotion: false)
    }

    private func check(preset: String, expectsMotion: Bool) throws {
        let model = SurfaceModel()
        let recorder = SurfaceEnvironment()
        let blue = TWAdaptiveColor(light: .blue, dark: .blue)
        let host = NSHostingView(rootView: SurfaceHarness(model: model, recorder: recorder, preset: preset)
            .twTheme(TWTheme(colors: [.primary: blue, .accent: blue, .onPrimary: .init(light: .white, dark: .white)]))
            .environment(\.colorScheme, .light)
            .environment(\.demoMotionEnabled, false))
        host.frame = CGRect(x: 0, y: 0, width: 400, height: 180)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        let compact = try bounds(host, name: "\(preset)-compact")
        var expansion: [CGRect] = []
        model.expanded = true
        for frame in 0..<12 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
            expansion.append(try bounds(host, name: "\(preset)-expand-\(frame)"))
        }
        let expanded = try #require(expansion.last)
        #expect(expanded.width > compact.width + 30)
        #expect(expanded.height > compact.height + 30)
        var collapse: [CGRect] = []
        model.expanded = false
        for frame in 0..<12 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
            collapse.append(try bounds(host, name: "\(preset)-collapse-\(frame)"))
        }
        #expect(abs(try #require(collapse.last).width - compact.width) < 1)
        #expect(abs(try #require(collapse.last).height - compact.height) < 1)
        for frames in [expansion, collapse] {
            let widths = frames.map(\.width)
            let heights = frames.map(\.height)
            let intermediateWidths = widths.filter { $0 > compact.width + 2 && $0 < expanded.width - 2 }
            let intermediateHeights = heights.filter { $0 > compact.height + 2 && $0 < expanded.height - 2 }
            if expectsMotion && !recorder.reduceMotion {
                #expect(!intermediateWidths.isEmpty, "Rendered widths: \(widths)")
                #expect(!intermediateHeights.isEmpty, "Rendered heights: \(heights)")
            } else {
                #expect(intermediateWidths.isEmpty)
                #expect(intermediateHeights.isEmpty)
            }
            #expect(frames.allSatisfy { abs($0.midX - compact.midX) < 1 && abs($0.midY - compact.midY) < 1 })
        }
        print("Motion \(preset): compact=\(compact.size), expanded=\(expanded.size), expansion=\(expansion.map(\.size)), collapse=\(collapse.map(\.size))")
    }

    /// Read the native presentation pixels, not the target SwiftUI layout proposal.
    private func bounds<V: View>(_ host: NSHostingView<V>, name: String) throws -> CGRect {
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        if let path = ProcessInfo.processInfo.environment["SWIFTCN_MOTION_ARTIFACTS"] {
            let directory = URL(fileURLWithPath: path, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try bitmap.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent("\(name).png"))
        }
        func isBlue(_ x: Int, _ y: Int) -> Bool {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { return false }
            return color.blueComponent > color.redComponent + 0.4 && color.blueComponent > color.greenComponent + 0.15
        }
        let xs = (0..<bitmap.pixelsWide).filter { isBlue($0, bitmap.pixelsHigh / 2) }
        let ys = (0..<bitmap.pixelsHigh).filter { isBlue(bitmap.pixelsWide / 2, $0) }
        let left = try #require(xs.first), right = try #require(xs.last)
        let top = try #require(ys.first), bottom = try #require(ys.last)
        let scale = CGFloat(bitmap.pixelsWide) / host.bounds.width
        return CGRect(x: CGFloat(left) / scale, y: CGFloat(top) / scale,
                      width: CGFloat(right - left + 1) / scale, height: CGFloat(bottom - top + 1) / scale)
    }
}

@MainActor private final class SurfaceModel: ObservableObject {
    @Published var expanded = false
}
@MainActor private final class SurfaceEnvironment { var reduceMotion = false }
private struct SurfaceHarness: View {
    @ObservedObject var model: SurfaceModel
    let recorder: SurfaceEnvironment
    let preset: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        recorder.reduceMotion = reduceMotion
        return MotionSurface(expanded: model.expanded, motionClasses: "animate-\(preset) duration-1000 delay-0")
            .frame(width: 400, height: 180)
            .background(.white)
    }
}
