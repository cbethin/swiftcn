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
        #expect(TWStyleResolver.resolve(TWStyle(.radiusTop(20), .radiusBottom(8)), theme: .standard, scheme: .light,
                                        state: TWState()).edgeRadii?.top == 20)
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
