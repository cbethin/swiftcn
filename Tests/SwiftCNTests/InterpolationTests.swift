import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Typed class interpolation")
struct InterpolationTests {
    private func resolve(_ classes: TWClasses, rules: TWGlobalRules = .init(), state: TWState = .init()) throws -> TWResolvedStyle {
        let style = try TWStyle.parse(classes, rules: rules)
        return TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: state, globalRules: rules)
    }

    @Test func literalsAndCompositionRetainNativePayloads() throws {
        let payload = InterpolationPayload(amount: 0.4, label: "A payload, not a serialized class")
        let rules = TWGlobalRules(modifiers: ["payload": .value(default: InterpolationPayload(amount: 1, label: "")) { view, payload in
            view.opacity(payload.amount)
        }])
        let direct = try resolve("payload-[\(payload)]", rules: rules)
        #expect(direct.nativeSlots[0].argument?.value(as: InterpolationPayload.self) == payload)
        let shared: TWClasses = "payload-[\(payload)]"
        let composed = cn("p-3", shared, "hover:opacity-80")
        let array = cn(["p-3", shared, nil])
        let runtime = "rounded-md"
        let builder = cn {
            "p-3"
            runtime
            [shared, nil]
            if true { "bg-surface" }
        }
        for classes in [composed, array, builder, "p-3 \(shared)", "p-3 \([shared, nil])"] {
            let result = try resolve(classes, rules: rules)
            #expect(result.nativeSlots[0].argument?.value(as: InterpolationPayload.self) == payload)
            #expect(result.padding.top == 12)
        }
    }

    @Test func nativeBuiltInsUseValuesAndUnitsWithoutAStringRoundTrip() throws {
        let amount = 1e-10
        let width: CGFloat = 123.5
        let color = Color.blue
        let angle = Angle.radians(.pi / 4)
        let style = try resolve("w-[\(width)] p-[\(amount)] rotate-[\(angle)] bg-[\(color)] text-[color:\(Color.red)]")
        #expect(style.width == width)
        #expect(style.padding.top == CGFloat(amount))
        #expect(abs(style.rotation - 45) < 0.00001)
        #expect(style.background == color && style.foreground == .red)
        let units = try resolve("w-[\(12.5)pt] duration-[\(0.4)s] delay-[\(75)ms] rotate-[\(0.5)rad] line-clamp-[\(2)]")
        #expect(units.width == 12.5 && units.motion.duration == 0.4 && units.motion.delay == 0.075)
        #expect(abs(units.rotation - 90 / .pi) < 0.00001)
        #expect(units.lineLimit == .some(2))
        let tuple = try resolve("offset-[\(12),\(-4)] scale-[\(CGSize(width: 1.1, height: 0.9))]")
        #expect(tuple.offset == CGSize(width: 12, height: -4))
        #expect(tuple.scale == CGSize(width: 1.1, height: 0.9))
        #expect(try resolve("w-\(12)").width == 48)
    }

    @Test func nativeAnimationsAndStylesPreserveTheirValues() throws {
        let native = Animation.spring(response: 0.4, dampingFraction: 0.8)
        let result = try resolve("animate-[\(native)] duration-10 delay-50")
        var transaction = Transaction()
        result.motion.update(&transaction, reduceMotion: false)
        #expect(transaction.animation == native.delay(0.05))
        let preset = TWAnimation { .smooth(duration: $0) }
        let adjusted = try resolve("animate-[\(preset)] duration-250")
        adjusted.motion.update(&transaction, reduceMotion: false)
        #expect(transaction.animation == Animation.smooth(duration: 0.25).delay(0))
        let style: TWStyle = "bg-[\(Color.green)] animate-[\(native)]"
        #expect(TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: .init()).background == .green)
    }

    @Test func stringsInsideBracketsAreAtomicAndDoNotInjectClasses() throws {
        let label = "Hello_world ] hover:opacity-0 [ : / \\ end\nAnother line"
        let rules = TWGlobalRules(modifiers: ["label": .value(default: "") { view, label in
            view.accessibilityLabel(label)
        }])
        let result = try resolve("p-3 label-[\(label)]", rules: rules)
        #expect(result.opacity == 1)
        #expect(result.nativeSlots[0].argument?.value(as: String.self) == label)
        #expect(result.nativeSlots[0].argument?.rawValue == label)
        let fragment: String? = "opacity-80"
        let fragments = ["p-3", "rounded-md"]
        #expect(try resolve("\(fragments) \(fragment)").opacity == 0.8)
        let absent: String? = nil
        #expect(cn("card", "\(absent)") == "card")
    }

    @Test func typedArgumentsRespectVariantsThemesAndCustomFactories() throws {
        let payload = InterpolationPayload(amount: 0.4, label: "native")
        let rules = TWGlobalRules(named: ["recipe": "payload-[\(payload)]"], utilities: ["payload": TWUtility { argument, _ in
            guard let payload = argument.value(as: InterpolationPayload.self) else { return nil }
            return .opacity(payload.amount)
        }])
        #expect(try resolve("recipe", rules: rules).opacity == 0.4)
        #expect(try resolve("hover:payload-[\(payload)]", rules: rules).opacity == 1)
        #expect(try resolve("hover:payload-[\(payload)]", rules: rules, state: .init(isHovered: true)).opacity == 0.4)
        let shared: TWClasses = "shared-[\("cover")]/hero"
        #expect(try resolve(shared).sharedID == "cover")
    }

    @Test func runtimeStringAndStrictTypedValidationBothWork() throws {
        let runtime: String = "w-[12] bg-[#ff0000]"
        let parsed = try TWStyle.parse(runtime)
        #expect(TWStyleResolver.resolve(parsed, theme: .standard, scheme: .light, state: .init()).width == 12)
        let rules = TWGlobalRules(modifiers: ["tilt": .value(default: 0.0) { view, degrees in view.rotationEffect(.degrees(degrees)) }])
        #expect(try resolve("tilt-[8]", rules: rules).nativeSlots[0].argument?.value(as: Double.self) == 8)
        #expect(throws: (any Error).self) { try TWStyle.parse("tilt-[\(Color.blue)]", rules: rules) }
        #expect(throws: (any Error).self) { try TWStyle.parse("tilt-[\(Double.nan)]", rules: rules) }
        #expect(throws: (any Error).self) { try TWStyle.parse("w-[\(Double.infinity)]") }
        #expect(throws: (any Error).self) { try TWStyle.parse("\(Color.blue)") }
    }

    @Test func interpolationEqualityRetainsTypeAndValue() {
        let first: TWClasses = "w-[\(12.0)]"
        let same: TWClasses = "w-[\(12.0)]"
        let changed: TWClasses = "w-[\(13.0)]"
        #expect(first == same && first != changed)
        #expect(cn("card", "p-3") == "card p-3")
        #expect(cn("card", "p-3") == cn { "card"; "p-3" })
    }

    @Test func repeatedResolutionKeepsEachRowsCurrentPayload() throws {
        let rules = TWGlobalRules(modifiers: [
            "payload": .value(default: InterpolationPayload(amount: 0, label: "")) { view, payload in
                view.opacity(payload.amount)
            }
        ])
        let base: TWClasses = "p-3 rounded-md"
        for generation in 0..<3 {
            for row in 0..<1000 {
                let width = CGFloat(20 + row + generation)
                let payload = InterpolationPayload(amount: Double(row % 100) / 100,
                    label: "Generation \(generation), row \(row) ] opacity-0")
                let classes = cn(base, "w-[\(width)] payload-[\(payload)]")
                let result = try resolve(classes, rules: rules)
                #expect(result.width == width)
                #expect(result.opacity == 1)
                #expect(result.nativeSlots[0].argument?.value(as: InterpolationPayload.self) == payload)
                #expect(result.padding.top == 12)
            }
        }
    }
}

private struct InterpolationPayload: Sendable, Equatable, CustomStringConvertible {
    let amount: Double
    let label: String
    var description: String { "THIS_VALUE_WAS_FLATTENED" }
}
