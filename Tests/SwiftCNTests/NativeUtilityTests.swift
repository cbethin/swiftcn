import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Native modifier registration and composition")
struct NativeUtilityTests {
    private var registry: TWGlobalRules {
        TWGlobalRules(named: ["lifted": "tilt-[8]"], modifiers: [
            "glass": .view(order: 20) { view, active in view.background(active ? Color.blue : .clear) },
            "tilt": .argument(default: "0", order: 10, conflictKey: "angle") { argument, _ in
                argument.degrees.map { NativeTestTilt(degrees: $0) }
            },
            "lean": .argument(default: "0", order: 10, conflictKey: "angle") { argument, _ in
                argument.degrees.map { NativeTestTilt(degrees: $0 * 2) }
            }
        ])
    }

    private func resolve(_ classes: TWClasses, state: TWState = TWState(),
                         groupStates: [String: TWState] = [:], rules: TWGlobalRules? = nil) throws -> TWResolvedStyle {
        let rules = rules ?? registry
        let style = try TWStyle.parse(classes, rules: rules)
        return TWStyleResolver.resolve(style, theme: .standard, scheme: .light,
            state: state, globalRules: rules, groupStates: groupStates)
    }

    @Test func compositionKeepsOrderVariantsAndBracketArguments() {
        #expect(cn(" card ", nil, "", "tilt-[8]", "hover:tilt-[12]", "p-3") == "card tilt-[8] hover:tilt-[12] p-3")
        #expect(cn(["card", nil, "glass"]) == "card glass")
        let selected = true
        let classes = cn {
            "card"
            ["glass", nil]
            if selected { "border-primary" } else { "border" }
            for angle in [0, 8] { "tilt-[\(angle)]" }
        }
        #expect(classes == cn("card glass border-primary", "tilt-[\(0)]", "tilt-[\(8)]"))
        let shared = ["glass", "p-4"]
        #expect(cn { shared; "tilt-[0]" } == "glass p-4 tilt-[0]")
    }

    @Test func phasesSortBeforeLocalOrderAndTargetValidationExpandsRecipes() throws {
        let rules = TWGlobalRules(named: ["photo": "resize"], modifiers: [
            "outer": .view(phase: .effects, order: -100) { view, _ in view },
            "inner": .view(phase: .content, order: 100) { view, _ in view },
            "resize": .image { image, active in active ? image.resizable() : image }
        ])
        let resolved = TWStyleResolver.resolve("inner outer", theme: .standard, scheme: .light,
            state: .init(), globalRules: rules)
        #expect(resolved.nativeSlots.map(\.name) == ["resize", "inner", "outer"])
        _ = try TWStyle.parse("photo", rules: rules, target: .image)
        #expect(throws: TWClassError.unsupportedTarget("resize", expected: .image)) {
            try TWStyle.parse("photo", rules: rules, target: .text)
        }
    }

    @Test func preparedSlotOrderTracksRegistryEditsWithoutLeakingSelections() throws {
        var rules = registry
        let inherited = rules
        rules.modifiers["first"] = .view(phase: .content) { view, _ in view }
        rules.modifiers["glass"] = .view(order: -10) { view, _ in view }
        #expect(try resolve("glass", rules: rules).nativeSlots.map(\.name) == ["first", "glass", "lean", "tilt"])
        #expect(try resolve("", rules: rules).nativeSlots.allSatisfy { !$0.active })
        #expect(try resolve("", rules: inherited).nativeSlots.map(\.name) == ["lean", "tilt", "glass"])
        rules.modifiers.removeValue(forKey: "first")
        #expect(try resolve("", rules: rules).nativeSlots.map(\.name) == ["glass", "lean", "tilt"])
    }

    @Test func aliasesAndArgumentsSelectOneStableOrderedSlot() throws {
        let resolved = try resolve(cn("lifted glass", "tilt-[12deg]"))
        #expect(resolved.nativeSlots.map(\.name) == ["lean", "tilt", "glass"])
        #expect(resolved.nativeSlots.filter(\.active).map(\.name) == ["tilt", "glass"])
        #expect(resolved.nativeSlots[1].argument?.degrees == 12)
        #expect(try resolve("").nativeSlots.map(\.name) == resolved.nativeSlots.map(\.name))
        #expect(try resolve("").nativeSlots.allSatisfy { !$0.active })
    }

    @Test func conflictKeysAndStatePrecedenceMatchBuiltInClasses() throws {
        let classes: TWClasses = "hover:tilt-[14] tilt-[4] lean-[6] disabled:tilt-[0]"
        #expect(try resolve(classes).nativeSlots.first(where: \.active)?.name == "lean")
        let hovered = try resolve(classes, state: .init(isHovered: true))
        #expect(hovered.nativeSlots.first(where: \.active)?.name == "tilt")
        #expect(hovered.nativeSlots.first(where: \.active)?.argument?.degrees == 14)
        let disabled = try resolve(classes, state: .init(isHovered: true, isDisabled: true))
        #expect(disabled.nativeSlots.first(where: \.active)?.argument?.degrees == 0)
        let grouped = try resolve("tilt-[0] group-hover/hero:tilt-[9]", groupStates: ["hero": .init(isHovered: true)])
        #expect(grouped.nativeSlots.first(where: \.active)?.argument?.degrees == 9)
    }

    @Test(arguments: ["tilt", "tilt-[nope]", "tilt-[50%]", "glass-[1]", "focus:missing", "tilt-[]"])
    func invalidTagsAndArgumentsFailStrictParsing(_ classes: String) {
        #expect(throws: (any Error).self) { try TWStyle.parse(classes, rules: registry) }
    }

    @Test func invalidInactiveArgumentsFailBeforeRendering() {
        let rules = TWGlobalRules(modifiers: ["tilt": .argument(default: "invalid") { argument, _ in
            argument.degrees.map { NativeTestTilt(degrees: $0) }
        }])
        #expect(throws: TWClassError.unknownClass("tilt-[5]")) { try TWStyle.parse("tilt-[5]", rules: rules) }
    }

    @Test func invalidSurfacesDisableAllNativeSlotsAndGlobalDefaults() {
        var rules = registry
        rules.view = "p-4 glass"
        let result = TWStyleResolver.resolve(TWStyle(rules.view, "tilt-[5] invalid"),
            theme: .standard, scheme: .light, state: TWState(), globalRules: rules)
        #expect(result.padding.top == 0)
        #expect(result.nativeSlots.count == 3)
        #expect(result.nativeSlots.allSatisfy { !$0.active })
    }

    @Test func namedClassesWinAndParsedReferencesRequireARegistration() throws {
        var rules = registry
        rules.named["tilt-[7]"] = .opacity(0.7)
        #expect(try resolve("tilt-[7]", rules: rules).opacity == 0.7)
        #expect(try resolve("tilt-[7]", rules: rules).nativeSlots.allSatisfy { !$0.active })
        let parsed = try TWStyle.parse("tilt-[8]", rules: registry)
        #expect(throws: TWClassError.unknownClass("tilt")) { try TWClassParser.expand(parsed, rules: .init(), theme: .standard) }
    }
}

private struct NativeTestTilt: ViewModifier {
    let degrees: Double
    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 1, z: 0))
    }
}
