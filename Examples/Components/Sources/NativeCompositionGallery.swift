import SwiftUI
import SwiftCN

enum CNNativeComposition: String, CaseIterable, Identifiable {
    case styles, drawer, navigation, split
    var id: Self { self }
    var title: String {
        switch self {
        case .styles: "Native control styles"
        case .drawer: "Native drawer content"
        case .navigation: "Native navigation"
        case .split: "Native split views"
        }
    }
    @MainActor var example: AnyView {
        switch self {
        case .styles: AnyView(NativeStylesExample())
        case .drawer: AnyView(NativeDrawerExample())
        case .navigation: AnyView(NativeNavigationLauncher())
        case .split: AnyView(NativeSplitExample())
        }
    }
}

enum CNGallerySelection: Hashable {
    case component(CNComponentGallery), native(CNNativeComposition)
    var title: String {
        switch self {
        case .component(let component): component.title
        case .native(let composition): composition.title
        }
    }
    var source: String {
        switch self {
        case .component(let component): component.source
        case .native(let composition): composition.source
        }
    }
    @MainActor var example: AnyView {
        switch self {
        case .component(let component): component.example
        case .native(let composition): composition.example
        }
    }
}

private struct NativeNavigationLauncher: View {
    @State private var presented = false
    @Environment(\.colorScheme) private var scheme
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Open native navigation") {
                #if os(macOS)
                openWindow(id: "native-navigation")
                #else
                presented = true
                #endif
            }.buttonStyle(.tw("button-outline"))
            Text("Open a complete navigation root with native columns and compact navigation.")
                .tw("text-sm text-mutedForeground")
        }
        #if !os(macOS)
        .sheet(isPresented: $presented) {
            NativeNavigationGalleryWindow(dark: scheme == .dark)
                .presentationDetents([.large])
        }
        #endif
    }
}

struct NativeNavigationGalleryWindow: View {
    let dark: Bool
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NativeNavigationExample()
            #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            #else
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }.buttonStyle(.tw("button-outline"))
                }.tw("px-6 py-3 bg-surface")
            }
            #endif
            .preferredColorScheme(dark ? .dark : .light)
    }
}
