import SwiftUI

// Compiled with the copied library sources, so this host needs no Xcode project.
@main
struct SwiftCNVisualHost: App {
    private let arguments = CommandLine.arguments
    private var dark: Bool { arguments.contains("--dark") }
    private var large: Bool { arguments.contains("--large-text") }
    private var rulesScene: Bool { arguments.contains("--rules") }

    var body: some Scene {
        WindowGroup {
            IOSFixture(rulesScene: rulesScene)
                .preferredColorScheme(dark ? .dark : .light)
                .environment(\.dynamicTypeSize, large ? .accessibility3 : .large)
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .transaction { $0.animation = nil }
                .task {
                    // Signal only after the native controls settle. The capture script polls this file.
                    try? await Task.sleep(for: .seconds(1))
                    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    try? Data("ready".utf8).write(to: directory.appendingPathComponent("visual-ready"))
                }
        }
    }
}

private struct IOSFixture: View {
    let rulesScene: Bool
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("swiftcn / iOS").tw("text-xl font-semibold")
                if rulesScene { rules } else { controls }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .foregroundStyle(theme.color(.foreground, scheme: scheme))
        .background(theme.color(.background, scheme: scheme))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Native controls and Dynamic Type").tw("text-lg")
            TextField("Name", text: .constant("Charles")).textFieldStyle(.plain)
                .tw("px-3 py-2 rounded-md border bg-surface")
            Button("String classes") {}.buttonStyle(.tw("button-primary w-full"))
            Button("Typed utilities") {}.buttonStyle(.tw(.outlineButton, .fullWidth))
            Button("Disabled button") {}.buttonStyle(.tw("button-primary w-full")).disabled(true)
            Toggle("Notifications", isOn: .constant(true))
            Slider(value: .constant(0.6)).accessibilityLabel("Volume")
            Text("Native text grows. The card and button heights follow the content.")
                .tw("card text-base w-full")
        }
    }

    private var rules: some View {
        let brand = TWColor("brand")
        let customTheme = TWTheme(colors: [brand: TWAdaptiveColor(light: .indigo, dark: .mint)])
        let customRules = TWGlobalRules(named: [
            "brand-button": TWStyle(.primaryButton, .bg(brand), .rounded(.full)),
            "card": TWStyle(TWStyle.defaultStyle(for: "card")!, .p(3), .radius(20))
        ])
        return VStack(alignment: .leading, spacing: 16) {
            Text("Global rules").tw("text-lg")
            Text("A global card").tw("card w-full")
            Button("Brand button") {}.buttonStyle(.tw("brand-button w-full"))
            Text("Local overrides").tw("card rounded-sm w-full")
            Text("Scoped rules").tw("card w-full").twRules {
                $0.named["card"] = .classes("p-3 rounded-none border-2 border-brand")
            }
            Text("Sibling keeps global rules").tw("card w-full")
        }.twTheme(customTheme).twRules(customRules)
    }
}
