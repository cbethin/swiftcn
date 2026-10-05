import SwiftUI
import SwiftCN

struct DemoView: View {
    @State private var appearance = DemoAppearance.system

    var body: some View {
        TabView {
            ScrollView { CatalogView().frame(maxWidth: .infinity) }
                .tabItem { Label("Components", systemImage: "square.grid.2x2") }
            MotionPlayground()
                .tabItem { Label("Motion", systemImage: "waveform.path") }
            SharedElementPlayground()
                .tabItem { Label("Shared elements", systemImage: "rectangle.on.rectangle") }
            GlobalRulesPlayground()
                .tabItem { Label("Global rules", systemImage: "slider.horizontal.3") }
        }
        .padding(12)
        .frame(minWidth: 960, minHeight: 680)
        .preferredColorScheme(appearance.scheme)
        .toolbar {
            ToolbarItem {
                Picker("Appearance", selection: $appearance) {
                    ForEach(DemoAppearance.allCases) { item in Text(item.rawValue).tag(item) }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

private enum DemoAppearance: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: Self { self }
    var scheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}

struct MotionPlayground: View {
    @State private var expanded = false
    @State private var preset = "spring"
    @State private var duration = 400.0
    @State private var delay = 0.0
    @State private var presses = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var motion = DemoMotion()

    private var motionClasses: String { "animate-\(preset) duration-\(Int(duration)) delay-\(Int(delay))" }
    private var surfaceClasses: String {
        "\(expanded ? "p-8 rounded-xl bg-primary text-primary-foreground" : "p-3 rounded-md bg-accent text-foreground") \(motionClasses)"
    }
    private var buttonClasses: String {
        "button-primary active:opacity-80 hover:bg-accent hover:text-foreground \(motionClasses)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DemoHeading(title: "Native motion, composed with strings",
                            subtitle: "Change state. SwiftUI animates the values that .tw owns.")
                    .demoEntrance()
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Animation settings").tw("text-lg font-semibold")
                        Picker("Preset", selection: $preset) {
                            ForEach(["spring", "smooth", "snappy", "bouncy", "ease-in-out", "ease-out", "linear", "settle", "none"], id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        LabeledContent("Duration") { Text("\(Int(duration)) ms").demoNumber(Int(duration)) }
                        Slider(value: $duration, in: 100...1200, step: 50).accessibilityLabel("Duration")
                        LabeledContent("Delay") { Text("\(Int(delay)) ms").demoNumber(Int(delay)) }
                        Slider(value: $delay, in: 0...500, step: 50).accessibilityLabel("Delay")
                        Toggle("Expanded", isOn: $expanded)
                        if reduceMotion {
                            Text("Reduce Motion is on. Styled changes appear immediately.")
                                .tw("text-sm text-muted-foreground")
                        }
                    }
                    .frame(width: 260)
                    .tw("card")
                    .demoEntrance(delay: 0.04)

                    VStack(alignment: .leading, spacing: 20) {
                        Text("State → native modifiers").tw("text-lg font-semibold")
                        ZStack {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .symbolEffect(.bounce, options: .speed(1.4), value: expanded)
                                    .symbolEffectsRemoved(!motion.isEnabled || preset == "none")
                                    .accessibilityHidden(true)
                                Text("Hello, SwiftUI")
                            }
                            .tw(surfaceClasses)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .tw("rounded-lg border")
                        Button(expanded ? "Collapse surface" : "Expand surface") { expanded.toggle() }
                            .buttonStyle(.demo("button-outline animate-smooth duration-180"))
                        DemoCode(text: ".tw(\"\(surfaceClasses)\")")
                        Text("Press and hover") .tw("text-lg font-semibold")
                        HStack {
                            Button { presses += 1 } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "hand.tap")
                                        .symbolEffect(.bounce, options: .speed(1.5), value: presses)
                                        .symbolEffectsRemoved(!motion.isEnabled || preset == "none")
                                    Text("Press me")
                                }
                            }
                            .buttonStyle(.demo(buttonClasses, feedback: preset != "none"))
                            Text("\(presses) activations").tw("text-sm text-muted-foreground").demoNumber(presses)
                        }
                        DemoCode(text: ".buttonStyle(.tw(\"\(buttonClasses)\"))")
                        Text("The settle preset comes from a custom native spring in global rules.")
                            .tw("text-sm text-muted-foreground")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tw("card")
                    .demoEntrance(delay: 0.08)
                }
            }
            .padding(32)
        }
        .twRules(.init(animations: ["settle": TWAnimation { .spring(duration: $0, bounce: 0.15) }]))
    }
}

struct GlobalRulesPlayground: View {
    @State private var palette = DemoPalette.indigo
    @State private var spacing = 4.0
    @State private var pillButtons = true
    @State private var compactScope = true
    @State private var cardClasses = "p-6 rounded-lg border bg-surface"
    @State private var name = "My workspace"
    @State private var enabled = true
    @State private var saves = 0
    private var motion = DemoMotion()

    private var customTheme: TWTheme {
        TWTheme(spacingUnit: spacing, colors: [.primary: palette.color])
    }

    private var validationError: String? {
        do { _ = try TWStyle.parse(cardClasses, theme: customTheme); return nil }
        catch { return String(describing: error) }
    }

    private var rules: TWGlobalRules {
        TWGlobalRules(
            view: "animate-smooth duration-220",
            button: "animate-snappy duration-200",
            named: [
                "demo-card": validationError == nil ? .classes(cardClasses) : "p-6 rounded-lg border bg-surface",
                "demo-button": TWStyle(.primaryButton, .rounded(pillButtons ? .full : .md))
            ]
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DemoHeading(title: "Your rules, across native views",
                            subtitle: "Edit shared classes, change the theme, and override one subtree.")
                    .demoEntrance()
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Global settings").tw("text-lg font-semibold")
                        Picker("Palette", selection: $palette) {
                            ForEach(DemoPalette.allCases) { item in Text(item.rawValue).tag(item) }
                        }
                        LabeledContent("Spacing unit") { Text("\(Int(spacing)) pt").demoNumber(Int(spacing)) }
                        Slider(value: $spacing, in: 3...6, step: 1).accessibilityLabel("Spacing unit")
                        Toggle("Pill buttons", isOn: $pillButtons)
                        Toggle("Compact second card", isOn: $compactScope)
                        Text("Shared card classes").tw("text-sm font-semibold")
                        TextEditor(text: $cardClasses)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 90)
                            .tw("p-2 border rounded-md")
                        if let validationError {
                            Text(validationError).tw("text-sm text-destructive")
                            Text("The preview keeps the default card until the classes are valid.")
                                .tw("text-sm text-muted-foreground")
                        }
                    }
                    .frame(width: 260)
                    .tw("card")
                    .demoEntrance(delay: 0.04)

                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Workspace").tw("text-xl font-semibold")
                            TextField("Workspace name", text: $name).textFieldStyle(.roundedBorder)
                            Toggle("Notifications", isOn: $enabled)
                            Button { saves += 1 } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: saves == 0 ? "square.and.arrow.down" : "checkmark.circle.fill")
                                        .contentTransition(.symbolEffect(.replace))
                                        .symbolEffect(.bounce, options: .speed(1.5), value: saves)
                                        .symbolEffectsRemoved(!motion.isEnabled)
                                    Text("Save workspace")
                                }
                            }
                            .buttonStyle(.demo("demo-button"))
                            Text("Saved \(saves) times").tw("text-sm text-muted-foreground").demoNumber(saves)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tw("demo-card")

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scoped card").tw("text-lg font-semibold")
                            Text("This card has a local rule. The workspace card keeps the shared rule.")
                                .tw("text-sm text-muted-foreground")
                            Button("Native button") {}.buttonStyle(.demo("demo-button"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tw("demo-card")
                        .twRules { scoped in
                            if compactScope { scoped.named["demo-card"] = "p-3 rounded-sm border bg-accent" }
                        }
                        DemoCode(text: "rules.named[\"demo-card\"] = \"\(cardClasses)\"\nText(\"Workspace\").tw(\"demo-card\")")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .twTheme(customTheme)
                    .twRules(rules)
                    .animation(motion.soft, value: compactScope)
                    .demoEntrance(delay: 0.08)
                }
            }
            .padding(32)
        }
    }
}

private enum DemoPalette: String, CaseIterable, Identifiable {
    case neutral = "Neutral", indigo = "Indigo", rose = "Rose"
    var id: Self { self }
    var color: TWAdaptiveColor {
        switch self {
        case .neutral: .init(light: .black, dark: .white)
        case .indigo: .init(light: .indigo, dark: .mint)
        case .rose: .init(light: Color(red: 0.73, green: 0.12, blue: 0.3), dark: .pink)
        }
    }
}

private struct DemoHeading: View {
    let title: String
    let subtitle: String
    private var motion = DemoMotion()

    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .symbolEffect(.pulse, options: .repeating.speed(0.3), isActive: motion.isEnabled)
                    .accessibilityHidden(true)
                Text(title).tw("text-2xl font-semibold")
            }
            Text(subtitle).tw("text-base text-muted-foreground")
        }
    }
}

private struct DemoCode: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tw("p-3 rounded-md bg-accent text-foreground")
    }
}
