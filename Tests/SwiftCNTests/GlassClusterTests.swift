import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Glass clusters")
struct GlassClusterPolicyTests {
    @Test func piecesAreAddedKeptAndRemovedByIdentifier() {
        let diff = TWGlassPieceDiff(current: ["a", "b", "c"], next: ["c", "d", "a", "d", "e"])
        #expect(diff.kept == ["c", "a"])
        #expect(diff.inserted == ["d", "e"], "A repeated identifier is one piece.")
        #expect(diff.removed == ["b"])
        let empty = TWGlassPieceDiff(current: [Int](), next: [])
        #expect(empty.inserted.isEmpty && empty.kept.isEmpty && empty.removed.isEmpty)
        #expect(TWGlassPieceDiff(current: [1, 2], next: []).removed == [1, 2])
    }

    @Test func uiKitClustersNeverUseSwiftUIGlass() {
        for engine in [TWGlassEngine.none, .swiftUI, .uiKit] {
            for supportsGlass in [false, true] {
                for appearance in [TWAppearance.automatic, .glass, .solid] {
                    for reduceTransparency in [false, true] {
                        let context = TWSurfaceContext(appearance: appearance, supportsGlass: supportsGlass,
                                                       reduceTransparency: reduceTransparency, engine: engine)
                        let rendering = TWGlassClusterRendering.resolve(context)
                        if reduceTransparency {
                            #expect(rendering == .solid, "Reduce Transparency draws no glass view.")
                        } else if !supportsGlass || engine == .none {
                            #expect(rendering == .material)
                        } else {
                            // A cluster is explicit glass, like the `glass` class: the policy does not turn it solid.
                            #expect(rendering == (engine == .uiKit ? .uiKitGlass : .swiftUIGlass))
                        }
                    }
                }
            }
        }
    }

    @Test func piecesKeepTheirIdentifierTypeAndDefaults() {
        let piece = TWGlassPiece(id: 7, frame: CGRect(x: 1, y: 2, width: 3, height: 4))
        #expect(piece.id == AnyHashable(7))
        #expect(piece.shape == .capsule && piece.tint == nil && !piece.interactive)
        #expect(TWGlassPiece(id: "7", frame: .zero).id != piece.id)
        #expect(EnvironmentValues().twGlassTracking == .transaction)
    }
}

#if os(macOS)
@Suite("Glass cluster rendering", .serialized)
@MainActor
struct GlassClusterRenderingTests {
    @Test func reduceTransparencyFillsEachPieceAtItsFrame() throws {
        let cluster = TWGlassCluster(pieces: [
            TWGlassPiece(id: 0, frame: CGRect(x: 10, y: 10, width: 30, height: 20), shape: .rounded(0), tint: Color(red: 1, green: 0, blue: 0)),
            TWGlassPiece(id: 1, frame: CGRect(x: 60, y: 10, width: 30, height: 20), shape: .edges(top: 0, bottom: 0)),
        ])
        .frame(width: 100, height: 40)
        .environment(\._accessibilityReduceTransparency, true)
        let image = try render(cluster)
        let tinted = try pixel(image, x: 25, y: 20)
        #expect(tinted.red > 0.9 && tinted.green < 0.2 && tinted.alpha > 0.99, "A tinted piece fills with its tint.")
        let surface = try pixel(image, x: 75, y: 20)
        let expected = try pixel(try render(Color.clear.frame(width: 4, height: 4)
            .background(TWTheme.standard.color(.surface, scheme: .light))), x: 2, y: 2)
        #expect(abs(surface.red - expected.red) < 0.02 && abs(surface.blue - expected.blue) < 0.02 && surface.alpha > 0.99)
        #expect(try pixel(image, x: 50, y: 20).alpha < 0.01, "Nothing is drawn between pieces.")
        #expect(try pixel(image, x: 25, y: 35).alpha < 0.01, "Nothing is drawn outside a piece.")
    }

    @Test func glassFramesReceiveTheValueAndTheContentSize() throws {
        let probe = FramesProbe()
        let view = Color.clear.frame(width: 120, height: 40)
            .twGlassFrames(CGFloat(0.5)) { value, size in
                probe.calls.append((value, size))
                return [TWGlassPiece(id: 0, frame: CGRect(x: 0, y: 0, width: size.width * value, height: size.height),
                                     shape: .rounded(0), tint: .blue)]
            }
            .environment(\._accessibilityReduceTransparency, true)
        let image = try render(view)
        let last = try #require(probe.calls.last)
        #expect(last.0 == 0.5 && last.1 == CGSize(width: 120, height: 40))
        #expect(try pixel(image, x: 30, y: 20).blue > 0.9, "The piece covers the computed frame.")
        #expect(try pixel(image, x: 90, y: 20).alpha < 0.01, "Nothing beyond the computed width.")
    }

    private func render<V: View>(_ view: V) throws -> CGImage {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
        renderer.scale = 1
        return try #require(renderer.cgImage)
    }

    private func pixel(_ image: CGImage, x: Int, y: Int) throws -> (red: Double, green: Double, blue: Double, alpha: Double) {
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
        return (Double(bytes[index]) / divisor, Double(bytes[index + 1]) / divisor, Double(bytes[index + 2]) / divisor, alpha)
    }
}

@MainActor private final class FramesProbe { var calls: [(CGFloat, CGSize)] = [] }
#endif
