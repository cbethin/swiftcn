#if os(macOS)
import AppKit
import SwiftUI
import SwiftCN

struct GallerySettingsButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        CNButton(variant: .ghost, classes: "w-full px-2", action: { openSettings() }) {
            HStack {
                Label("Settings", systemImage: "gearshape")
                Spacer()
                CNKbd("⌘ ,")
            }.tw("text-xs text-mutedForeground")
        }.accessibilityLabel("Open settings")
    }
}

struct GallerySettingsView: View {
    @Binding var dark: Bool
    @AppStorage(GalleryPreferences.defaultModeKey) private var defaultMode = GalleryWorkspaceMode.split.rawValue
    @AppStorage(GalleryPreferences.previewGridKey) private var previewGrid = true

    var body: some View {
        VStack(spacing: 0) {
            CNWindowHeader(height: 28, classes: "bg-background") { Color.clear }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Settings")
                            .font(.system(size: 22, weight: .semibold)).tracking(-0.5)
                        Text("Appearance and defaults for the component gallery.")
                            .tw("text-xs text-mutedForeground")
                    }
                    preferences
                    shortcuts
                }.padding(24)
            }
            CNSeparator()
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle").tw("text-mutedForeground")
                Text("Saved automatically").tw("text-xs text-mutedForeground")
                Spacer()
                CNButton("Restore defaults", variant: .ghost, size: .small,
                         classes: "text-xs text-mutedForeground", action: restoreDefaults)
            }.padding(.horizontal, 24).frame(height: 56).tw("bg-surface")
        }
        .cnWindowContent()
        .frame(width: 620, height: 576)
        .tw("bg-background text-foreground")
        .preferredColorScheme(dark ? .dark : .light)
        .onChange(of: dark, initial: true) { _, dark in
            NSApplication.shared.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        }
        .galleryChrome()
    }

    private var preferences: some View {
        CNCard("shadow-none rounded-xl") {
            VStack(spacing: 0) {
                HStack(spacing: 20) {
                    settingLabel("Appearance", detail: "Set the mood for the whole gallery.")
                    Spacer(minLength: 0)
                    HStack(spacing: 2) {
                        choice("Light", icon: "sun.max", selected: !dark,
                               accessibility: "Use light appearance") { dark = false }
                        choice("Dark", icon: "moon", selected: dark,
                               accessibility: "Use dark appearance") { dark = true }
                    }.tw("p-1 bg-muted rounded-lg")
                }.padding(16)
                CNSeparator()
                HStack(spacing: 16) {
                    settingLabel("Default view", detail: "Start new windows in your favorite view.")
                    Spacer(minLength: 0)
                    HStack(spacing: 2) {
                        ForEach(GalleryWorkspaceMode.allCases, id: \.self) { mode in
                            choice(mode.rawValue, icon: mode.icon, selected: defaultMode == mode.rawValue,
                                   accessibility: "Default \(mode.rawValue) view") { defaultMode = mode.rawValue }
                        }
                    }.tw("p-1 bg-muted rounded-lg")
                }.padding(16)
                CNSeparator()
                CNSwitch(isOn: $previewGrid, classes: "cn-tint-[primary]") {
                    settingLabel("Preview grid", detail: "A dot grid behind your live examples.")
                }
                .accessibilityLabel("Preview grid").accessibilityIdentifier("gallery-preview-grid")
                .padding(16)
            }
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "keyboard").tw("text-mutedForeground")
                Text("Keyboard shortcuts").tw("text-xs font-medium")
            }
            CNCard("shadow-none rounded-xl") {
                VStack(spacing: 10) {
                    shortcut("Search components", keys: "⌘ K")
                    shortcut("Toggle sidebar", keys: "⇧ ⌘ B")
                    shortcut("Open settings", keys: "⌘ ,")
                }.padding(16)
            }
        }
    }

    private func choice(_ title: String, icon: String, selected: Bool,
                        accessibility: String, action: @escaping () -> Void) -> some View {
        CNButton(variant: .ghost, size: .small,
                 classes: cn("px-2 text-xs rounded-md",
                             selected ? "bg-surface border shadow-sm hover:bg-accent pressed:bg-border" : "text-mutedForeground"),
                 action: action) {
            Label(title, systemImage: icon).fixedSize()
        }
        .accessibilityLabel(accessibility)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func settingLabel(_ title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).tw("text-xs font-medium")
            Text(detail).font(.system(size: 11)).tw("text-mutedForeground")
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func shortcut(_ title: LocalizedStringKey, keys: String) -> some View {
        HStack {
            Text(title).tw("text-xs text-mutedForeground")
            Spacer()
            CNKbd(LocalizedStringKey(keys))
        }
    }

    private func restoreDefaults() {
        dark = false
        defaultMode = GalleryWorkspaceMode.split.rawValue
        previewGrid = true
    }
}
#endif
