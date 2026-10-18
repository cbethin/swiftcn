import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Top and bottom radii")
struct EdgeRadiusTests {
    private func resolve(_ classes: String) -> TWResolvedStyle {
        TWStyleResolver.resolve(.classes(classes), theme: .standard, scheme: .light, state: TWState())
    }

    @Test func topAndBottomClassesSetTheirCornersAlone() throws {
        let sheet = resolve("rounded-t-[28] rounded-b-[12]")
        #expect(sheet.hasRadius)
        let corners = try #require(sheet.edgeRadii)
        #expect(corners.top == 28 && corners.bottom == 12)

        // The other corners keep the radius `rounded-*` gives.
        let mixed = try #require(resolve("rounded-[14] rounded-b-none").edgeRadii)
        #expect(mixed.top == 14 && mixed.bottom == 0)

        let tokens = try #require(resolve("rounded-t-xl rounded-b-sm").edgeRadii)
        #expect(tokens.top == TWTheme.standard.radius(.xl) && tokens.bottom == TWTheme.standard.radius(.sm))
    }

    @Test func equalRadiiAreOneRoundedRectangle() {
        #expect(resolve("rounded-[14]").edgeRadii == nil)
        #expect(resolve("rounded-t-[14] rounded-b-[14]").edgeRadii == nil)
        #expect(resolve("rounded-t-[14] rounded-b-[14]").radius == 14)
        #expect(resolve("rounded-[14] rounded-t-[20] rounded-b-[20]").radius == 20)
        #expect(TWStyleResolver.resolve(TWStyle(.radiusTop(20), .radiusBottom(8)), theme: .standard, scheme: .light,
                                        state: TWState()).edgeRadii?.top == 20)
    }

    @Test func generalRadiiReplaceEarlierEdgeRadii() {
        let general = resolve("rounded-t-[28] rounded-b-[12] rounded-[8]")
        #expect(general.radius == 8 && general.edgeRadii == nil)
        let hovered = TWStyleResolver.resolve("rounded-t-[28] hover:rounded-none", theme: .standard,
                                             scheme: .light, state: TWState(isHovered: true))
        #expect(hovered.radius == 0 && hovered.edgeRadii == nil)
        let edge = resolve("rounded-[8] rounded-t-[28]")
        #expect(edge.edgeRadii?.top == 28 && edge.edgeRadii?.bottom == 8)
    }

    @Test func surfaceRadiiAndBorderInsetsInterpolate() {
        var shape = TWSurfaceShape(top: 4, bottom: 8)
        let target = TWSurfaceShape(top: 24, bottom: 28, inset: 2)
        var difference = target.animatableData - shape.animatableData
        difference.scale(by: 0.5)
        shape.animatableData += difference
        #expect(shape.top == 14 && shape.bottom == 18 && shape.inset == 1)

        var uniform = TWSurfaceShape(top: 0, bottom: 0)
        let rounded = TWSurfaceShape(top: 28, bottom: 28)
        var uniformDifference = rounded.animatableData - uniform.animatableData
        uniformDifference.scale(by: 0.5)
        uniform.animatableData += uniformDifference
        let rect = CGRect(x: 0, y: 0, width: 180, height: 64)
        #expect(uniform.path(in: rect).description == RoundedRectangle(cornerRadius: 14, style: .continuous).path(in: rect).description)
    }

    /// With equal radii the surface draws exactly what a RoundedRectangle drew before, inset or not,
    /// so existing surfaces and their borders don't move.
    @Test func equalRadiiDrawExactlyARoundedRectangle() {
        let rect = CGRect(x: 0, y: 0, width: 180, height: 64)
        for radius: CGFloat in [0, 14, 10_000] {
            let shape = TWSurfaceShape(top: radius, bottom: radius)
            let rounded = RoundedRectangle(cornerRadius: radius, style: .continuous)
            #expect(shape.path(in: rect).description == rounded.path(in: rect).description)
            #expect(shape.inset(by: 0.5).path(in: rect).description == rounded.inset(by: 0.5).path(in: rect).description)
        }
    }

    @Test func unequalRadiiDrawASheetsCorners() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 300)
        let path = TWSurfaceShape(top: 30, bottom: 6).path(in: rect)
        #expect(path.boundingRect.integral == rect)
        // The top corner is cut far more than the bottom one.
        #expect(!path.contains(CGPoint(x: 3, y: 3)))
        #expect(path.contains(CGPoint(x: 3, y: 296)) == false || path.contains(CGPoint(x: 6, y: 294)))
        #expect(!path.contains(CGPoint(x: 8, y: 8)))
        #expect(path.contains(CGPoint(x: 8, y: 292)))
    }

    @Test func parserRefusesUnknownEdgeTokens() {
        #expect(throws: (any Error).self) {
            try TWClassParser.expand(.classes("rounded-t-huge"), rules: TWGlobalRules(), theme: .standard, target: .view)
        }
    }
}

#if os(macOS)
@Suite("Rendered edge radii", .serialized)
@MainActor
struct EdgeRadiusRenderingTests {
    private var red: Color { Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1) }
    private var blue: Color { Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 1) }

    @Test(arguments: ["", "surface-solid"], [LayoutDirection.leftToRight, .rightToLeft])
    func backgroundsAndBordersUseBothEdges(role: String, direction: LayoutDirection) throws {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 12,
                                          bottomTrailingRadius: 12, topTrailingRadius: 28, style: .continuous)
        // Equal leading/trailing corners keep the native LTR raster in either layout direction.
        let expected = Color.clear.frame(width: 200, height: 100)
            .background(shape.fill(red).environment(\.layoutDirection, .leftToRight))
            .overlay(shape.strokeBorder(blue, lineWidth: 2).environment(\.layoutDirection, .leftToRight))
            .environment(\.layoutDirection, direction)
        let actual = Color.clear.frame(width: 200, height: 100)
            .tw("bg-[#ff0000] border-[#0000ff] border-[2] rounded-t-[28] rounded-b-[12] \(role)")
            .environment(\.layoutDirection, direction)
        #expect(try pixels(actual) == pixels(expected))
    }

    @Test(arguments: ["", "surface-solid"], [LayoutDirection.leftToRight, .rightToLeft])
    func equalEdgesRenderTheirSpecifiedRadius(role: String, direction: LayoutDirection) throws {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let expected = Color.clear.frame(width: 200, height: 100)
            .background(shape.fill(red))
            .overlay(shape.strokeBorder(blue, lineWidth: 2))
            .environment(\.layoutDirection, direction)
        let actual = Color.clear.frame(width: 200, height: 100)
            .tw("bg-[#ff0000] border-[#0000ff] border-[2] rounded-t-[14] rounded-b-[14] \(role)")
            .environment(\.layoutDirection, direction)
        #expect(try pixels(actual) == pixels(expected))
    }

    private func pixels<V: View>(_ view: V) throws -> Data {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light).environment(\.twGlassSupport, false))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        let context = try #require(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return Data(bytes: try #require(context.data), count: image.width * image.height * 4)
    }
}
#endif

@Suite("Reduced motion variants")
struct ReducedMotionTests {
    private func resolve(_ classes: String, pressed: Bool = false, reduced: Bool = false) -> TWResolvedStyle {
        TWStyleResolver.resolve(.classes(classes), theme: .standard, scheme: .light,
                                state: TWState(isPressed: pressed, prefersReducedMotion: reduced))
    }

    @Test func motionReduceCancelsAPressScale() {
        let classes = "pressed:scale-[0.94] motion-reduce:pressed:scale-[1]"
        #expect(resolve(classes, pressed: true).scale.width == 0.94)
        #expect(resolve(classes, pressed: true, reduced: true).scale.width == 1)
        #expect(resolve(classes, pressed: false, reduced: true).scale.width == 1)
    }

    @Test func motionSafeAppliesOnlyWithFullMotion() {
        #expect(resolve("motion-safe:scale-[1.05]").scale.width == 1.05)
        #expect(resolve("motion-safe:scale-[1.05]", reduced: true).scale.width == 1)
    }

    /// Reduce Motion drops an animation, unless it was written for reduced motion: then it runs,
    /// so a press can fade instead of snapping.
    @Test func anAnimationWrittenForReducedMotionStillRuns() {
        var plain = Transaction()
        resolve("animate-snappy", reduced: true).motion.update(&plain, reduceMotion: true)
        #expect(plain.animation == nil)

        let fade = resolve("animate-snappy motion-reduce:animate-smooth motion-reduce:duration-[120ms]", reduced: true).motion
        #expect(fade.runsWithReducedMotion)
        #expect(fade.duration == 0.12)
        var reduced = Transaction()
        fade.update(&reduced, reduceMotion: true)
        #expect(reduced.animation != nil)

        var full = Transaction()
        resolve("animate-snappy motion-reduce:animate-smooth").motion.update(&full, reduceMotion: false)
        #expect(full.animation != nil)
    }
}
