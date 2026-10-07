import SwiftUI
import SwiftCN

struct NativeStylesExample: View {
    private enum Field: Hashable { case amount }
    @State private var amount = 12.5
    @State private var notifications = true
    @State private var disabled = false
    @State private var compact = false
    @State private var saves = 0
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CNField {
                Label("Amount", systemImage: "number")
                    .labelStyle(.tw("field-label", base: .titleAndIcon))
                TextField("Amount", value: $amount, format: .number)
                    .textFieldStyle(.tw("input", state: .init(isFocused: focusedField == .amount)))
                    .focused($focusedField, equals: .amount)
                    .onSubmit(save)
                    .disabled(disabled)
                CNFieldDescription("Formatting, selection, and submit handling stay native.")
            }
            Toggle("Notifications", isOn: $notifications)
                .toggleStyle(.tw("switch", base: .switch))
                .disabled(disabled)
            CNButtonGroup {
                Button("Save", action: save)
                    .buttonStyle(.tw("button-primary"))
                    .keyboardShortcut("s", modifiers: .command)
                Button("Edit amount") { focusedField = .amount }
                    .buttonStyle(.tw("button-outline"))
            }.disabled(disabled)
            Text("Saved \(saves) times · Amount: \(amount.formatted(.number))")
                .tw("text-sm text-mutedForeground")
            CNCheckbox("Disable controls", isOn: $disabled)
            CNCheckbox("Compact input recipe", isOn: $compact)
        }
        .twRules {
            if compact {
                $0.named["input"] = "px-3 py-1 min-h-[44] border rounded-lg bg-surface focus:border-primary disabled:opacity-45"
            }
        }
    }
    private func save() { saves += 1; focusedField = nil }
}
