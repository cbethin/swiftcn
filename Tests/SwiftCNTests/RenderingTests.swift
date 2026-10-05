#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Native rendering", .serialized)
@MainActor
struct RenderingTests {
    @Test func unspecifiedForegroundInheritsAParentColor() throws {
        let image = try render(Rectangle().frame(width: 20, height: 20).tw(.p(1)).foregroundStyle(.red))
        let center = try pixel(image, x: image.width / 2, y: image.height / 2)
        let reference = try render(Rectangle().frame(width: 20, height: 20).foregroundStyle(.red))
        let expected = try pixel(reference, x: 10, y: 10)
        #expect(abs(center.red - expected.red) < 0.01)
        #expect(abs(center.green - expected.green) < 0.01)
        #expect(abs(center.blue - expected.blue) < 0.01)
    }

    @Test func explicitForegroundOverridesParentStyle() throws {
        let image = try render(Rectangle().frame(width: 20, height: 20).tw(.fgColor(.blue)).foregroundStyle(.red))
        let center = try pixel(image, x: 10, y: 10)
        #expect(center.blue > 0.9)
        #expect(center.red < 0.1)
    }

    @Test func unspecifiedForegroundInheritsParentColorModifierAndNestedUtilities() throws {
        let native = try render(Rectangle().frame(width: 20, height: 20).tw(.p(1)).foregroundColor(.red))
        let nested = try render(Rectangle().frame(width: 20, height: 20).tw(.p(1)).tw(.fgColor(.red)))
        #expect(try pixel(native, x: 14, y: 14).red > 0.9)
        #expect(try pixel(nested, x: 14, y: 14).red > 0.9)
    }

    @Test func unspecifiedForegroundPreservesInheritedGradient() throws {
        let gradient = LinearGradient(colors: [.red, .blue], startPoint: .leading, endPoint: .trailing)
        let reference = try render(Rectangle().frame(width: 20, height: 20).foregroundStyle(gradient))
        let styled = try render(Rectangle().frame(width: 20, height: 20).tw(.p(0)).foregroundStyle(gradient))
        for x in [2, 10, 17] {
            let expected = try pixel(reference, x: x, y: 10)
            let actual = try pixel(styled, x: x, y: 10)
            #expect(abs(actual.red - expected.red) < 0.01)
            #expect(abs(actual.blue - expected.blue) < 0.01)
        }
    }

    @Test func unspecifiedForegroundPreservesExplicitSecondaryStyle() throws {
        let reference = try render(Rectangle().fill(.secondary).frame(width: 20, height: 20)
            .foregroundStyle(Color.red, Color.blue))
        let styled = try render(Rectangle().fill(.secondary).frame(width: 20, height: 20)
            .tw(.p(0)).foregroundStyle(Color.red, Color.blue))
        let expected = try pixel(reference, x: 10, y: 10)
        let actual = try pixel(styled, x: 10, y: 10)
        #expect(abs(actual.red - expected.red) < 0.01)
        #expect(abs(actual.blue - expected.blue) < 0.01)
    }

    @Test func cornersShapeTheBackgroundWithoutClippingContent() throws {
        let image = try render(Rectangle().fill(.red).frame(width: 20, height: 20).tw(.rounded(.full)))
        let corner = try pixel(image, x: 1, y: 1)
        #expect(corner.red > 0.9)
        #expect(corner.alpha > 0.9)
    }

    @Test func paddingAffectsSizeAndBackgroundCoverage() throws {
        let image = try render(Color.red.frame(width: 20, height: 10).tw(.p(2), .bgColor(.blue)))
        #expect(image.width == 36)
        #expect(image.height == 26)
        let edge = try pixel(image, x: 1, y: 1)
        #expect(edge.blue > 0.9)
        let center = try pixel(image, x: 18, y: 13)
        #expect(center.red > 0.9)
    }

    @Test func adaptiveCustomColorsResolveInEachScheme() throws {
        let brand = TWColor("brand")
        let theme = TWTheme(colors: [brand: .init(light: .red, dark: .blue)])
        for scheme in [ColorScheme.light, .dark] {
            let image = try render(Color.clear.frame(width: 20, height: 20).tw(.bg(brand)).twTheme(theme), scheme: scheme)
            let center = try pixel(image, x: 10, y: 10)
            #expect(scheme == .dark ? center.blue > 0.9 : center.red > 0.9)
        }
    }

    @Test func missingFontPreservesInheritedFontAndWeightUpdatesIt() throws {
        let probe = FontProbe()
        _ = try render(FontReader(probe: probe).tw(.p(1)).font(.largeTitle))
        #expect(probe.font == .largeTitle)
        _ = try render(FontReader(probe: probe).tw(.weight(.bold)).font(.largeTitle))
        #expect(probe.font == Font.largeTitle.weight(.bold))
    }

    @Test func disabledEnvironmentActivatesAppearanceWithoutARecognizer() throws {
        let view = Color.red.frame(width: 20, height: 20).tw(.disabled(.opacity(0.25))).disabled(true)
        let image = try render(view)
        let center = try pixel(image, x: 10, y: 10)
        #expect(abs(center.alpha - 0.25) < 0.02)
    }

    @Test func changingVariantsPreservesChildStateIdentity() {
        let model = IdentityModel()
        let identities = IdentityRecorder()
        let host = NSHostingView(rootView: IdentityHarness(model: model, recorder: identities))
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        drainRunLoop()
        #expect(!identities.values.isEmpty)
        model.focused = true
        host.layoutSubtreeIfNeeded()
        drainRunLoop()
        model.focused = false
        host.layoutSubtreeIfNeeded()
        drainRunLoop()
        #expect(Set(identities.values).count == 1)
        #expect(identities.focusedValues.contains(true))
        #expect(identities.focusedValues.contains(false))
        window.contentView = nil
    }

    @Test func minimumHeightExpandsTheStyledSurface() throws {
        let image = try render(Color.clear.frame(width: 20, height: 10).tw(.minH(44), .bgColor(.blue)))
        #expect(image.height == 44)
        #expect(try pixel(image, x: 10, y: 1).blue > 0.9)
    }

    @Test func globalDefaultsAffectOnlyExplicitSurfacesAndLocalPaddingWins() throws {
        let rules = TWGlobalRules(view: TWStyle(.p(3), .bgColor(.red)))
        let plain = try render(Color.clear.frame(width: 20, height: 20).twRules(rules))
        #expect(plain.width == 20)
        let styled = try render(Color.clear.frame(width: 20, height: 20).tw(TWStyle()).twRules(rules))
        #expect(styled.width == 44)
        let local = try render(Color.clear.frame(width: 20, height: 20).tw("p-1").twRules(rules))
        #expect(local.width == 28)
    }

    @Test func subtreeRulesPreserveInheritedNamesWithoutLeakingToSiblings() throws {
        let rules = TWGlobalRules(named: ["tile": .classes("p-1 bg-primary"), "other": .classes("p-3")])
        let view = HStack(spacing: 0) {
            Color.clear.frame(width: 20, height: 20).tw("tile")
                .twRules { $0.named["tile"] = .classes("p-2") }
            Color.clear.frame(width: 20, height: 20).tw("tile")
            Color.clear.frame(width: 20, height: 20).tw("other")
                .twRules { $0.named["tile"] = .classes("p-2") }
        }.twRules(rules)
        #expect(try render(view).width == 36 + 28 + 44)
    }

    @Test func buttonDefaultsDoNotDecorateOrdinaryStyledViews() throws {
        let rules = TWGlobalRules(button: TWStyle(.minH(60), .p(2)))
        let plain = try render(Color.clear.frame(width: 20, height: 20).tw("").twRules(rules))
        #expect(plain.height == 20)
        let button = Button {} label: { Color.clear.frame(width: 20, height: 20) }
            .buttonStyle(.tw("")).twRules(rules)
        let image = try render(button)
        #expect(image.height == 60)
        #expect(image.width == 36)
    }

    private func render<V: View>(_ view: V, scheme: ColorScheme = .light) throws -> CGImage {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, scheme))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }

    private func pixel(_ image: CGImage, x: Int, y: Int) throws -> Pixel {
        let context = try #require(CGContext(
            data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        let index = (y * image.width + x) * 4
        let alpha = Double(bytes[index + 3]) / 255
        let divisor = max(alpha * 255, 1)
        return Pixel(red: Double(bytes[index]) / divisor, green: Double(bytes[index + 1]) / divisor,
                     blue: Double(bytes[index + 2]) / divisor, alpha: alpha)
    }

    private func drainRunLoop() {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }
}

private struct Pixel { var red: Double; var green: Double; var blue: Double; var alpha: Double }

@MainActor private final class FontProbe { var font: Font? }
private struct FontReader: View {
    let probe: FontProbe
    @Environment(\.font) private var font
    var body: some View {
        probe.font = font
        return Color.clear.frame(width: 1, height: 1)
    }
}

@MainActor private final class IdentityModel: ObservableObject {
    @Published var focused = false
}
@MainActor private final class IdentityRecorder {
    var values: [UUID] = []
    var focusedValues: [Bool] = []
}
private struct IdentityHarness: View {
    @ObservedObject var model: IdentityModel
    let recorder: IdentityRecorder
    var body: some View {
        IdentityChild(recorder: recorder, focused: model.focused)
            .tw(.focus(.fgColor(.red), .text(.xl), .bgColor(.blue), .rounded(.lg)),
                state: .init(isFocused: model.focused))
    }
}
private struct IdentityChild: View {
    let recorder: IdentityRecorder
    let focused: Bool
    @State private var identity = UUID()
    var body: some View {
        recorder.values.append(identity)
        recorder.focusedValues.append(focused)
        return Text("State identity")
    }
}
#endif
