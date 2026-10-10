import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Utility resolution")
struct StyleResolverTests {
    private func resolve(_ style: TWStyle, theme: TWTheme = .standard, state: TWState = .init()) -> TWResolvedStyle {
        TWStyleResolver.resolve(style, theme: theme, scheme: .light, state: state)
    }

    @Test func directionalPaddingOverridesOnlyItsEdges() {
        let result = resolve(TWStyle(.p(4), .px(6), .pt(1), .pe(3)))
        #expect(result.padding.top == 4)
        #expect(result.padding.bottom == 16)
        #expect(result.padding.leading == 24)
        #expect(result.padding.trailing == 12)
    }

    @Test func localValuesOverrideNamedRecipes() {
        let result = resolve(TWStyle(.card, .p(8), .radius(20)))
        #expect(result.padding.top == 32)
        #expect(result.radius == 20)
        #expect(result.borderWidth == 1)
    }

    @Test func themeScaleResolvesLateButRawPointsRemainFixed() {
        let theme = TWTheme(spacingUnit: 5)
        let result = resolve(TWStyle(.p(4), .px(3), .pb(0)), theme: theme)
        #expect(result.padding.top == 20)
        #expect(result.padding.leading == 15)
        #expect(result.padding.bottom == 0)
        let raw = resolve(.paddingPoints(7), theme: theme)
        #expect(raw.padding.trailing == 7)
    }

    @Test func foregroundInheritanceDependsOnlyOnTheDeclaredRules() throws {
        #expect(resolve("p-2 bg-background text-lg font-semibold").inheritsForeground)
        let hovered = TWState(isHovered: true, isFocused: true)
        for classes in ["text-primary", "hover:text-primary", "focus:text-primary", "group-hover:text-primary"] {
            // A variant that is inactive now still keeps the foreground modifier installed.
            #expect(!resolve(.classes(classes)).inheritsForeground, "\(classes)")
            #expect(!resolve(.classes(classes), state: hovered).inheritsForeground, "\(classes)")
        }
        let rules = TWGlobalRules(named: ["accent-label": .classes("hover:text-primary")])
        let named = TWStyleResolver.resolve("accent-label", theme: .standard, scheme: .light, state: TWState(), globalRules: rules)
        #expect(!named.inheritsForeground)
    }

    @Test func buttonClassesSelectOneNativeStyle() throws {
        #expect(resolve("button-primary").buttonBezel == .prominent)
        #expect(resolve("button-outline").buttonBezel == .bordered)
        #expect(resolve("button-ghost").buttonBezel == .borderless)
        #expect(resolve("button-link").buttonBezel == .link)
        #expect(resolve("glass").buttonBezel == .bordered)
        #expect(resolve("glass-prominent").buttonBezel == .prominent)
        #expect(resolve("button-outline bezel-prominent").buttonBezel == .prominent)
        // Rows and menu items keep a plain button.
        #expect(resolve("dropdown-item").buttonBezel == nil)
        #expect(resolve("px-2 bg-muted").buttonBezel == nil)
        // States never switch the native style type, so the button keeps its structure.
        let pressed = TWState(isHovered: true, isFocused: true, isPressed: true)
        #expect(resolve("hover:bezel-prominent", state: pressed).buttonBezel == nil)
        #expect(resolve("button-outline pressed:bezel-prominent", state: pressed).buttonBezel == .bordered)
    }

    @Test func tintAndControlSizeClassesResolve() throws {
        #expect(resolve("tint-destructive").glassTint == TWTheme.standard.color(.destructive, scheme: .light))
        #expect(resolve("tint-[#ff0000]").glassTint != nil)
        #expect(resolve("control-sm").controlSize == .small)
        #expect(resolve("control-xl").controlSize == .extraLarge)
        #expect(throws: (any Error).self) { try TWStyle.parse("tint-unknown") }
        #expect(throws: (any Error).self) { try TWStyle.parse("control-huge") }
    }

    @Test func statesOverrideBaseRegardlessOfDeclarationOrder() {
        let style = TWStyle(.pressed(.opacity(0.5)), .opacity(1))
        #expect(resolve(style).opacity == 1)
        #expect(resolve(style, state: .init(isPressed: true)).opacity == 0.5)
    }

    @Test func disabledWinsOverPressAndHover() {
        let style = TWStyle(.disabled(.opacity(0.2)), .pressed(.opacity(0.4)), .hover(.opacity(0.6)))
        let state = TWState(isHovered: true, isPressed: true, isDisabled: true)
        #expect(resolve(style, state: state).opacity == 0.2)
    }

    @Test func activeStateChangesOnlyItsProperties() {
        let style = TWStyle(.p(4), .opacity(1), .focus(.rounded(.lg)), .pressed(.opacity(0.5)))
        let result = resolve(style, state: .init(isFocused: true, isPressed: true))
        #expect(result.padding.top == 16)
        #expect(result.radius == TWTheme.standard.radius(.lg))
        #expect(result.opacity == 0.5)
    }

    @Test func nestedConditionsRequireEveryStateAndWinBySpecificity() {
        let style = TWStyle(.disabled(.hover(.opacity(0.1))), .disabled(.opacity(0.3)))
        #expect(resolve(style, state: .init(isDisabled: true)).opacity == 0.3)
        #expect(resolve(style, state: .init(isHovered: true)).opacity == 1)
        #expect(resolve(style, state: .init(isHovered: true, isDisabled: true)).opacity == 0.1)
    }

    @Test func laterOverridesWithinTheSameStateWin() {
        let style = TWStyle(.primaryButton, .pressed(.opacity(0.7)))
        #expect(resolve(style, state: .init(isPressed: true)).opacity == 0.7)
    }

    @Test func widthUtilitiesReplaceOneAnother() {
        let fixed = resolve(TWStyle(.fullWidth, .w(100)))
        #expect(fixed.width == 100)
        #expect(!fixed.expandsWidth)
        let expanding = resolve(TWStyle(.w(100), .fullWidth))
        #expect(expanding.width == nil)
        #expect(expanding.expandsWidth)
    }

    @Test func themeOverridesKeepUnspecifiedDefaults() {
        let theme = TWTheme(radii: [.lg: 20])
        #expect(theme.radius(.lg) == 20)
        #expect(theme.radius(.md) == TWTheme.standard.radius(.md))
        #expect(theme.colors[.surface] != nil)
        #expect(theme.typography[.lg] != nil)
    }

    @Test func emptyStyleDoesNotSetInheritedProperties() {
        let result = resolve(TWStyle())
        #expect(result.font == nil)
        #expect(result.weight == nil)
        #expect(result.foreground == nil)
        #expect(result.background == nil)
        #expect(result.width == nil)
        #expect(result.shadow == nil)
        #expect(result.opacity == 1)
    }
}
