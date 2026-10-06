import SwiftUI
import SwiftCN
import Accessibility

public struct CNQuestion: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case text
        case single([CNOption<String>])
        case multiple([CNOption<String>])
    }
    public let id: String
    public var title: String
    public var description: String?
    public var kind: Kind
    public var isRequired: Bool
    public init(_ id: String, title: String, description: String? = nil, kind: Kind = .text, isRequired: Bool = true) {
        self.id = id; self.title = title; self.description = description; self.kind = kind; self.isRequired = isRequired
    }
}
public enum CNAnswer: Equatable, Sendable {
    case text(String)
    case choices(Set<String>)
    public var textValue: String? { if case .text(let value) = self { return value }; return nil }
    public var choiceValues: Set<String>? { if case .choices(let value) = self { return value }; return nil }
}
public enum CNQuestionnaireValidation {
    /// Native controls can write the displayed value during focus without a user edit.
    public static func changesText(_ answer: CNAnswer?, to value: String) -> Bool { (answer?.textValue ?? "") != value }

    public static func error(for question: CNQuestion, answer: CNAnswer?) -> String? {
        switch (question.kind, answer) {
        case (.text, .text(let text)):
            return question.isRequired && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Enter an answer to continue." : nil
        case (.single(let options), .choices(let ids)), (.multiple(let options), .choices(let ids)):
            let allowed = Set(options.filter { !$0.isDisabled }.map(\.id))
            guard ids.isSubset(of: allowed) else { return "Choose an available answer." }
            if case .single = question.kind, ids.count > 1 { return "Choose one answer." }
            return question.isRequired && ids.isEmpty ? "Choose an answer to continue." : nil
        case (_, nil): return question.isRequired ? "Answer this question to continue." : nil
        default: return "The answer does not match this question."
        }
    }
    /// A deterministic navigation decision lets hosts test validation without synthesizing UI events.
    public static func next(questions: [CNQuestion], answers: [String: CNAnswer], activeIndex: Int) -> CNQuestionnaireStep {
        guard !questions.isEmpty else { return .empty }
        let index = min(max(0, activeIndex), questions.count - 1)
        if let message = error(for: questions[index], answer: answers[questions[index].id]) {
            return .invalid(index: index, message: message)
        }
        if index < questions.count - 1 { return .advance(index: index + 1) }
        if let invalid = questions.firstIndex(where: { error(for: $0, answer: answers[$0.id]) != nil }) {
            return .invalid(index: invalid, message: error(for: questions[invalid], answer: answers[questions[invalid].id])!)
        }
        let ids = Set(questions.map(\.id))
        return .submit(answers.filter { ids.contains($0.key) })
    }

}

public enum CNQuestionnaireStep: Equatable, Sendable {
    case empty
    case invalid(index: Int, message: String)
    case advance(index: Int)
    case submit([String: CNAnswer])
}

/// The host owns questions, answers, persistence, cancellation, and submission.
/// This view owns only validation feedback; branching and transport stay in application code.
public struct CNQuestionnaire: View {
    private let questions: [CNQuestion]
    @Binding private var answers: [String: CNAnswer]
    @Binding private var activeIndex: Int
    private let classes: TWClasses
    private let onSubmit: ([String: CNAnswer]) -> Void
    private let onCancel: (() -> Void)?
    @State private var validationError: String?
    @State private var errorQuestionID: String?
    @FocusState private var textFocused: Bool
    public init(_ questions: [CNQuestion], answers: Binding<[String: CNAnswer]>, activeIndex: Binding<Int>,
                classes: TWClasses = "", onCancel: (() -> Void)? = nil, onSubmit: @escaping ([String: CNAnswer]) -> Void) {
        precondition(Set(questions.map(\.id)).count == questions.count, "Question IDs must be unique.")
        self.questions = questions; _answers = answers; _activeIndex = activeIndex
        self.classes = classes; self.onCancel = onCancel; self.onSubmit = onSubmit
    }
    private var index: Int { min(max(0, activeIndex), max(0, questions.count - 1)) }
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !questions.isEmpty {
                let question = questions[index]
                CNProgress("Question \(index + 1) of \(questions.count)", value: Double(index + 1), total: Double(questions.count))
                CNField(isInvalid: validationError != nil && errorQuestionID == question.id) {
                    Text(question.title).tw("text-lg font-semibold").accessibilityAddTraits(.isHeader)
                    if let description = question.description { Text(description).tw("text-sm text-mutedForeground") }
                    answerControl(question).id(question.id)
                    if let validationError, errorQuestionID == question.id { Text(validationError).tw("field-error") }
                }
                HStack {
                    CNButton("Previous", variant: .outline, action: { activeIndex = index - 1 }).disabled(index == 0)
                    Spacer()
                    if let onCancel { CNButton("Cancel", role: .cancel, variant: .ghost, action: onCancel) }
                    if !question.isRequired { CNButton("Skip", variant: .ghost, action: { answers[question.id] = nil; continueFromCurrent() }) }
                    CNButton(index == questions.count - 1 ? "Submit" : "Next", action: continueFromCurrent).keyboardShortcut(.defaultAction)
                }
            } else {
                Text("No questions").tw("text-sm text-mutedForeground")
            }
        }.tw(cn("questionnaire", classes))
            .onChange(of: questions, initial: true) { _, _ in
                if activeIndex != index { activeIndex = index }
                validationError = nil
            }
    }
    @ViewBuilder private func answerControl(_ question: CNQuestion) -> some View {
        switch question.kind {
        case .text:
            CNInput("Your answer", text: Binding(get: {
                if case .text(let value) = answers[question.id] { return value }; return ""
            }, set: { value in
                guard CNQuestionnaireValidation.changesText(answers[question.id], to: value) else { return }
                answers[question.id] = .text(value); validationError = nil
            }), focus: $textFocused)
                .accessibilityLabel(question.title)
                .onSubmit(continueFromCurrent)
        case .single(let options):
            CNRadioGroup("Your answer", options: options, selection: Binding<String?>(get: {
                guard case .choices(let ids) = answers[question.id] else { return nil }
                return options.first { ids.contains($0.id) }?.id
            }, set: { value in
                let current = options.first { answers[question.id]?.choiceValues?.contains($0.id) ?? false }?.id
                guard value != current else { return }
                answers[question.id] = value.map { .choices([$0]) }; validationError = nil
            })).accessibilityLabel(question.title)
        case .multiple(let options):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(options) { option in
                    CNCheckbox(isOn: Binding(get: {
                        if case .choices(let ids) = answers[question.id] { return ids.contains(option.id) }; return false
                    }, set: { isOn in
                        var ids: Set<String> = []
                        if case .choices(let stored) = answers[question.id] { ids = stored }
                        if isOn {
                            ids.insert(option.id)
                        } else { ids.remove(option.id) }
                        answers[question.id] = .choices(ids); validationError = nil
                    })) { Text(option.title) }.disabled(option.isDisabled)
                }
            }
        }
    }
    private func continueFromCurrent() {
        let step = CNQuestionnaireValidation.next(questions: questions, answers: answers, activeIndex: index)
        switch step {
        case .empty: break
        case .advance(let next): validationError = nil; activeIndex = next
        case .submit(let validated): validationError = nil; onSubmit(validated)
        case .invalid(let invalid, let message):
            activeIndex = invalid; errorQuestionID = questions[invalid].id; validationError = message
            AccessibilityNotification.Announcement(message).post()
            if case .text = questions[invalid].kind { textFocused = true }
        }
    }
}
