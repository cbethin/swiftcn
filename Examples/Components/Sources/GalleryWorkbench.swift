import SwiftUI
import SwiftCN
#if os(macOS)
import AppKit
#endif

enum GalleryWorkspaceMode: String, CaseIterable {
    case preview = "Preview", code = "Code", split = "Split"
    var icon: String {
        switch self {
        case .preview: "rectangle.on.rectangle"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .split: "rectangle.split.2x1"
        }
    }
}

struct ComponentGalleryView: View {
    @State private var selection: CNGallerySelection = {
        #if DEBUG
        if let route = ProcessInfo.processInfo.environment["SWIFTCN_UI_EXAMPLE"] {
            if route.hasPrefix("native:"), let example = CNNativeComposition(rawValue: String(route.dropFirst(7))) {
                return .native(example)
            }
            if let example = CNComponentGallery(rawValue: route) { return .component(example) }
        }
        #endif
        return .component(.button)
    }()
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var mobilePresented = false
    @State private var mode = GalleryPreferences.defaultMode()
    @FocusState private var searchFocused: Bool
    @Binding var dark: Bool

    var body: some View {
        CNSidebar(visibility: $visibility, mobilePresented: $mobilePresented,
                  collapsible: .offcanvas, width: 248, compactBreakpoint: 740) {
            GalleryNavigation(selection: $selection, searchFocused: $searchFocused,
                              onSearch: focusSearch)
                .galleryChrome()
        } detail: {
            VStack(spacing: 0) {
                topBar
                CNSeparator()
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 26) {
                            introduction
                            #if DEBUG
                            if ProcessInfo.processInfo.environment["SWIFTCN_UI_PROBE"] == "native-button-labels" {
                                NativeButtonLabelProbe()
                            }
                            #if os(macOS)
                            if ProcessInfo.processInfo.environment["SWIFTCN_UI_PROBE"] == "flat-button-focus" {
                                NativeButtonFocusProbe()
                            }
                            #endif
                            #endif
                            GalleryWorkspace(selection: selection, mode: $mode,
                                             isWide: geometry.size.width >= 780)
                                .id(selection)
                            compositionNote
                        }
                        .padding(geometry.size.width < 600 ? 20 : 32)
                        .frame(maxWidth: 1440)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
            }.tw("bg-background")
        }
        .preferredColorScheme(dark ? .dark : .light)
        .cnPopoverHost().cnPresentationHost()
        #if os(macOS)
        .frame(minWidth: 680, minHeight: 560)
        #endif
    }

    private var topBar: some View {
        GalleryWindowHeader {
            HStack(spacing: 12) {
                CNSidebarTrigger().keyboardShortcut("b", modifiers: [.command, .shift])
                CNSeparator(axis: .vertical).frame(height: 16)
                ViewThatFits(in: .horizontal) {
                    CNBreadcrumb {
                        Text(selection.sectionTitle).tw("text-sm text-mutedForeground")
                        CNBreadcrumbSeparator()
                        CNBreadcrumbPage(LocalizedStringKey(selection.title))
                    }.fixedSize()
                    Text(selection.title).font(.subheadline.weight(.medium)).lineLimit(1)
                }
                Spacer(minLength: 8)
                GalleryAppearanceControl(dark: $dark)
            }
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("COMPONENT LIBRARY")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(2)
                    .tw("text-mutedForeground")
                Spacer()
                CNBadge("SwiftUI", variant: .outline, classes: "font-medium")
            }
            Text(selection.title)
                .font(.system(size: 34, weight: .semibold)).tracking(-1)
                .accessibilityAddTraits(.isHeader)
            Text(selection.summary)
                .font(.system(size: 14)).lineSpacing(4)
                .tw("text-mutedForeground")
                .frame(maxWidth: 680, alignment: .leading)
        }
    }

    private var compositionNote: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                Label("Built with the library", systemImage: "square.stack.3d.up")
                    .font(.system(size: 11)).tw("text-mutedForeground")
                Spacer(minLength: 8)
                componentLinks
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Built with the library").tw("text-xs text-mutedForeground")
                componentLinks
            }
        }
    }

    private var componentLinks: some View {
        HStack(spacing: 4) {
            ForEach([CNComponentGallery.sidebar, .card, .button, .input_group, .badge]) { component in
                CNButton(LocalizedStringKey(component.title), variant: .ghost, size: .small,
                         classes: "text-xs px-2 text-mutedForeground", action: { selection = .component(component) })
            }
        }.galleryChrome()
    }

    private func focusSearch() {
        visibility = .all
        mobilePresented = true
        searchFocused = true
    }
}

private struct GalleryWindowHeader<Content: View>: View {
    @Environment(\.cnSidebarContext) private var sidebar
    @Environment(\.layoutDirection) private var direction
    @ViewBuilder let content: Content

    var body: some View {
        CNWindowHeader(reservesWindowControls: sidebar.isCompact || !sidebar.isPresented || direction == .rightToLeft) { content }
            .galleryChrome()
    }
}

private struct GalleryNavigation: View {
    @Binding var selection: CNGallerySelection
    @State private var results = GallerySearchResults()
    @State private var searchReset = 0
    var searchFocused: FocusState<Bool>.Binding
    let onSearch: () -> Void
    @Environment(\.cnSidebarContext) private var sidebar
    @Environment(\.openURL) private var openURL
    private var resultLabel: String {
        let count = results.count
        return count == 1 ? "1 result" : "\(count) results"
    }

    var body: some View {
        CNWindowControlsSpacer(axis: .vertical)
        CNSidebarHeader("p-5 pb-3") {
            HStack(spacing: 10) {
                brandMark.accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("SwiftCN").font(.system(size: 18, weight: .semibold)).tracking(-0.5)
                    Text("Native components").font(.system(size: 11)).tw("text-mutedForeground")
                }
                Spacer(minLength: 0)
                if sidebar.isCompact { CNSidebarTrigger() }
            }.padding(.bottom, 16)
            GallerySearchField(focus: searchFocused, reset: searchReset, onSearch: onSearch,
                               onFilter: filter, onSubmit: submit)
            Text(results.query.isEmpty ? "\(CNComponentGallery.allCases.count) components · \(CNNativeComposition.allCases.count) compositions"
                 : resultLabel)
                .font(.system(size: 10)).tw("text-mutedForeground").padding(.top, 4)
                .accessibilityIdentifier("gallery-result-count")
        }
        CNSidebarContent("px-3 py-2") {
            ForEach(results.groups) { group in
                CNSidebarGroup {
                    CNSidebarGroupLabel(LocalizedStringKey(group.category.rawValue), classes: "text-[10] font-semibold")
                    CNSidebarMenu {
                        ForEach(group.components) { component in
                            GalleryNavigationRow(destination: .component(component), icon: component.icon,
                                isSelected: selection == .component(component), selection: $selection,
                                searchFocused: searchFocused).equatable()
                        }
                    }
                }
            }
            if !results.compositions.isEmpty {
                CNSidebarGroup {
                    CNSidebarGroupLabel("Native composition", classes: "text-[10] font-semibold")
                    CNSidebarMenu {
                        ForEach(results.compositions) { composition in
                            GalleryNavigationRow(destination: .native(composition), icon: "macwindow",
                                isSelected: selection == .native(composition), selection: $selection,
                                searchFocused: searchFocused).equatable()
                        }
                    }
                }
            }
            if results.count == 0 {
                CNEmpty("p-3 border-0") {
                    Image(systemName: "magnifyingglass").tw("text-mutedForeground")
                    CNEmptyTitle("No results", classes: "text-sm")
                    CNEmptyDescription("Try a component name.")
                    CNButton("Clear search", variant: .outline, size: .small, action: {
                        filter("")
                        searchReset += 1
                    })
                }
            }
        }
        CNSidebarFooter("px-4 pb-4 pt-2") {
            CNSeparator().padding(.bottom, 6)
            #if os(macOS)
            GallerySettingsButton()
            #endif
            CNButton(variant: .ghost, classes: "w-full px-2", action: {
                openURL(URL(string: "https://cbethin.github.io/swiftcn/docs/component-library/")!)
            }) {
                HStack {
                    Label("Documentation", systemImage: "book.closed")
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 10))
                }.tw("text-xs text-mutedForeground")
            }
        }
    }

    @ViewBuilder private var brandMark: some View {
        #if os(macOS)
        if Bundle.main.url(forResource: "SwiftCNAppIcon", withExtension: "icns") != nil {
            Image(nsImage: NSApplication.shared.applicationIconImage).resizable().scaledToFit()
                .frame(width: 44, height: 44)
        } else {
            fallbackMark
        }
        #else
        fallbackMark
        #endif
    }

    private var fallbackMark: some View {
        Image(systemName: "square.stack.3d.up.fill")
            .font(.system(size: 18, weight: .medium))
            .frame(width: 36, height: 36).tw("bg-primary text-onPrimary rounded-lg")
    }

    private func filter(_ query: String) {
        guard query != results.query else { return }
        results = GallerySearchResults(query)
    }

    private func submit(_ draft: String) {
        // Return uses the current draft even if its debounce has not fired.
        let current = GallerySearchResults(draft)
        results = current
        if let first = current.components.first { select(.component(first)) }
        else if let first = current.compositions.first { select(.native(first)) }
    }

    private func select(_ destination: CNGallerySelection) {
        selection = destination
        searchFocused.wrappedValue = false
        if sidebar.isCompact { sidebar.dismiss() }
    }
}

/// Only selection changes for the old and new rows need to rebuild their styled controls.
private struct GalleryNavigationRow: View, Equatable {
    let destination: CNGallerySelection
    let icon: String
    let isSelected: Bool
    @Binding var selection: CNGallerySelection
    var searchFocused: FocusState<Bool>.Binding

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.destination == rhs.destination && lhs.icon == rhs.icon && lhs.isSelected == rhs.isSelected
    }

    var body: some View {
        CNSidebarMenuButton(destination.title, systemImage: icon, isSelected: isSelected,
                            classes: "py-1 text-[12] rounded-lg", action: {
            selection = destination
            searchFocused.wrappedValue = false
        })
    }
}

private struct GalleryWorkspace: View {
    let selection: CNGallerySelection
    @Binding var mode: GalleryWorkspaceMode
    let isWide: Bool
    @State private var revision = 0
    @AppStorage(GalleryPreferences.previewGridKey) private var previewGrid = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                CNSegmentedControl(selection: $mode) {
                    ForEach(GalleryWorkspaceMode.allCases, id: \.self) { tab in
                        CNSegment(tab, classes: "text-xs px-3") {
                            Label(tab.rawValue, systemImage: tab.icon).fixedSize()
                        }.accessibilityLabel("\(tab.rawValue) mode")
                    }
                }.controlSize(.small).galleryChrome()
                Spacer()
                if isWide {
                    Text(selection.symbol).font(.system(size: 11, design: .monospaced))
                        .tw("text-mutedForeground").lineLimit(1)
                }
            }
            // The layout changes without removing the example. Edits survive view-mode changes.
            let horizontal = mode == .split && isWide
            let layout = horizontal ? AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                                    : AnyLayout(VStackLayout(alignment: .leading, spacing: mode == .split ? 16 : 0))
            layout {
                preview
                    .frame(maxWidth: .infinity)
                    .frame(height: mode == .code ? 0 : nil)
                    .opacity(mode == .code ? 0 : 1).clipped()
                    .disabled(mode == .code)
                    .allowsHitTesting(mode != .code).accessibilityHidden(mode == .code)
                GalleryCodePanel(source: selection.source, fileName: selection.fileName,
                                 fillsWidth: mode == .code, isVisible: mode != .preview)
                    .frame(width: horizontal ? 360 : nil)
                    .frame(maxWidth: horizontal ? nil : .infinity)
                    .frame(height: mode == .preview ? 0 : nil)
                    .opacity(mode == .preview ? 0 : 1).clipped()
                    .disabled(mode == .preview)
                    .allowsHitTesting(mode != .preview).accessibilityHidden(mode == .preview)
            }
            if ["CNDropdownMenu", "CNPopover", "CNHoverCard", "CNTooltip"].contains(where: selection.source.contains) {
                Label("Add .cnPopoverHost() at your window or screen root.", systemImage: "info.circle")
                    .font(.system(size: 11)).tw("text-mutedForeground").textSelection(.enabled)
            }
        }
    }

    @ViewBuilder private var exampleContent: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SWIFTCN_UI_PROBE"] == "long-combobox" {
            ComboboxInteractionProbe()
        } else { selection.example.id(revision) }
        #else
        selection.example.id(revision)
        #endif
    }

    private var preview: some View {
        CNCard("shadow-none rounded-xl") {
            HStack(spacing: 8) {
                Circle().fill(.green).frame(width: 5, height: 5).accessibilityHidden(true)
                Text("Live preview").font(.system(size: 11, weight: .medium))
                Spacer()
                CNButton(variant: .ghost, size: .small, classes: "px-2", action: { revision += 1 }) {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 11))
                }.accessibilityLabel("Reset example").help("Reset example").galleryChrome()
            }.padding(.horizontal, 16).frame(height: 48)
            CNSeparator()
            exampleContent
                .padding(isWide ? 28 : 20)
                .frame(maxWidth: .infinity, minHeight: isWide ? 390 : 200, alignment: .center)
                .background { if previewGrid { GalleryPreviewGrid() } }
            CNSeparator()
            HStack(spacing: 6) {
                Image(systemName: "cursorarrow.rays")
                Text("Interactive · Try it out")
                Spacer()
            }.font(.system(size: 10)).tw("text-mutedForeground")
                .padding(.horizontal, 16).frame(height: 36)
        }
    }
}

private struct GalleryPreviewGrid: View {
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Canvas { context, size in
            let color = theme.color(.mutedForeground, scheme: scheme).opacity(0.12)
            var dots = Path()
            for x in stride(from: 12.0, to: size.width, by: 20) {
                for y in stride(from: 12.0, to: size.height, by: 20) {
                    dots.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
            context.fill(dots, with: .color(color))
        }.accessibilityHidden(true).allowsHitTesting(false)
    }
}

#if DEBUG
private struct ComboboxInteractionProbe: View {
    @State private var selection: String?
    var body: some View {
        CNCombobox("Choose a workspace", options: (1...40).map { CNOption("\($0)", title: "Workspace \($0)") },
                   selection: $selection, searchPrompt: "Search workspaces…")
    }
}
#endif
