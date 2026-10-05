import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Native animation rules")
struct AnimationTests {
    private func motion(_ classes: String, rules: TWGlobalRules = TWGlobalRules(),
                        state: TWState = TWState()) throws -> TWResolvedMotion {
        let style = try TWStyle.parse(classes, rules: rules)
        return TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: state).motion
    }

    @Test func presetsMapToNativeAnimations() throws {
        let expected: [String: Animation] = [
            "linear": .linear(duration: 0.2), "ease-in": .easeIn(duration: 0.2),
            "ease-out": .easeOut(duration: 0.2), "ease-in-out": .easeInOut(duration: 0.2),
            "spring": .spring(duration: 0.2), "smooth": .smooth(duration: 0.2),
            "snappy": .snappy(duration: 0.2), "bouncy": .bouncy(duration: 0.2)
        ]
        for (name, animation) in expected {
            var transaction = Transaction()
            try motion("duration-200 animate-\(name) delay-100").update(&transaction, reduceMotion: false)
            #expect(transaction.animation == animation.delay(0.1))
        }
    }

    @Test func defaultsAndTimingOverridesAreIndependentOfPresetOrder() throws {
        #expect(try motion("animate-spring").duration == 0.3)
        let result = try motion("duration-400 delay-90 animate-ease-out duration-125.5 delay-0")
        #expect(result.duration == 0.1255)
        #expect(result.delay == 0)
        for classes in ["duration--1", "delay-NaN", "duration-infinity", "duration-1..2", "animate-typo"] {
            #expect(throws: (any Error).self) { try TWStyle.parse(classes) }
        }
    }

    @Test func variantsUseExistingPrecedenceOnEntryAndExit() throws {
        let classes = "animate-ease-out duration-300 active:animate-spring active:duration-100 disabled:animate-none"
        var transaction = Transaction()
        try motion(classes, state: .init(isPressed: true)).update(&transaction, reduceMotion: false)
        #expect(transaction.animation == Animation.spring(duration: 0.1).delay(0))
        try motion(classes).update(&transaction, reduceMotion: false)
        #expect(transaction.animation == Animation.easeOut(duration: 0.3).delay(0))
        try motion(classes, state: .init(isPressed: true, isDisabled: true)).update(&transaction, reduceMotion: false)
        #expect(transaction.animation == nil)
    }

    @Test func customGlobalPresetsResolveLateAndHonorTiming() throws {
        var rules = TWGlobalRules(named: ["motion": "animate-settle duration-250"], animations: [
            "settle": TWAnimation { .spring(duration: $0, bounce: 0.15) }
        ])
        let style = TWStyle.classes("motion delay-50")
        var transaction = Transaction()
        TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: .init(), globalRules: rules)
            .motion.update(&transaction, reduceMotion: false)
        #expect(transaction.animation == Animation.spring(duration: 0.25, bounce: 0.15).delay(0.05))
        rules.animations["settle"] = TWAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8))
        TWStyleResolver.resolve(style, theme: .standard, scheme: .light, state: .init(), globalRules: rules)
            .motion.update(&transaction, reduceMotion: false)
        #expect(transaction.animation == Animation.interactiveSpring(response: 0.4, dampingFraction: 0.8).delay(0.05))
        // A partial custom registry retains the built-in presets.
        _ = try TWStyle.parse("animate-bouncy", rules: rules)
    }

    @Test func noPresetPreservesCallerTransactionAndTimingAloneDoesNotEnableMotion() throws {
        let native = Animation.linear(duration: 2)
        var transaction = Transaction(animation: native)
        try motion("p-4 duration-200 delay-100").update(&transaction, reduceMotion: true)
        #expect(transaction.animation == native)
        #expect(!transaction.disablesAnimations)
    }

    @Test func explicitNoneReduceMotionAndDisabledTransactionsRespectNativeSemantics() throws {
        var transaction = Transaction(animation: .linear(duration: 2))
        try motion("animate-none delay-100").update(&transaction, reduceMotion: false)
        #expect(transaction.animation == nil)
        try motion("animate-spring").update(&transaction, reduceMotion: true)
        #expect(transaction.animation == nil)
        transaction.disablesAnimations = true
        try motion("animate-spring").update(&transaction, reduceMotion: false)
        #expect(transaction.animation == nil)
        #expect(transaction.disablesAnimations)
        let explicit = Animation.linear(duration: 2)
        transaction.animation = explicit
        try motion("animate-none").update(&transaction, reduceMotion: false)
        #expect(transaction.animation == explicit)
    }

    @Test func typedAndStringAnimationUtilitiesResolveEqually() throws {
        let typed = TWStyleResolver.resolve(TWStyle(.animation(.snappy), .duration(0.2), .delay(0.05)),
            theme: .standard, scheme: .light, state: .init()).motion
        var a = Transaction(), b = Transaction()
        typed.update(&a, reduceMotion: false)
        try motion("animate-snappy duration-200 delay-50").update(&b, reduceMotion: false)
        #expect(a.animation == b.animation)
    }
}
