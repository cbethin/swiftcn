import SwiftUI
import SwiftCN

struct SharedElementPlayground: View {
    @State private var expanded = false
    @State private var preset = "smooth"
    @State private var duration = 450.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(expanded: Bool = false) { _expanded = State(initialValue: expanded) }

    private var motionClasses: String { "animate-\(preset) duration-\(Int(duration))" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("One element, two native layouts").tw("text-2xl font-semibold")
                    Text("Open the card. Its artwork and title move into the detail layout.")
                        .tw("text-base text-muted-foreground")
                }
                .demoEntrance()

                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Shared elements").tw("text-lg font-semibold")
                        Picker("Preset", selection: $preset) {
                            ForEach(["smooth", "spring", "snappy", "bouncy", "none"], id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        LabeledContent("Duration") { Text("\(Int(duration)) ms").demoNumber(Int(duration)) }
                        Slider(value: $duration, in: 150...900, step: 50).accessibilityLabel("Shared transition duration")
                        Button(expanded ? "Close details" : "Open details") { expanded.toggle() }
                            .buttonStyle(.demo("button-primary"))
                            .keyboardShortcut(.return, modifiers: [])
                        if reduceMotion {
                            Text("Reduce Motion is on. The layout changes immediately.")
                                .tw("text-sm text-muted-foreground")
                        }
                        Text("The hero group owns a native namespace. Shared classes pair its children.")
                            .tw("text-sm text-muted-foreground")
                    }
                    .frame(width: 260)
                    .tw("card")
                    .demoEntrance(delay: 0.04)

                    VStack(alignment: .leading, spacing: 20) {
                        ZStack {
                            if expanded {
                                VStack(alignment: .leading, spacing: 20) {
                                    artwork.frame(maxWidth: .infinity).frame(height: 210)
                                    title.tw("text-2xl")
                                    Text("A quiet place for your next idea. Native layout and a shared identity do the moving.")
                                        .tw("text-base text-muted-foreground")
                                        .transition(.opacity)
                                }
                                .transition(.opacity)
                            } else {
                                HStack(spacing: 20) {
                                    artwork.frame(width: 112, height: 112)
                                    VStack(alignment: .leading, spacing: 8) {
                                        title.tw("text-xl")
                                        Text("A little space to think.").tw("text-sm text-muted-foreground")
                                    }
                                    Spacer(minLength: 0)
                                }
                                .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 350)
                        .tw("group/hero p-6 rounded-xl border bg-surface \(motionClasses)", value: expanded)
                        .accessibilityIdentifier("shared-element-preview")

                        Text(expanded ? "Detail layout" : "Compact layout").tw("text-sm text-muted-foreground")
                        Text(code)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tw("p-4 rounded-md bg-accent")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .demoEntrance(delay: 0.08)
                }
            }
            .padding(32)
        }
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay { Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(.white) }
            .tw("shared-[artwork]/hero")
            .accessibilityHidden(true)
    }

    private var title: some View {
        Text("Room for ideas")
            .tw("shared-[title]/hero shared-position font-semibold group-hover/hero:opacity-70 animate-smooth duration-180")
    }

    private var code: String {
        """
        @State private var expanded = false

        // In both layouts, before their different frames:
        artwork.tw("shared-[artwork]/hero")
        title.tw("shared-[title]/hero shared-position")

        // On their common container:
        .tw("group/hero \(motionClasses)", value: expanded)
        """
    }
}
