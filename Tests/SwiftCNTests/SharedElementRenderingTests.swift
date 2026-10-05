#if os(macOS)
import AppKit
import SwiftUI
import Testing
import SwiftCN

@Suite("Native shared elements", .serialized)
@MainActor
struct SharedElementRenderingTests {
    @Test(arguments: [false, true])
    func sourceDimensionsMatchOnlyInsideTheSameNamespace(separate: Bool) throws {
        let host = NSHostingView(rootView: SharedSizeFixture(separate: separate))
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil); window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        if let directory = ProcessInfo.processInfo.environment["SWIFTCN_SHARED_ARTIFACTS"],
           let png = bitmap.representation(using: .png, properties: [:]) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("shared-size-\(separate).png"))
        }
        var xs: [Int] = [], ys: [Int] = []
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB)
                if let color, color.blueComponent > color.redComponent + 0.4,
                   color.blueComponent > color.greenComponent + 0.15, color.alphaComponent > 0.9 {
                    xs.append(x); ys.append(y)
                }
            }
        }
        let scale = CGFloat(bitmap.pixelsWide) / host.bounds.width
        let width = CGFloat(try #require(xs.max()) - #require(xs.min()) + 1) / scale
        let height = CGFloat(try #require(ys.max()) - #require(ys.min()) + 1) / scale
        #expect(abs(width - (separate ? 16 : 48)) < 1)
        #expect(abs(height - (separate ? 12 : 24)) < 1)
    }
}

private struct SharedSizeFixture: View {
    @Namespace private var first
    @Namespace private var second
    let separate: Bool

    var body: some View {
        HStack(spacing: 60) {
            Color.red.frame(width: 48, height: 24)
                .twShared(42, in: first, properties: .size, anchor: .topLeading)
            Color.blue
                .twShared(42, in: separate ? second : first, properties: .size,
                    anchor: .topLeading, isSource: separate)
                .frame(width: 16, height: 12)
        }
        .frame(width: 200, height: 100)
    }
}
#endif
