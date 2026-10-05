import SwiftUI
import SwiftCN

struct ArgumentPlayground: View {
    @State private var classes = Self.defaultClasses
    @State private var pressed = false

    private static let defaultClasses = "text-[22] font-semibold tracking-[0.3] line-spacing-[6] text-center p-[24] w-[360] rounded-[22] bg-[#6366f1] text-[#fff] hover:scale-[1.02] active:tilt-[3deg] animate-smooth duration-[220ms]"
    private var rules: TWGlobalRules {
        TWGlobalRules(utilities: ["tilt": TWUtility { argument, _ in
            guard let degrees = argument.degrees else { return nil }
            return .rotate(degrees)
        }])
    }
    private var validationError: String? {
        do { _ = try TWStyle.parse(classes, rules: rules); return nil }
        catch { return String(describing: error) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your values, native modifiers").tw("text-2xl font-semibold")
                Text("Edit the classes. Use exact sizes, typography, colors, and a custom tilt utility.")
                    .tw("text-base text-muted-foreground")
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Argument classes").tw("text-lg font-semibold")
                        TextEditor(text: $classes)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 240)
                            .accessibilityLabel("Arbitrary argument classes")
                            .tw("p-2 border rounded-md")
                        Toggle("Preview active state", isOn: $pressed)
                        Button("Reset classes") { classes = Self.defaultClasses }
                            .buttonStyle(.demo("button-outline"))
                        if let validationError {
                            Text(validationError).tw("text-sm text-destructive")
                            Text("The preview uses the default classes until the input is valid.")
                                .tw("text-sm text-muted-foreground")
                        }
                    }.frame(width: 300).tw("card")

                    VStack(alignment: .leading, spacing: 20) {
                        ZStack {
                            Text("Room for ideas\nA little space to think.")
                                .tw(validationError == nil ? classes : Self.defaultClasses,
                                    state: .init(isPressed: pressed))
                                .accessibilityIdentifier("argument-preview")
                        }.frame(maxWidth: .infinity, minHeight: 260)
                        Text("Custom global utility").tw("text-lg font-semibold")
                        Text("""
                        rules.utilities["tilt"] = TWUtility { argument, _ in
                            guard let degrees = argument.degrees else { return nil }
                            return .rotate(degrees)
                        }

                        Text("Hello").tw("hover:tilt-[3deg]")
                        """)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tw("p-4 rounded-md bg-accent")
                        Text("Bracket lengths use native points. Hex colors use RGB or RGBA order.")
                            .tw("text-sm text-muted-foreground")
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.padding(32)
        }.twRules(rules)
    }
}
