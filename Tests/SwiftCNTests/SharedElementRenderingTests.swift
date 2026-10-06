#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Native shared elements", .serialized)
@MainActor
struct SharedElementRenderingTests {
    @Test(arguments: [false, true])
    func sourceDimensionsMatchOnlyInsideTheSameNamespace(separate: Bool) throws {
        let size = try blueDimensions(SharedSizeFixture(separate: separate), name: "shared-size-\(separate)")
        #expect(abs(size.width - (separate ? 16 : 48)) < 1)
        #expect(abs(size.height - (separate ? 12 : 24)) < 1)
    }

    @Test(arguments: ["same", "siblings", "nearest", "named"])
    func classScopesMatchNearestNamedAndIsolatedGroups(layout: String) throws {
        let size = try blueDimensions(ClassSharedSizeFixture(layout: layout), name: "class-shared-\(layout)")
        let matches = layout == "same" || layout == "named"
        #expect(abs(size.width - (matches ? 48 : 16)) < 1)
        #expect(abs(size.height - (matches ? 24 : 12)) < 1)
    }

    @Test func groupUpdatesPreserveNamespaceAndChildStateWhilePassingNativeState() {
        let model = GroupModel()
        let recorder = GroupRecorder()
        let host = NSHostingView(rootView: GroupIdentityFixture(model: model, recorder: recorder))
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        model.hovered = true
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        model.hovered = false
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        #expect(Set(recorder.namespaces).count == 1)
        #expect(Set(recorder.identities).count == 1)
        #expect(recorder.hoverStates.contains(true))
        #expect(recorder.hoverStates.contains(false))
    }

    private func blueDimensions<V: View>(_ view: V, name: String) throws -> CGSize {
        let host = NSHostingView(rootView: view)
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
            try png.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
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
        return CGSize(width: width, height: height)
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

private struct ClassSharedSizeFixture: View {
    let layout: String
    private var source: some View { Color.red.tw("shared-[cover] shared-size w-12 h-6") }
    private var follower: some View { Color.blue.tw("shared-[cover] shared-follower shared-size w-4 h-3") }

    @ViewBuilder var body: some View {
        if layout == "siblings" {
            HStack(spacing: 60) {
                source.tw("group/hero")
                Color.blue.tw("shared-[cover] shared-size w-4 h-3").tw("group/hero")
            }.frame(width: 200, height: 100)
        } else {
            HStack(spacing: 60) {
                source
                if layout == "nearest" {
                    Color.blue.tw("shared-[cover] shared-size w-4 h-3").tw("group/inner")
                } else if layout == "named" {
                    Color.blue.tw("shared-[cover]/hero shared-follower shared-size w-4 h-3").tw("group/inner")
                } else {
                    follower
                }
            }
            .frame(width: 200, height: 100)
            .tw("group/hero")
        }
    }
}

@MainActor private final class GroupModel: ObservableObject {
    @Published var hovered = false
}

@MainActor private final class GroupRecorder {
    var namespaces: [Namespace.ID] = []
    var identities: [UUID] = []
    var hoverStates: [Bool] = []
}

private struct GroupIdentityFixture: View {
    @ObservedObject var model: GroupModel
    let recorder: GroupRecorder
    var body: some View {
        GroupIdentityChild(recorder: recorder)
            .tw("group/hero \(model.hovered ? "p-4" : "p-2")", state: .init(isHovered: model.hovered))
    }
}

private struct GroupIdentityChild: View {
    let recorder: GroupRecorder
    @State private var identity = UUID()
    @Environment(\.twGroups) private var groups
    var body: some View {
        if let scope = groups.scope(named: "hero") {
            recorder.namespaces.append(scope.namespace)
            recorder.hoverStates.append(scope.state.isHovered)
        }
        recorder.identities.append(identity)
        return Color.blue.frame(width: 20, height: 20).tw("group-hover/hero:opacity-20")
    }
}
#endif
