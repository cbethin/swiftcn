import AppKit
import QuartzCore
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

    @Test func nativePaddingUsesTheSamePresentationCapture() throws {
        try check(preset: "linear", expectsMotion: true, native: true)
    }

    @Test func plainUtilitiesInterpolateWithoutDemoEffects() throws {
        try check(preset: "linear", expectsMotion: true, plainUtilities: true)
    }

    @Test func nativePaddingWithRemovedSymbolEffectsStillInterpolates() throws {
        try check(preset: "linear", expectsMotion: true, native: true, removedSymbolEffects: true)
    }

    @Test(arguments: [TWAnimationScope.surface, .layout])
    func scopedMotionKeepsTheLabelFixed(scope: TWAnimationScope) throws {
        try check(preset: "linear", expectsMotion: scope != .content, animationScope: scope)
    }

    private func check(preset: String, expectsMotion: Bool, animationScope: TWAnimationScope = .all,
                       native: Bool = false, plainUtilities: Bool = false, removedSymbolEffects: Bool = false) throws {
        let model = SurfaceModel()
        let recorder = SurfaceEnvironment()
        let blue = TWAdaptiveColor(light: .blue, dark: .blue)
        let host = NSHostingView(rootView: SurfaceHarness(model: model, recorder: recorder, preset: preset,
            animationScope: animationScope, native: native, plainUtilities: plainUtilities, removedSymbolEffects: removedSymbolEffects)
            .twTheme(TWTheme(colors: [.primary: blue, .accent: blue,
                .onPrimary: .init(light: .white, dark: .white), .foreground: .init(light: .black, dark: .black)]))
            .environment(\.colorScheme, .light)
            .environment(\.demoMotionEnabled, false))
        host.frame = CGRect(x: 0, y: 0, width: 400, height: 180)
        host.wantsLayer = true
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        let label = "\(native ? "native" : "tw")\(plainUtilities ? "-plain" : "")\(removedSymbolEffects ? "-symbols" : "")-\(preset)-\(animationScope.rawValue)"
        var contentFrames: [CGRect] = []
        let compact = try bounds(host, name: "\(label)-compact", contentFrames: &contentFrames)
        var expansion: [CGRect] = []
        model.expanded = true
        for frame in 0..<12 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
            expansion.append(try bounds(host, name: "\(label)-expand-\(frame)", contentFrames: &contentFrames))
        }
        let expanded = try #require(expansion.last)
        #expect(expanded.width > compact.width + 30)
        #expect(expanded.height > compact.height + 30)
        var collapse: [CGRect] = []
        model.expanded = false
        for frame in 0..<12 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
            collapse.append(try bounds(host, name: "\(label)-collapse-\(frame)", contentFrames: &contentFrames))
        }
        let restingContent = try #require(contentFrames.first)
        #expect(contentFrames.allSatisfy {
            abs($0.midX - restingContent.midX) < 1 && abs($0.midY - restingContent.midY) < 1
        }, "Content centers: \(contentFrames.map { CGPoint(x: $0.midX, y: $0.midY) })")
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
        print("Motion \(label): compact=\(compact.size), expanded=\(expanded.size), expansion=\(expansion.map(\.size)), collapse=\(collapse.map(\.size))")
    }

    /// Read the native presentation pixels, not the target SwiftUI layout proposal.
    private func bounds<V: View>(_ host: NSHostingView<V>, name: String, contentFrames: inout [CGRect]) throws -> CGRect {
        // Flush pending AppKit layout before each capture, including on older runners.
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        CATransaction.flush()
        let layer = try #require(host.layer)
        let scale = host.window?.backingScaleFactor ?? 1
        let width = Int(host.bounds.width * scale), height = Int(host.bounds.height * scale)
        let presentation = try #require(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        presentation.scaleBy(x: scale, y: scale)
        (layer.presentation() ?? layer).render(in: presentation)
        let bitmap = NSBitmapImageRep(cgImage: try #require(presentation.makeImage()))
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
        // Measure only the label's ink, excluding the independently animated symbol.
        // This central region stays inside the blue surface at both endpoint sizes.
        // Read the explicit RGBA layout rather than AppKit's platform-specific bitmap format.
        let bytes = try #require(presentation.data).assumingMemoryBound(to: UInt8.self)
        var glyphX: [Int] = [], glyphY: [Int] = []
        for y in Int(76 * scale)..<Int(106 * scale) {
            for x in Int(165 * scale)..<Int(260 * scale) {
                let offset = (y * bitmap.pixelsWide + x) * 4
                let colors = [bytes[offset], bytes[offset + 1], bytes[offset + 2]]
                // Black, white, and their interpolated grays differ from the blue background.
                if colors.max()! - colors.min()! < 35 {
                    glyphX.append(x); glyphY.append(y)
                }
            }
        }
        let glyphLeft = try #require(glyphX.min()), glyphRight = try #require(glyphX.max())
        let glyphTop = try #require(glyphY.min()), glyphBottom = try #require(glyphY.max())
        contentFrames.append(CGRect(x: CGFloat(glyphLeft) / scale, y: CGFloat(glyphTop) / scale,
            width: CGFloat(glyphRight - glyphLeft + 1) / scale, height: CGFloat(glyphBottom - glyphTop + 1) / scale))
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
    let animationScope: TWAnimationScope
    var native = false
    var plainUtilities = false
    var removedSymbolEffects = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        recorder.reduceMotion = reduceMotion
        return Group {
            if native {
                HStack(spacing: 8) {
                    if removedSymbolEffects {
                        Image(systemName: "sparkles")
                            .symbolEffect(.bounce, options: .speed(1.4), value: model.expanded)
                            .symbolEffectsRemoved(true)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "sparkles").accessibilityHidden(true)
                    }
                    Text("Hello, SwiftUI").contentTransition(.identity)
                }
                .foregroundStyle(removedSymbolEffects && model.expanded ? Color.white : Color.black)
                .padding(model.expanded ? 32 : 12)
                .background(RoundedRectangle(cornerRadius: model.expanded ? 16 : 8).fill(.blue))
                .animation(.linear(duration: 1), value: model.expanded)
            } else if plainUtilities {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").accessibilityHidden(true)
                    Text("Hello, SwiftUI").contentTransition(.identity)
                }
                .tw(MotionSurface.classes(expanded: model.expanded, motion: "animate-linear duration-1000"), value: model.expanded)
            } else {
                MotionSurface(expanded: model.expanded, motionClasses: "animate-\(preset) duration-1000 delay-0", animationScope: animationScope)
            }
        }
        .frame(width: 400, height: 180)
        .background(.white)
    }
}
