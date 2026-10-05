import SwiftUI
import SwiftCN

struct ComponentPlayground: View {
    @State private var email = "charles"
    @State private var name = "Charles"
    @State private var updates = true
    @State private var volume = 0.4
    @State private var submitted = true
    @State private var saved = false
    @State private var compact = false
    @FocusState private var emailFocused: Bool
    private var motion = DemoMotion()
    private var invalid: Bool { submitted && !email.contains("@") }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Native controls, composable parts").tw("text-2xl font-semibold")
                Text("Edit the fields, save the form, and change its shared defaults.")
                    .tw("text-base text-muted-foreground")
                Toggle("Compact content rule", isOn: $compact).toggleStyle(.tw(base: .switch))
                form
                    .twRules { rules in
                        if compact { rules.named["card-content"] = "p-4" }
                    }
                    .demoEntrance(delay: 0.04)
                Text("CNField supplies validation appearance. SwiftUI owns editing, focus, bindings, and actions.")
                    .tw("text-sm text-muted-foreground")
            }
            .padding(32)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var form: some View {
        CNCard {
            CNCardHeader {
                CNCardTitle {
                    Label("Your workspace", systemImage: "folder")
                        .labelStyle(.tw("", base: .titleAndIcon))
                }
                CNCardDescription("Custom content in every slot. Native editing in every field.")
            }
            CNCardContent {
                CNFieldGroup {
                    CNField {
                        CNFieldLabel("Name").accessibilityHidden(true)
                        TextField("Name", text: $name).textFieldStyle(.tw())
                        CNFieldDescription("Shown on your profile.")
                    }
                    CNField(isInvalid: invalid) {
                        CNFieldLabel("Email").accessibilityHidden(true)
                        TextField("Email", text: $email)
                            .focused($emailFocused)
                            .textFieldStyle(.tw("input animate-smooth duration-180",
                                state: TWState(isFocused: emailFocused)))
                            .onSubmit(save)
                            .accessibilityHint(invalid ? "Enter an email address." : "Used for invitations.")
                        if invalid {
                            CNFieldError("Enter an email address.")
                        } else {
                            CNFieldDescription("Used for invitations.")
                        }
                    }
                    CNField {
                        CNFieldLabel("Notification volume").accessibilityHidden(true)
                        CNFieldControl("p-3 border rounded-md") {
                            Slider(value: $volume).accessibilityLabel("Notification volume")
                        }
                    }
                    Toggle("Product updates", isOn: $updates).toggleStyle(.tw(base: .switch))
                    Toggle("Managed by your organization", isOn: .constant(false))
                        .toggleStyle(.tw()).disabled(true)
                }
            }
            CNCardFooter {
                Button(action: save) {
                    Label(saved ? "Saved" : "Save workspace", systemImage: saved ? "checkmark" : "square.and.arrow.down")
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.demo("button-primary"))
                Button("Reset") {
                    email = ""
                    name = "Charles"
                    submitted = false
                    saved = false
                }
                .buttonStyle(.demo("button-outline"))
                Spacer()
            }
        }
        .animation(motion.soft, value: invalid)
        .onChange(of: email) { saved = false }
        .onChange(of: name) { saved = false }
    }

    private func save() {
        submitted = true
        saved = !invalid
        emailFocused = invalid
    }
}
