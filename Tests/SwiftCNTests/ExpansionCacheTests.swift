import Dispatch
import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Class expansion cache")
struct ExpansionCacheTests {
    @Test func preparedSurfacesKeepCascadeOrderAcrossStatesAndComposition() throws {
        let styles: [TWStyle] = [
            "hover:p-4 p-2 disabled:p-1",
            TWStyle(.classes("hover:p-4"), .classes("p-2 disabled:p-1")),
            .classes(cn("hover:p-4", "p-2", "disabled:p-1"))
        ]
        for style in styles {
            let ordered = try TWClassParser.ordered(style, rules: TWGlobalRules(), theme: .standard, target: .view)
            #expect(ordered.map(\.priority) == ordered.map(\.priority).sorted())
            #expect(resolve(style).padding.top == 8)
            #expect(resolve(style, state: .init(isHovered: true)).padding.top == 16)
            #expect(resolve(style, state: .init(isHovered: true, isDisabled: true)).padding.top == 4)
        }
        // Typed defaults bypass the literal cache and retain their own precedence.
        #expect(resolve(TWStyle(.p(6), styles[0])).padding.top == 8)
    }

    @Test func defaultValuesShareTheStandardRevision() {
        #expect(TWGlobalRules().revision == TWRevision.standard)
        #expect(TWTheme().revision == TWRevision.standard)
        #expect(TWTheme.standard.revision == TWRevision.standard)
        #expect(TWGlobalRules(named: ["chip": "p-2"]).revision != TWRevision.standard)
        #expect(TWTheme(spacingUnit: 8).revision != TWRevision.standard)
    }

    @Test func copiesShareARevisionAndMutationsReplaceIt() {
        var rules = TWGlobalRules(named: ["chip": "p-2"])
        let copy = rules
        #expect(copy.revision == rules.revision)
        rules.named["chip"] = "p-4"
        #expect(copy.revision != rules.revision)

        var theme = TWTheme.standard
        theme.colors[TWColor("brand")] = TWAdaptiveColor(.red)
        #expect(theme.revision != TWTheme.standard.revision)
    }

    @Test func repeatedResolutionMatchesFirstResolution() {
        let style: TWStyle = "p-4 rounded-lg hover:bg-primary disabled:opacity-50"
        let hovered = TWState(isHovered: true)
        let first = resolve(style, state: hovered)
        let second = resolve(style, state: hovered)
        #expect(first.padding == second.padding)
        #expect(first.radius == second.radius)
        #expect(second.background != nil)
        #expect(resolve(style).background == nil)
        #expect(resolve(style, state: TWState(isDisabled: true)).opacity == 0.5)
    }

    @Test func changedNamedClassesInvalidateCachedTokens() {
        var rules = TWGlobalRules(named: ["cache-chip": "p-2"])
        #expect(resolve("cache-chip", rules: rules).padding.top == 8)
        rules.named["cache-chip"] = "p-4"
        #expect(resolve("cache-chip", rules: rules).padding.top == 16)
    }

    @Test func changedThemeColorsInvalidateCachedTokens() throws {
        var theme = TWTheme.standard
        #expect(throws: (any Error).self) { try TWStyle.parse("bg-cache-brand", theme: theme) }
        theme.colors[TWColor("cache-brand")] = TWAdaptiveColor(.red)
        _ = try TWStyle.parse("bg-cache-brand", theme: theme)
        #expect(throws: (any Error).self) { try TWStyle.parse("bg-cache-brand", theme: .standard) }
    }

    @Test func outerConditionsDoNotLeakIntoCachedTokens() {
        let plain = resolve("p-4")
        #expect(plain.padding.top == 16)
        let conditioned = TWStyle.classes("p-4").conditioned(on: .hovered)
        #expect(resolve(conditioned).padding.top == 0)
        #expect(resolve(conditioned, state: TWState(isHovered: true)).padding.top == 16)
        #expect(resolve("p-4").padding.top == 16)
    }

    @Test func typedArgumentsResolveFreshEachTime() {
        for width in [CGFloat(120), 240, 360] {
            let classes: TWClasses = "p-4 w-[\(width)]"
            #expect(resolve(.classes(classes)).width == width)
        }
    }

    @Test func customUtilitiesRefreshAfterThemeMutation() {
        let rules = TWGlobalRules(utilities: ["cache-gap": TWUtility { argument, theme in
            guard let units = argument.number else { return nil }
            return .paddingPoints(theme.space(CGFloat(units)))
        }])
        var theme = TWTheme.standard
        #expect(resolve("cache-gap-[2]", rules: rules, theme: theme).padding.top == 8)
        theme.spacingUnit = 7
        #expect(resolve("cache-gap-[2]", rules: rules, theme: theme).padding.top == 14)
    }

    @Test func cachedNativeClassesStillValidateTheirSourceTarget() throws {
        let rules = TWGlobalRules(modifiers: ["cache-bold": .text { text, active in active ? text.bold() : text }])
        _ = try TWStyle.parse("cache-bold", rules: rules, target: .text)
        #expect(throws: TWClassError.unsupportedTarget("cache-bold", expected: .text)) {
            try TWStyle.parse("cache-bold", rules: rules, target: .view)
        }
    }

    @Test func concurrentResolutionsKeepTheirOwnState() {
        DispatchQueue.concurrentPerform(iterations: 1000) { index in
            let state = TWState(isHovered: index.isMultiple(of: 2))
            let result = TWStyleResolver.resolve("hover:p-4 p-2", theme: .standard, scheme: .light, state: state)
            #expect(result.padding.top == (state.isHovered ? 16 : 8))
        }
    }

    @Test func cacheStaysWithinCapacity() {
        let cache = TWExpansionCache(capacity: 2)
        for token in ["p-1", "p-2", "p-3"] {
            cache.insert([], for: .init(token: token, target: .view, rules: 0, theme: 0))
        }
        #expect(cache.count <= 2)
        #expect(cache.rules(for: .init(token: "p-3", target: .view, rules: 0, theme: 0)) != nil)
    }

    private func resolve(_ style: TWStyle, rules: TWGlobalRules = TWGlobalRules(),
                         theme: TWTheme = .standard, state: TWState = TWState()) -> TWResolvedStyle {
        TWStyleResolver.resolve(style, theme: theme, scheme: .light, state: state, globalRules: rules)
    }
}
