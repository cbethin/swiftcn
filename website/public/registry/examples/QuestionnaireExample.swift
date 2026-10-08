import SwiftUI
import SwiftCN

struct QuestionnaireExample: View {
    @State private var answers: [String: CNAnswer] = [:]
    @State private var questionIndex = 0
    @State private var submitted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNQuestionnaire([
                CNQuestion("name", title: "What is your workspace called?"),
                CNQuestion("plan", title: "Choose a plan", kind: .single([
                    CNOption("personal", title: "Personal"), CNOption("team", title: "Team")
                ]))
            ], answers: $answers, activeIndex: $questionIndex) { _ in submitted = true }
            Text(submitted ? "Submitted" : "Answers stay in your app.").tw("text-sm text-mutedForeground")

        }
    }
}
