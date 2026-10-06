import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Arbitrary arguments")
struct ArgumentTests {
    private func resolve(_ classes: String, theme: TWTheme = .standard, rules: TWGlobalRules = TWGlobalRules(),
                         state: TWState = TWState(), scheme: ColorScheme = .light) throws -> TWResolvedStyle {
        let parsed = try TWStyle.parse(classes, rules: rules, theme: theme)
        return TWStyleResolver.resolve(parsed, theme: theme, scheme: scheme, state: state, globalRules: rules)
    }

    @Test func nativePointsDoNotUseTheThemeScaleAndComposeByEdge() throws {
        let style = try resolve("w-[240px] h-[80pt] min-w-[40] max-w-[300] min-h-[20] max-h-[90] p-[13] px-2 pt-[3.5]",
                                theme: TWTheme(spacingUnit: 5))
        #expect(style.width == 240 && style.height == 80)
        #expect(style.minimumWidth == 40 && style.maximumWidth == 300)
        #expect(style.minimumHeight == 20 && style.maximumHeight == 90)
        #expect(style.padding.top == 3.5 && style.padding.bottom == 13)
        #expect(style.padding.leading == 10 && style.padding.trailing == 10)
        #expect(try resolve("size-[44] w-[52]").height == 44)
        #expect(try resolve("size-[44] w-[52]").width == 52)
    }

    @Test func argumentsComposeWithNativeTypographyTimingAndTransforms() throws {
        let style = try resolve("text-[length:18px] font-semibold tracking-[-0.5] line-spacing-[4] text-center line-clamp-[2] " +
                                "rounded-[13] border-[1.5] opacity-[0.7] offset-[12,-4pt] scale-[1.1,0.9] rotate-[0.5rad] blur-[2] " +
                                "animate-smooth duration-[0.4s] delay-[75ms]")
        #expect(style.font == .system(size: 18))
        #expect(style.weight == .semibold && style.tracking == -0.5)
        #expect(style.lineSpacing == 4 && style.textAlignment == .center && style.lineLimit == .some(2))
        #expect(style.radius == 13 && style.borderWidth == 1.5 && style.opacity == 0.7)
        #expect(style.offset == CGSize(width: 12, height: -4))
        #expect(style.scale == CGSize(width: 1.1, height: 0.9))
        #expect(abs(style.rotation - 90 / .pi) < 0.0001 && style.blur == 2)
        #expect(style.motion.duration == 0.4 && style.motion.delay == 0.075)
        #expect(try resolve("line-clamp-2 line-clamp-none").lineLimit == .some(nil))
    }

    @Test func colorsPreserveAdaptiveTokensAndDecodeCSSHexOrder() throws {
        let theme = TWTheme(colors: [TWColor("brand"): .init(light: .red, dark: .blue)])
        #expect(try resolve("text-[color:brand] bg-[brand]", theme: theme, scheme: .dark).foreground == .blue)
        #expect(try resolve("text-[color:brand] bg-[brand]", theme: theme, scheme: .dark).background == .blue)
        #expect(try resolve("text-[#f008] border-[color:#ff000088] bg-[#ff0000] border-[2]").foreground == TWArgument("#ff000088").hexColor)
        #expect(try resolve("bg-[#f00]").background == TWArgument("#ff0000").hexColor)
        #expect(try resolve("text-[color:#123456]").font == nil)
    }

    @Test func customUtilitiesResolveLateAndRetainConditions() throws {
        var rules = TWGlobalRules(utilities: ["tilt": TWUtility { argument, _ in
            guard let degrees = argument.degrees else { return nil }
            return .rotate(degrees)
        }])
        let style: TWStyle = "rotate-[0] hover:tilt-[12deg]"
        func lateResolve(_ rules: TWGlobalRules, hovered: Bool) -> TWResolvedStyle {
            TWStyleResolver.resolve(style, theme: .standard, scheme: .light,
                                    state: .init(isHovered: hovered), globalRules: rules)
        }
        #expect(lateResolve(rules, hovered: false).rotation == 0)
        #expect(lateResolve(rules, hovered: true).rotation == 12)
        rules.utilities["tilt"] = TWUtility { argument, _ in
            guard let degrees = argument.degrees else { return nil }
            return TWStyle(.rotate(degrees * 2), "rounded-[12]")
        }
        #expect(lateResolve(rules, hovered: true).rotation == 24)
        #expect(lateResolve(rules, hovered: true).radius == 12)
        #expect(throws: (any Error).self) { try TWStyle.parse("tilt-[nope]", rules: rules) }
    }

    @Test func colonsUnderscoresAndEscapedUnderscoresReachTheFactory() throws {
        let rules = TWGlobalRules(utilities: ["label": TWUtility { argument, _ in
            switch argument.rawValue {
            case "label:Hello world": return .opacity(0.4)
            case "literal_name": return .opacity(0.6)
            default: return nil
            }
        }])
        #expect(try resolve("hover:label-[label:Hello_world]", rules: rules, state: .init(isHovered: true)).opacity == 0.4)
        #expect(try resolve("label-[literal\\_name]", rules: rules).opacity == 0.6)
        let scoped = try TWStyle.parse("group-hover/hero:label-[label:Hello_world]", rules: rules)
        #expect(TWStyleResolver.resolve(scoped, theme: .standard, scheme: .light, state: TWState(),
            groupStates: ["hero": .init(isHovered: true)]).opacity == 0.4)
    }

    @Test func factoriesReceiveTheCurrentThemeAndComposeThroughAliases() throws {
        let rules = TWGlobalRules(named: ["tile": "inset-[3] rounded-[12]"], utilities: [
            "inset": TWUtility { argument, theme in
                guard let units = argument.number, units >= 0,
                      theme.space(CGFloat(units)).isFinite else { return nil }
                return .paddingPoints(theme.space(CGFloat(units)))
            }
        ])
        #expect(try resolve("tile px-[2]", theme: TWTheme(spacingUnit: 5), rules: rules).padding.top == 15)
        #expect(try resolve("tile px-[2]", theme: TWTheme(spacingUnit: 5), rules: rules).padding.leading == 2)
        #expect(try resolve("tile", theme: TWTheme(spacingUnit: 6), rules: rules).padding.top == 18)
    }

    @Test(arguments: ["w-[]", "w-[2", "w-[2]]", "w-[2][3]", "w-[2]suffix", "w-[[2]]", "w-[-1]", "w-[50%]", "w-[2rem]",
                      "text-[0]", "text-[color:18]", "text-[size:#fff]", "bg-[#ggg]", "bg-[#fffff]", "p-[NaN]",
                      "h-[infinity]", "rotate-[1e309]", "offset-[1]", "offset-[1,]", "offset-[1,2,3]", "scale-[-1]",
                      "opacity-[1.1]", "duration-[-1s]", "delay-[NaNs]", "line-clamp-[0]", "line-clamp-[2.5]", "blur-[-2]"])
    func invalidArgumentsFailWithoutCallingNativePreconditions(_ classes: String) {
        #expect(throws: (any Error).self) { try TWStyle.parse(classes) }
    }

    @Test func customCyclesFailAndExactNamedRulesTakePrecedence() throws {
        let cycle = TWGlobalRules(utilities: ["loop": TWUtility { _, _ in .classes("loop-[1]") }])
        #expect(throws: TWClassError.recursiveClass("loop-[1]")) { try TWStyle.parse("loop-[1]", rules: cycle) }
        let rules = TWGlobalRules(named: ["w-[42]": .w(84)], utilities: ["w": TWUtility { _, _ in .w(21) }])
        #expect(try resolve("w-[42]", rules: rules).width == 84)
        #expect(try resolve("w-[43]", rules: rules).width == 21)
    }
}
