import SwiftUI
import Testing
@testable import SwiftCN
@testable import SwiftCNComponentGallery

@Suite("Gallery workbench data", .serialized)
@MainActor
struct GalleryWorkbenchTests {
    @Test func repeatedChromeResolutionReusesItsExpansionCache() {
        let style = TWStyle.classes("sidebar-menu-button text-[13] rounded-[11]")
        _ = TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: TWState(),
                                    globalRules: GalleryInteractionStyle.rules)
        let count = TWExpansionCache.shared.count
        for _ in 0..<100 {
            _ = TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: TWState(isHovered: true),
                                        globalRules: GalleryInteractionStyle.rules)
        }
        #expect(TWExpansionCache.shared.count == count)
    }

    @Test func codeDocumentsReuseSourceMetadataAndKeepBothColorVariants() {
        let source = "import SwiftUI\nlet title = \"Native\"\n"
        let document = GalleryCodeDocument.cached(source)
        #expect(document === GalleryCodeDocument.cached(source))
        #expect(document !== GalleryCodeDocument.cached(source + "// changed"))
        #expect(document.lineCount == 3 && document.lineNumbers == "1\n2\n3")
        let light = document.highlighted(dark: false)
        let dark = document.highlighted(dark: true)
        #expect(String(light.characters) == source && String(dark.characters) == source)
        #expect(light != dark)
        #expect(GallerySwiftSyntax.highlight(source, dark: false) == light)
        #expect(GallerySwiftSyntax.highlight(source, dark: true) == dark)
    }

    @Test func clearedFilterRestoresTheCompleteCatalog() {
        #expect(GallerySearchResults("button").components == [.button, .button_group])
        #expect(GallerySearchResults("CNInputOTP").components.contains(.input_otp))
        let cleared = GallerySearchResults("")
        #expect(cleared.components == CNComponentGallery.allCases)
        #expect(cleared.compositions == CNNativeComposition.allCases)
        #expect(cleared.groups.flatMap(\.components).count == CNComponentGallery.allCases.count)
    }

}
