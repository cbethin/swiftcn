import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Catalog behavior")
struct CatalogBehaviorTests {
    @Test func otpAcceptsPasteWithoutUnicodeDigitsOrOverflow() {
        #expect(CNInputOTP.normalize("Your code: 123 456 789", length: 6) == "123456")
        #expect(CNInputOTP.normalize("١２3a4", length: 6) == "34")
        #expect(CNInputOTP.normalize("1234", length: 0).isEmpty)
    }
    @Test func paginationIsBoundedAndHandlesEmptyOrInvalidPages() {
        #expect(CNPagination.visiblePages(page: 500_000, pageCount: 1_000_000) == [1, 499_998, 499_999, 500_000, 500_001, 500_002, 1_000_000])
        #expect(CNPagination.visiblePages(page: -10, pageCount: 3) == [1, 2, 3])
        #expect(CNPagination.visiblePages(page: 1, pageCount: 0).isEmpty)
        #expect(CNPagination.visiblePages(page: .max, pageCount: .max) == [1, Int.max - 2, Int.max - 1, Int.max])
    }
    @Test func commandSearchUsesDetailsAndKeepsDisabledMetadata() {
        let options = [CNOption("a", title: "Résumé", detail: "Design team"), CNOption("b", title: "Archived", isDisabled: true)]
        #expect(CNOptionSearch.filter(options, query: "  design  ").map(\.id) == ["a"])
        #expect(CNOptionSearch.filter(options, query: "archived").first?.isDisabled == true)
        #expect(CNOptionSearch.filter(options, query: "missing").isEmpty)
    }
    @Test func questionnaireRejectsMissingStaleDisabledAndWrongTypeAnswers() {
        let requiredText = CNQuestion("name", title: "Name")
        #expect(CNQuestionnaireValidation.error(for: requiredText, answer: nil) != nil)
        #expect(CNQuestionnaireValidation.error(for: requiredText, answer: .text(" \n ")) != nil)
        #expect(CNQuestionnaireValidation.error(for: requiredText, answer: .text("Charles")) == nil)
        #expect(CNQuestionnaireValidation.error(for: requiredText, answer: .choices([])) != nil)
        let choices = [CNOption("a", title: "A"), CNOption("b", title: "B"), CNOption("c", title: "C", isDisabled: true)]
        let single = CNQuestion("plan", title: "Plan", kind: .single(choices))
        #expect(CNQuestionnaireValidation.error(for: single, answer: .choices(["a"])) == nil)
        #expect(CNQuestionnaireValidation.error(for: single, answer: .choices(["a", "b"])) != nil)
        #expect(CNQuestionnaireValidation.error(for: single, answer: .choices(["c"])) != nil)
        #expect(CNQuestionnaireValidation.error(for: single, answer: .choices(["removed"])) != nil)
        let optional = CNQuestion("optional", title: "Optional", isRequired: false)
        #expect(CNQuestionnaireValidation.error(for: optional, answer: nil) == nil)
        let multiple = CNQuestion("features", title: "Features", kind: .multiple(choices))
        #expect(CNQuestionnaireValidation.error(for: multiple, answer: .choices(["a", "b"])) == nil)
    }
    @Test func focusingAnEmptyQuestionIsNotAnAnswerEdit() {
        #expect(!CNQuestionnaireValidation.changesText(nil, to: ""))
        #expect(!CNQuestionnaireValidation.changesText(.text(""), to: ""))
        #expect(!CNQuestionnaireValidation.changesText(.text("Charles"), to: "Charles"))
        #expect(CNQuestionnaireValidation.changesText(.text("Charles"), to: ""))
        #expect(CNQuestionnaireValidation.changesText(nil, to: "Charles"))
    }
    @Test func questionnaireNavigationRevalidatesEarlierAnswersAndDropsUnknownIDs() {
        let questions = [CNQuestion("name", title: "Name"), CNQuestion("optional", title: "Optional", isRequired: false)]
        #expect(CNQuestionnaireValidation.next(questions: [], answers: [:], activeIndex: 0) == .empty)
        #expect(CNQuestionnaireValidation.next(questions: questions, answers: ["name": .text("Charles")], activeIndex: 0) == .advance(index: 1))
        #expect(CNQuestionnaireValidation.next(questions: questions, answers: [:], activeIndex: 1) == .invalid(index: 0, message: "Answer this question to continue."))
        #expect(CNQuestionnaireValidation.next(questions: questions, answers: ["name": .text("Charles"), "removed": .text("Old")], activeIndex: 1) == .submit(["name": .text("Charles")]))
    }
    @Test func resizeBoundsRemainFinite() {
        #expect(CNResizable<Text, Text>.clamp(.nan, minimum: 0.15) == 0.5)
        #expect(CNResizable<Text, Text>.clamp(-5, minimum: 0.15) == 0.15)
        #expect(CNResizable<Text, Text>.clamp(5, minimum: 0.15) == 0.85)
    }
    @Test func resizeCoordinatesRespectAxisDirectionAndHandleWidth() {
        #expect(CNResizeDrag.position(CGPoint(x: 356, y: 806), axis: .horizontal,
            direction: .leftToRight, length: 1_000, handleExtent: 12) == 350)
        #expect(CNResizeDrag.position(CGPoint(x: 656, y: 806), axis: .horizontal,
            direction: .rightToLeft, length: 1_000, handleExtent: 12) == 350)
        #expect(CNResizeDrag.position(CGPoint(x: 356, y: 806), axis: .vertical,
            direction: .rightToLeft, length: 1_000, handleExtent: 12) == 800)
        #expect(CNResizeDrag.position(CGPoint(x: 372, y: 822), axis: .horizontal,
            direction: .leftToRight, length: 1_000, handleExtent: 44) == 350)
    }
    @Test func resizeGrabTracksSmallMovesReversalsAndContainerChanges() {
        // Grab four points off-center at a non-default split.
        let drag = CNResizeDrag(fraction: 0.35, start: 354, length: 1_000)
        #expect(abs(drag.fraction(at: 358, length: 1_000, minimum: 0.15) - 0.354) < 0.000_001)
        #expect(abs(drag.fraction(at: 454, length: 1_000, minimum: 0.15) - 0.45) < 0.000_001)
        #expect(abs(drag.fraction(at: 304, length: 1_000, minimum: 0.15) - 0.30) < 0.000_001)
        #expect(drag.fraction(at: -100, length: 1_000, minimum: 0.15) == 0.15)
        #expect(drag.fraction(at: 1_100, length: 1_000, minimum: 0.15) == 0.85)
        // Resizing the window retains the physical grab position instead of multiplying the old fraction.
        #expect(abs(drag.fraction(at: 304, length: 600, minimum: 0.15) - 0.50) < 0.000_001)
        let next = CNResizeDrag(fraction: 0.30, start: 296, length: 1_000)
        #expect(abs(next.fraction(at: 300, length: 1_000, minimum: 0.15) - 0.304) < 0.000_001)
    }
    @Test @MainActor func recipesHaveNoUnknownUtilitiesAndLocalOverridesWin() throws {
        let rules = TWGlobalRules(modifiers: ["cn-tint": CNUtilities.tint, "cn-mono": CNUtilities.monospaced,
                                              "cn-avatar-crop": CNUtilities.avatarCrop, "cn-avatar-image": CNUtilities.avatarImage,
                                              "cn-shimmer": CNLoadingUtilities.shimmer, "cn-spin": CNLoadingUtilities.spin])
        for (name, _) in TWStyle.defaultClasses {
            _ = try TWStyle.parse(TWClasses(name), rules: rules)
        }
        let resolved = TWStyleResolver.resolve(.classes("badge bg-destructive px-4"), theme: .standard, scheme: .light, state: .init())
        #expect(resolved.background == TWTheme.standard.color(.destructive, scheme: .light))
        #expect(resolved.padding.leading == 16)
    }
    @Test func nativeTintAcceptsTypedColorsAndChecksNamedTokens() throws {
        let rules = TWGlobalRules(modifiers: ["cn-tint": CNUtilities.tint])
        _ = try TWStyle.parse(TWClasses("cn-tint-[\(Color.indigo)]"), rules: rules)
        #expect(throws: (any Error).self) { try TWStyle.parse("cn-tint-[missing]", rules: rules) }
    }
}
