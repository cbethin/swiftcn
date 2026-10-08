#if os(macOS)
import AppKit
import SwiftUI
import Testing
import SwiftCN

@Suite("Standard theme text contrast")
@MainActor
struct ThemeContrastTests {
    @Test(arguments: [ColorScheme.light, .dark])
    func textRemainsReadableOnDefaultSurfaces(scheme: ColorScheme) throws {
        let theme = TWTheme.standard
        for background in [TWColor.background, .surface, .muted, .accent] {
            #expect(try contrast(theme.color(.foreground, scheme: scheme), theme.color(background, scheme: scheme)) >= 7)
            #expect(try contrast(theme.color(.mutedForeground, scheme: scheme), theme.color(background, scheme: scheme)) >= 4.5)
        }
        for (foreground, background) in [(TWColor.onPrimary, TWColor.primary), (.onAccent, .accent), (.onDestructive, .destructive)] {
            #expect(try contrast(theme.color(foreground, scheme: scheme), theme.color(background, scheme: scheme)) >= 4.5)
        }
    }

    private func contrast(_ foreground: Color, _ background: Color) throws -> Double {
        let a = try luminance(foreground), b = try luminance(background)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
    private func luminance(_ color: Color) throws -> Double {
        let rgb = try #require(NSColor(color).usingColorSpace(.sRGB))
        func linear(_ value: CGFloat) -> Double {
            let value = Double(value)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgb.redComponent) + 0.7152 * linear(rgb.greenComponent) + 0.0722 * linear(rgb.blueComponent)
    }
}
#endif
