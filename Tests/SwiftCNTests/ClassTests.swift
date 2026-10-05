import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Classes and global rules")
struct ClassTests {
    private func resolve(_ style: TWStyle, rules: TWGlobalRules = TWGlobalRules(),
                         theme: TWTheme = .standard, state: TWState = TWState()) -> TWResolvedStyle {
        TWStyleResolver.resolve(style, theme: theme, scheme: .light, state: state, globalRules: rules)
    }

    @Test func stringsComposeByPropertyAndWhitespace() throws {
        let result = resolve(try .parse(" p-4\npx-6\tpt-1 rounded-lg rounded-md text-sm font-bold "))
        #expect(result.padding.top == 4)
        #expect(result.padding.bottom == 16)
        #expect(result.padding.leading == 24)
        #expect(result.radius == 8)
        #expect(result.weight == .bold)
        #expect(result.font == TWTheme.standard.font(.sm))
    }

    @Test func stringsAndTypedUtilitiesResolveEqually() throws {
        let text = resolve(try .parse("button-primary px-6 active:opacity-70 disabled:opacity-20"), state: .init(isPressed: true))
        let typed = resolve(TWStyle(.primaryButton, .px(6), .pressed(.opacity(0.7)), .disabled(.opacity(0.2))), state: .init(isPressed: true))
        #expect(text.padding.leading == typed.padding.leading)
        #expect(text.opacity == typed.opacity)
        #expect(text.background == typed.background)
        #expect(text.minimumHeight == typed.minimumHeight)
    }

    @Test func nestedVariantsRequireAllConditions() throws {
        let style = try TWStyle.parse("disabled:hover:opacity-10 disabled:opacity-30 hover:opacity-60")
        #expect(resolve(style, state: .init(isDisabled: true)).opacity == 0.3)
        #expect(resolve(style, state: .init(isHovered: true, isDisabled: true)).opacity == 0.1)
    }

    @Test func dimensionsUseTheCurrentSpacingScale() {
        let style = TWStyle.classes("w-12 h-10 min-h-8 px-2.5")
        let result = resolve(style, theme: TWTheme(spacingUnit: 5))
        #expect(result.width == 60)
        #expect(result.height == 50)
        #expect(result.minimumHeight == 40)
        #expect(result.padding.leading == 12.5)
    }

    @Test func borderColorAndWidthComposeIndependently() throws {
        let a = resolve(try .parse("border-2 border-primary"))
        let b = resolve(try .parse("border-primary border-2"))
        #expect(a.borderWidth == 2)
        #expect(a.border == b.border)
        #expect(b.borderWidth == 2)
        #expect(resolve(try .parse("border border-0")).borderWidth == 0)
    }

    @Test func namedRulesResolveLateAndLocalUtilitiesWin() {
        let style = TWStyle.classes("brand-button px-2")
        var rules = TWGlobalRules(named: ["brand-button": TWStyle(.primaryButton, .px(8), .radius(20))])
        #expect(resolve(style, rules: rules).radius == 20)
        #expect(resolve(style, rules: rules).padding.leading == 8)
        rules.named["brand-button"] = TWStyle(.primaryButton, .radius(30))
        #expect(resolve(style, rules: rules).radius == 30)
    }

    @Test func globalRulesAcceptStringLiteralsAndTypedComposition() {
        let rules = TWGlobalRules(view: "text-sm", button: "min-h-12", named: [
            "pill": "button-primary rounded-full"
        ])
        let style = TWStyle("pill", .px(6))
        #expect(resolve(style, rules: rules).radius == 10_000)
        #expect(resolve(style, rules: rules).padding.leading == 24)
    }

    @Test func typedRecipesHonorGlobalReplacements() throws {
        let base = try #require(TWStyle.defaultStyle(for: "button-primary"))
        let rules = TWGlobalRules(named: ["button-primary": TWStyle(base, .radius(22), .minH(48))])
        #expect(resolve(.primaryButton, rules: rules).radius == 22)
        #expect(resolve(.primaryButton, rules: rules).minimumHeight == 48)
        #expect(resolve(TWStyle(.primaryButton, .radius(7)), rules: rules).radius == 7)
    }

    @Test func customColorTokensWorkInStrings() throws {
        let brand = TWColor("brand")
        let theme = TWTheme(colors: [brand: TWAdaptiveColor(light: .purple, dark: .orange)])
        let parsed = try TWStyle.parse("bg-brand text-primary-foreground", theme: theme)
        #expect(resolve(parsed, theme: theme).background == .purple)
    }

    @Test func unknownClassesAndVariantsFailValidation() {
        for classes in ["px-nope", "opacity-101", "p--2", "text-typo", "p-NaN", "w-infinity", "p-2..0"] {
            #expect(throws: (any Error).self) { try TWStyle.parse(classes) }
        }
        #expect(throws: TWClassError.unknownVariant("dark")) { try TWStyle.parse("dark:bg-primary") }
    }

    @Test func cyclicNamedRulesFailValidation() {
        let rules = TWGlobalRules(named: ["a": .classes("b"), "b": .classes("a")])
        #expect(throws: TWClassError.recursiveClass("a")) { try TWStyle.parse("a", rules: rules) }
    }
}
