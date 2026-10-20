import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Container-relative corners")
struct ContainerShapeTests {
    @Test func explicitCornersOverrideContainerCornersAndViceVersa() {
        let nested = TWStyleResolver.resolve("rounded-xl rounded-container", theme: .standard,
                                             scheme: .light, state: TWState())
        #expect(nested.containerRelativeRadius)
        #expect(!nested.hasRadius, "Container-relative corners must not request square native bezels.")
        let fixed = TWStyleResolver.resolve("rounded-container rounded-lg", theme: .standard,
                                            scheme: .light, state: TWState())
        #expect(!fixed.containerRelativeRadius && fixed.radius == TWTheme.standard.radius(.lg))
    }

    @Test(arguments: ["control-motion", "input", "input-group", "textarea", "calendar-day",
                      "resizable-handle", "sidebar-menu-button", "dropdown-item"])
    func builtInControlFeedbackNeverAddsATrailingAnimation(recipe: String) {
        for state in [TWState(), TWState(isHovered: true), TWState(isPressed: true), TWState(isFocused: true)] {
            let motion = TWStyleResolver.resolve(.classes(recipe), theme: .standard,
                                                  scheme: .light, state: state).motion
            var transaction = Transaction(animation: .linear(duration: 1))
            motion.update(&transaction, reduceMotion: false)
            #expect(motion.preset != nil)
            #expect(transaction.animation == nil)
        }
        let custom = TWStyleResolver.resolve(.classes("\(recipe) animate-ease-out duration-100"),
            theme: .standard, scheme: .light, state: TWState(isHovered: true)).motion
        var transaction = Transaction()
        custom.update(&transaction, reduceMotion: false)
        #expect(transaction.animation == .easeOut(duration: 0.1).delay(0))
    }
}

#if os(macOS)
@Suite("Rendered container corners", .serialized)
@MainActor
struct ContainerShapeRenderingTests {
    @Test(arguments: ["card", "field", "custom", "hover", "disabled"], [LayoutDirection.leftToRight, .rightToLeft])
    func insetFillFollowsTheParentThemeAndPlacement(parent: String, direction: LayoutDirection) throws {
        for radius: CGFloat in [12, 24] {
            var theme = TWTheme.standard
            theme.radii[.xl] = radius
            let actualChild = Color.clear.frame(width: 32, height: 32)
                .tw("rounded-container hover:bg-[#0000ff]", state: TWState(isHovered: true))
            let actual = Group {
                if parent == "card" {
                    CNCard("p-1 rounded-xl bg-[#ff0000] border-0 shadow-none") {
                        HStack(spacing: 8) { Spacer(minLength: 0); actualChild }
                    }
                } else if parent == "field" {
                    CNInputGroup("p-1 rounded-xl bg-[#ff0000] border-0") {
                        Spacer(minLength: 0); actualChild
                    }
                } else if parent == "hover" {
                    HStack(spacing: 8) { Spacer(minLength: 0); actualChild }
                        .tw("p-1 rounded-none hover:rounded-xl bg-[#ff0000]", state: TWState(isHovered: true))
                } else if parent == "disabled" {
                    HStack(spacing: 8) { Spacer(minLength: 0); actualChild }
                        .tw("p-1 rounded-md disabled:rounded-xl bg-[#ff0000]").disabled(true)
                } else {
                    HStack(spacing: 8) { Spacer(minLength: 0); actualChild }
                        .tw("p-1 rounded-xl bg-[#ff0000]")
                }
            }.frame(width: 160).twTheme(theme).environment(\.layoutDirection, direction)
            let expected = HStack(spacing: 8) {
                Spacer(minLength: 0)
                Color.clear.frame(width: 32, height: 32)
                    .background { ContainerRelativeShape().fill(Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 1)) }
            }.padding(4).frame(width: 160)
                .background { RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)) }
                .containerShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .environment(\.layoutDirection, direction)
            #expect(try pixels(actual) == pixels(expected))
        }
    }

    @Test func unroundedStyledWrappersPreserveRealCurvedCorners() throws {
        let native = Color.clear.frame(width: 32, height: 32)
            .background { ContainerRelativeShape().fill(Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)) }
            .padding(4).containerShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        let forwarded = Color.clear.frame(width: 32, height: 32)
            .tw("rounded-container bg-[#ff0000]")
            .tw("text-mutedForeground")
            .tw("p-1")
            .tw("rounded-[18]")
        let rectangle = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1).frame(width: 32, height: 32).padding(4)
        #expect(try pixels(native) != pixels(rectangle))
        #expect(try pixels(native) == pixels(forwarded))
    }

    private func pixels<V: View>(_ view: V) throws -> Data {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
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
