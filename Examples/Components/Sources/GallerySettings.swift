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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your component workbench").font(.system(size: 24, weight: .semibold)).tracking(-0.5)
                        Text("A few preferences to make it feel like home.")
                            .tw("text-sm text-mutedForeground")
                    }.padding(.bottom, 4)
                    appearance
                    workbench
                    shortcuts
                }.padding(28)
            }
            CNSeparator()
            HStack {
                Text("Changes save automatically").tw("text-xs text-mutedForeground")
                Spacer()
                CNButton("Restore defaults", variant: .outline, size: .small, action: restoreDefaults)
            }.padding(.horizontal, 28).frame(height: 60).tw("bg-surface")
        }
        .frame(width: 600, height: 720)
        .tw("bg-background text-foreground")
        .preferredColorScheme(dark ? .dark : .light)
        .onChange(of: dark, initial: true) { _, dark in
            NSApplication.shared.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        }
        .galleryChrome()
    }

    private var appearance: some View {
        CNCard("shadow-none rounded-xl") {
            CNCardContent("pt-5") {
                HStack(spacing: 24) {
                    settingLabel("Appearance", detail: "Use light or dark throughout the gallery.")
                    Spacer(minLength: 0)
                    GalleryAppearanceControl(dark: $dark)
                }
            }
        }
    }

    private var workbench: some View {
        CNCard("shadow-none rounded-xl") {
            CNCardHeader {
                CNCardTitle("Workbench", classes: "text-sm")
                CNCardDescription("Set up your next window and live previews.")
            }
            CNCardContent {
                CNFieldGroup(spacing: 18) {
                    CNField {
                        CNFieldLabel("Default view")
                        CNSelect("Default view", options: GalleryWorkspaceMode.allCases.map {
                            CNOption($0.rawValue, title: $0.rawValue)
                        }, selection: $defaultMode).labelsHidden()
                        CNFieldDescription("Used when you open a new gallery window.")
                    }
                    CNSeparator()
                    CNSwitch(isOn: $previewGrid) {
                        settingLabel("Preview grid", detail: "Show the dot grid behind live examples.")
                    }.accessibilityLabel("Preview grid").accessibilityIdentifier("gallery-preview-grid")
                }
            }
        }
    }

    private var shortcuts: some View {
        CNCard("shadow-none rounded-xl") {
            CNCardHeader { CNCardTitle("Keyboard shortcuts", classes: "text-sm") }
            CNCardContent {
                VStack(spacing: 12) {
                    shortcut("Search components", keys: "⌘ K")
                    shortcut("Toggle sidebar", keys: "⇧ ⌘ B")
                    shortcut("Open settings", keys: "⌘ ,")
                }
            }
        }
    }

    private func settingLabel(_ title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).tw("text-sm font-medium")
            Text(detail).tw("text-xs text-mutedForeground").fixedSize(horizontal: false, vertical: true)
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
