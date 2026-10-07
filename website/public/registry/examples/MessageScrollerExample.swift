import SwiftUI
import SwiftCN

struct MessageScrollerExample: View {
    private struct Message: Identifiable {
        let id: Int
        var text: String
    }
    @State private var messages = (1...12).map { Message(id: $0, text: "Message \($0): a stable native scroll target.") }
    @State private var position: Int?
    @State private var follow = false
    @State private var atBottom = false
    @State private var revision = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CNMessageScroller(messages, followNewMessages: follow, scrollRevision: revision,
                              position: $position, isAtBottom: $atBottom, classes: "h-[240]") { message in
                CNBubble { Text(message.text) }
            }
            CNCheckbox("Follow latest messages", isOn: $follow)
            CNButtonGroup {
                CNButton("Earlier", variant: .outline) {
                    let first = messages.first?.id ?? 1
                    messages.insert(contentsOf: ((first - 5)..<first).map { Message(id: $0, text: "Earlier message \($0)") }, at: 0)
                }
                CNButton("Append", variant: .outline) {
                    messages.append(Message(id: (messages.last?.id ?? 0) + 1, text: "A new message."))
                }
                CNButton("Stream", variant: .outline) {
                    guard !messages.isEmpty else { return }
                    messages[messages.count - 1].text += " More streamed text, wrapping naturally as the message grows."
                    revision += 1
                }
            }
            Text(atBottom ? "At the latest message" : "Reading history — position stays under your control")
                .tw("text-xs text-mutedForeground")
        }
    }
}
