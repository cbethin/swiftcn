#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Native argument rendering", .serialized)
@MainActor
struct ArgumentRenderingTests {
    @Test(arguments: [false, true], [false, true])
    func arbitraryClassesMatchNativeModifiers(dark: Bool, largeText: Bool) throws {
        let text = Text("A quiet place for ideas.\nNative text, with custom arguments.")
        let color = try #require(TWArgument("#6366f1").hexColor)
        let native = text.font(.system(size: 18).weight(.semibold)).tracking(0.5)
            .lineSpacing(4).multilineTextAlignment(.center).lineLimit(2)
            .padding(12).frame(width: 240, height: 120)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(color))
            .opacity(0.85).blur(radius: 0.5).scaleEffect(0.95).rotationEffect(.degrees(2)).offset(x: 3, y: -2)
        let styled = text.tw("text-[18] font-semibold tracking-[0.5] line-spacing-[4] text-center line-clamp-[2] " +
                             "p-[12] w-[240] h-[120] rounded-[13] bg-[#6366f1] opacity-[0.85] blur-[0.5] scale-[0.95] rotate-[2deg] offset-[3,-2]")
        let expected = try render(native, dark: dark, largeText: largeText)
        let actual = try render(styled, dark: dark, largeText: largeText)
        #expect(actual.width == expected.width && actual.height == expected.height)
        #expect(try pixels(actual) == pixels(expected))
        if let directory = ProcessInfo.processInfo.environment["SWIFTCN_ARGUMENT_ARTIFACTS"] {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            let name = "arguments-\(dark ? "dark" : "light")-\(largeText ? "large" : "standard")"
            for (label, image) in [("native", expected), ("classes", actual)] {
                let data = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
                try data.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name)-\(label).png"))
            }
        }
    }

    @Test func absentTextUtilitiesPreserveNativeInheritance() throws {
        let text = Text("Inherited text\nSecond line\nThird line")
        let native = text.font(.title).tracking(3).lineSpacing(8).multilineTextAlignment(.trailing).lineLimit(2)
        let styled = text.tw("p-0").font(.title).tracking(3).lineSpacing(8).multilineTextAlignment(.trailing).lineLimit(2)
        #expect(try pixels(render(native)) == pixels(render(styled)))
        let unclamped = text.tw("line-clamp-none").lineLimit(1)
        #expect(try pixels(render(unclamped)) == pixels(render(text)))
    }

    @Test func trackingAndArgumentChangesPreserveChildIdentity() {
        let model = ArgumentIdentityModel()
        let recorder = ArgumentIdentityRecorder()
        let host = NSHostingView(rootView: ArgumentIdentityChild(model: model, recorder: recorder))
        host.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        let window = NSWindow(contentRect: host.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        for state in [false, true, false] {
            model.active = state
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        #expect(Set(recorder.values).count == 1)
        #expect(recorder.states.contains(true) && recorder.states.contains(false))
    }

    private func render<V: View>(_ view: V, dark: Bool = false, largeText: Bool = false) throws -> CGImage {
        let renderer = ImageRenderer(content: view.foregroundStyle(Color.primary)
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, largeText ? .accessibility3 : .large))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }

    private func pixels(_ image: CGImage) throws -> Data {
        let context = try #require(CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        let data = try #require(context.data)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Data(bytes: data, count: image.width * image.height * 4)
    }
}

@MainActor private final class ArgumentIdentityModel: ObservableObject { @Published var active = false }
@MainActor private final class ArgumentIdentityRecorder { var values: [UUID] = []; var states: [Bool] = [] }
private struct ArgumentIdentityChild: View {
    @ObservedObject var model: ArgumentIdentityModel
    let recorder: ArgumentIdentityRecorder
    @State private var identity = UUID()
    var body: some View {
        recorder.values.append(identity)
        recorder.states.append(model.active)
        return Text("Native text")
            .tw(model.active ? "tracking-[2] w-[220] rotate-[2deg]" : "w-[200]")
    }
}
#endif
