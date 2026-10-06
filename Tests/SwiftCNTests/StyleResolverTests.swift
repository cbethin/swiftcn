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
