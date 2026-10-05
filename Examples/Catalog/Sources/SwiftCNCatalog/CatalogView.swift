import SwiftUI
import SwiftCN

struct CatalogView: View {
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme
    @State private var notifications = true
    @State private var projectName = "My workspace"
    @State private var saves = 0
    @FocusState private var fieldFocused: Bool
    private var motion = DemoMotion()

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space(7)) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: theme.space(2)) {
                    Text("swiftcn").tw(.text(.xxxl), .weight(.bold), .fg(.foreground))
                    Text("Small styles. Native SwiftUI.").tw(.text(.lg), .fg(.mutedForeground))
                }
                Spacer()
                Text(scheme == .dark ? "DARK" : "LIGHT")
                    .tw(.text(.xs), .weight(.semibold), .px(3), .py(1.5), .bg(.accent), .fg(.onAccent), .rounded(.full))
            }
            .demoEntrance()

            VStack(alignment: .leading, spacing: theme.space(4)) {
                sectionLabel("01 / NATIVE BUTTONS")
                HStack(spacing: theme.space(3)) {
                    Button { saves += 1 } label: {
                        HStack(spacing: 6) {
                            Image(systemName: saves == 0 ? "square.and.arrow.down" : "checkmark.circle.fill")
                                .contentTransition(.symbolEffect(.replace))
                                .symbolEffect(.bounce, options: .speed(1.5), value: saves)
                                .symbolEffectsRemoved(!motion.isEnabled)
                            Text("Save changes")
                        }
                    }
                    .buttonStyle(.demo("button-primary animate-spring duration-180"))
                    Button("Preview") {}.buttonStyle(.demo(.secondaryButton))
                    Button("Cancel") {}.buttonStyle(.demo(.outlineButton))
                    Button("Delete", role: .destructive) {}.buttonStyle(.demo(.destructiveButton))
                    Button("Disabled") {}.buttonStyle(.demo(.primaryButton)).disabled(true)
                }
                Text(saves == 0 ? "Native activation, roles, and disabled state." : "Saved \(saves) time(s).")
                    .tw(.text(.sm), .fg(.mutedForeground))
                    .demoNumber(saves)
            }
            .tw(.card, .fullWidth)
            .demoEntrance(delay: 0.04)

            HStack(alignment: .top, spacing: theme.space(5)) {
                VStack(alignment: .leading, spacing: theme.space(4)) {
                    sectionLabel("02 / COMPOSABLE SURFACES")
                    Text("Your workspace").tw(.text(.xl), .weight(.semibold))
                    Text("A shared theme gives native controls a consistent surrounding surface.")
                        .tw(.text(.base), .fg(.mutedForeground))
                    TextField("Project name", text: $projectName)
                        .textFieldStyle(.plain)
                        .focused($fieldFocused)
                        .tw(.px(3), .py(2), .bg(.background), .border(.border), .rounded(.md),
                            .focus(.border(.primary, width: 2)), .animation(.smooth), .duration(0.18),
                            state: .init(isFocused: fieldFocused))
                    Toggle("Notifications", isOn: $notifications).tint(theme.color(.primary, scheme: scheme))
                    Divider()
                    Button("Create project") { saves += 1 }.buttonStyle(.demo(.primaryButton, .fullWidth))
                }
                .tw(.card, .fullWidth)
                .demoEntrance(delay: 0.08)

                VStack(alignment: .leading, spacing: theme.space(4)) {
                    sectionLabel("03 / TYPED UTILITIES")
                    Text("One design vocabulary").tw(.text(.xl), .weight(.semibold))
                    Text("p(4)   ·   rounded(lg)   ·   bg(surface)")
                        .font(.system(.caption, design: .monospaced))
                        .tw("\(notifications ? "p-3 rounded-md" : "p-5 rounded-xl") bg-accent w-full animate-spring duration-300")
                    HStack(spacing: theme.space(2)) {
                        tokenTile("4", units: 4)
                        tokenTile("6", units: 6)
                        tokenTile("8", units: 8)
                    }
                    Text("Edit the source. Extend the theme. Keep your SwiftUI composition.")
                        .tw(.text(.base), .fg(.mutedForeground))
                }
                .tw(.card, .fullWidth)
                .demoEntrance(delay: 0.12)
            }

            HStack {
                Text("SwiftCN / first styling layer").tw(.text(.xs), .fg(.mutedForeground))
                Spacer()
                Text("iOS 17+  ·  macOS 14+").tw(.text(.xs), .fg(.mutedForeground))
            }
        }
        .padding(36)
        .frame(width: 900)
        .background(theme.color(.background, scheme: scheme))
    }

    private func sectionLabel(_ value: String) -> some View {
        Text(value).tw(.text(.xs), .weight(.semibold), .fg(.mutedForeground))
    }

    private func tokenTile(_ label: String, units: CGFloat) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4).fill(theme.color(.primary, scheme: scheme))
                .frame(width: theme.space(units), height: theme.space(units))
            Text(label).tw(.text(.xs), .fg(.mutedForeground))
        }
        .frame(maxWidth: .infinity)
        .tw(.p(3), .bg(.background), .rounded(.md))
    }
}
