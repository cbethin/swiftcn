import SwiftUI
import Testing
@_spi(Tooling) @testable import SwiftCN

@Suite("Inherited customization")
struct CustomizationTests {
    private func resolve(_ style: TWStyle, rules: TWGlobalRules = TWGlobalRules(),
                         theme: TWTheme = .standard, size: ControlSize = .regular,
                         state: TWState = TWState()) -> TWResolvedStyle {
        TWStyleResolver.resolve(style, theme: theme, scheme: .light, state: state,
                                globalRules: rules, controlSize: size)
    }

    @Test func nestedOverridesKeepInheritedPropertiesAndInstancePrecedence() {
        let app = TWRuleOverrides(named: ["button-primary": "px-7 hover:opacity-70"])
        let scope = TWRuleOverrides(named: ["button-primary": "rounded-lg py-1"])
        let rules = scope.applying(to: app.applying(to: TWGlobalRules()))
        let inherited = resolve("button-primary", rules: rules)
        #expect(inherited.padding.leading == 28 && inherited.padding.top == 4)
        #expect(inherited.radius == 12 && inherited.minimumHeight == 36)
        #expect(inherited.background != nil && inherited.foreground != nil)
        let local = resolve("button-primary rounded-none hover:opacity-90", rules: rules,
                            state: TWState(isHovered: true))
        #expect(local.radius == 0 && local.opacity == 0.9)
        #expect(resolve("button-primary", rules: rules, state: .init(isDisabled: true)).opacity == 0.5)
    }

    @Test func replacementDropsOnlyTheChosenRecipeAndPreservesRegistries() {
        var parent = TWClassCatalog.componentRules
        parent.animations["snappy"] = TWAnimation.none
        parent.named["brand"] = "rounded-xl"
        parent.animations.removeValue(forKey: "smooth")
        let patch = TWRuleOverrides(named: ["card": "p-3"], replacing: ["button-primary": "text-destructive"])
        let result = patch.applying(to: parent)
        #expect(result.modifiers["cn-tint"] != nil)
        #expect(result.named["brand"] != nil)
        #expect(result.animations["smooth"] == nil, "Unrelated overrides must preserve an intentionally removed preset.")
        #expect(result.animations["snappy"]?.resolve(duration: 0.2, delay: 0) == nil)
        let replaced = resolve("button-primary", rules: result)
        #expect(replaced.background == nil && replaced.minimumHeight == nil)
        #expect(replaced.padding.leading == 0 && replaced.foreground != nil)
        #expect(resolve("card", rules: result).padding.top == 12)
    }

    @Test func cacheTracksRegistryChangesWithoutStoringOldGeneralDefaults() {
        let patch = TWRuleOverrides(named: ["card": "rounded-xl"])
        var parent = TWGlobalRules(view: .px(1))
        let first = patch.applying(to: parent)
        #expect(first.revision == patch.applying(to: parent).revision)
        parent.view = .px(7)
        let second = patch.applying(to: parent)
        #expect(first.revision == second.revision)
        #expect(resolve(second.view).padding.leading == 28)
        parent.named["card"] = "bg-muted"
        #expect(patch.applying(to: parent).revision != first.revision)
        var changed = patch
        changed.named["card"] = "rounded-sm"
        #expect(changed.applying(to: parent).revision != patch.applying(to: parent).revision)
    }

    @Test func selectionVariantsKeepStateAndSpecificityPrecedence() throws {
        let style = try TWStyle.parse("bg-muted selected:bg-primary hover:bg-surface selected:hover:bg-accent disabled:opacity-50")
        #expect(resolve(style).background == TWTheme.standard.color(.muted, scheme: .light))
        #expect(resolve(style, state: .init(isSelected: true)).background == TWTheme.standard.color(.primary, scheme: .light))
        let active = resolve(style, state: .init(isSelected: true, isHovered: true, isDisabled: true))
        #expect(active.background == TWTheme.standard.color(.accent, scheme: .light))
        #expect(active.opacity == 0.5)
        let typed = resolve(.selected(.opacity(0.7)), state: .init(isSelected: true))
        #expect(typed.opacity == 0.7)
        let group = TWStyleResolver.resolve("group-selected/choice:opacity-70", theme: .standard, scheme: .light,
            state: TWState(), groupStates: ["choice": .init(isSelected: true)])
        #expect(group.opacity == 0.7)
    }

    @Test func controlMetricsFollowEnvironmentClassesAndLocalOverrides() {
        var theme = TWTheme.standard
        theme.controls.small.minHeight = 34
        theme.controls.small.radius = 11
        theme.controls.small.horizontalPadding = 9
        let small = resolve("button-primary", theme: theme, size: .small)
        #expect(small.minimumHeight == 34 && small.radius == 11 && small.padding.leading == 9)
        let explicit = resolve("button-primary control-lg", theme: theme, size: .small)
        #expect(explicit.minimumHeight == 40 && explicit.padding.leading == 24)
        let local = resolve("button-primary rounded-none px-2 min-h-[48]", theme: theme, size: .small)
        #expect(local.radius == 0 && local.minimumHeight == 48 && local.padding.leading == 8)
        let icon = resolve("button-ghost control-icon", theme: theme, size: .small)
        #expect(icon.minimumWidth == 32 && icon.padding.leading == 0)
    }
}
