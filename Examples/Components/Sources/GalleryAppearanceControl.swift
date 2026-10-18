import SwiftUI
import SwiftCN

struct GalleryAppearanceControl: View {
    @Binding var dark: Bool
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var indicator

    private var diameter: CGFloat {
        #if os(macOS)
        30
        #else
        44
        #endif
    }

    var body: some View {
        HStack(spacing: 2) {
            appearanceButton(isDark: false)
            appearanceButton(isDark: true)
        }
        .padding(3)
        .background(theme.color(.muted, scheme: scheme), in: Capsule())
        .overlay { Capsule().strokeBorder(theme.color(.border, scheme: scheme), lineWidth: 1).allowsHitTesting(false) }
        .animation(reduceMotion ? nil : .snappy(duration: 0.2, extraBounce: 0), value: dark)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance")
        .twRules { rules in
            // Keep the native CNButton action and focus; draw a quiet surface around the selected icon.
            rules.named["button-ghost"] = .classes(
                "p-0 rounded-full hover:opacity-80 pressed:opacity-60 focus:border-ring " +
                "disabled:opacity-40 animate-none"
            )
        }
    }

    private func appearanceButton(isDark: Bool) -> some View {
        let selected = dark == isDark
        return CNButton(variant: .ghost,
                        classes: cn("p-0 rounded-full", selected ? "hover:bg-primary pressed:bg-primary" : "hover:bg-accent pressed:bg-border"),
                        action: { dark = isDark }) {
            Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.color(selected ? .onPrimary : .mutedForeground, scheme: scheme))
                .frame(width: diameter, height: diameter)
        }
        .background {
            if selected {
                Circle().fill(theme.color(.primary, scheme: scheme))
                    .matchedGeometryEffect(id: "appearance-selection", in: indicator)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityLabel(isDark ? "Use dark appearance" : "Use light appearance")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .help(isDark ? "Dark appearance" : "Light appearance")
    }
}
