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
    @State private var query = ""
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var mobilePresented = false
    @State private var mode: GalleryWorkspaceMode = .split
    @FocusState private var searchFocused: Bool
    @Binding var dark: Bool

    var body: some View {
        CNSidebar(visibility: $visibility, mobilePresented: $mobilePresented,
                  collapsible: .offcanvas, width: 248, compactBreakpoint: 740) {
            GalleryNavigation(selection: $selection, query: $query, searchFocused: $searchFocused,
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
        .onChange(of: dark, initial: true) { _, dark in
            NSApplication.shared.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        }
        #endif
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            CNSidebarTrigger().keyboardShortcut("b", modifiers: [.command, .shift])
            CNSeparator(axis: .vertical).frame(height: 16)
            CNBreadcrumb {
                Text(selection.sectionTitle).tw("text-sm text-mutedForeground")
                CNBreadcrumbSeparator()
                CNBreadcrumbPage(LocalizedStringKey(selection.title))
            }.lineLimit(1)
            Spacer(minLength: 8)
            GalleryAppearanceControl(dark: $dark)
        }
        .padding(.horizontal, 20).frame(height: 58)
        .tw("bg-surface")
        .galleryChrome()
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

private struct GalleryNavigation: View {
    @Binding var selection: CNGallerySelection
    @Binding var query: String
    var searchFocused: FocusState<Bool>.Binding
    let onSearch: () -> Void
    @Environment(\.cnSidebarContext) private var sidebar
    @Environment(\.openURL) private var openURL
    @Environment(\.twTheme) private var theme
    @Environment(\.colorScheme) private var scheme

    private var search: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var matches: [CNComponentGallery] {
        CNComponentGallery.allCases.filter { $0.matches(search) }
    }
    private var nativeMatches: [CNNativeComposition] {
        CNNativeComposition.allCases.filter {
            search.isEmpty || $0.title.localizedStandardContains(search) || "Native composition".localizedStandardContains(search)
        }
    }
    private var resultLabel: String {
        let count = matches.count + nativeMatches.count
        return count == 1 ? "1 result" : "\(count) results"
    }

    var body: some View {
        CNSidebarHeader("p-5 pb-3") {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 36, height: 36).tw("bg-primary text-onPrimary rounded-lg")
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("SwiftCN").font(.system(size: 18, weight: .semibold)).tracking(-0.5)
                    Text("Native components").font(.system(size: 11)).tw("text-mutedForeground")
                }
                Spacer(minLength: 0)
                if sidebar.isCompact { CNSidebarTrigger() }
            }.padding(.bottom, 16)
            CNInputGroup("px-2 rounded-lg hover:border-foreground animate-smooth duration-120 motion-reduce:animate-none", focus: searchFocused) {
                CNButton(variant: .ghost, size: .small, classes: "px-0", action: onSearch) {
                    Image(systemName: "magnifyingglass").tw("text-mutedForeground")
                }.keyboardShortcut("k", modifiers: .command).accessibilityLabel("Search components")
                CNInputGroupField("Search components…", text: $query)
                    .accessibilityIdentifier("gallery-search")
                if !query.isEmpty {
                    CNButton(variant: .ghost, size: .small, classes: "px-0", action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill").tw("text-mutedForeground")
                    }.accessibilityLabel("Clear search")
                }
            }
            .onSubmit {
                if let first = matches.first { select(.component(first)) }
                else if let first = nativeMatches.first { select(.native(first)) }
            }
            .onKeyPress(.escape) {
                guard !query.isEmpty else { return .ignored }
                query = ""; return .handled
            }
            Text(search.isEmpty ? "\(CNComponentGallery.allCases.count) components · \(CNNativeComposition.allCases.count) compositions"
                 : resultLabel)
                .font(.system(size: 10)).tw("text-mutedForeground").padding(.top, 4)
                .accessibilityIdentifier("gallery-result-count")
        }
        CNSidebarContent("px-3 py-2") {
            ForEach(GalleryCategory.allCases) { category in
                let components = matches.filter { $0.category == category }
                if !components.isEmpty {
                    CNSidebarGroup {
                        CNSidebarGroupLabel(LocalizedStringKey(category.rawValue), classes: "text-[10] font-semibold")
                        CNSidebarMenu {
                            ForEach(components) { component in
                                CNSidebarMenuButton(component.title, systemImage: component.icon,
                                    isSelected: selection == .component(component),
                                    classes: "py-1 text-[12] rounded-lg",
                                    action: { select(.component(component)) })
                                    .background(selection == .component(component) ? theme.color(.accent, scheme: scheme) : .clear,
                                                in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            if !nativeMatches.isEmpty {
                CNSidebarGroup {
                    CNSidebarGroupLabel("Native composition", classes: "text-[10] font-semibold")
                    CNSidebarMenu {
                        ForEach(nativeMatches) { composition in
                            CNSidebarMenuButton(composition.title, systemImage: "macwindow",
                                isSelected: selection == .native(composition), classes: "py-1 text-[12] rounded-lg",
                                action: { select(.native(composition)) })
                                .background(selection == .native(composition) ? theme.color(.accent, scheme: scheme) : .clear,
                                            in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            if matches.isEmpty && nativeMatches.isEmpty {
                CNEmpty("p-3 border-0") {
                    Image(systemName: "magnifyingglass").tw("text-mutedForeground")
                    CNEmptyTitle("No results", classes: "text-sm")
                    CNEmptyDescription("Try a component name.")
                    CNButton("Clear search", variant: .outline, size: .small, action: { query = "" })
                }
            }
        }
        CNSidebarFooter("px-4 pb-4 pt-2") {
            CNSeparator().padding(.bottom, 6)
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

    private func select(_ destination: CNGallerySelection) {
        selection = destination
        searchFocused.wrappedValue = false
        if sidebar.isCompact { sidebar.dismiss() }
    }
}

private struct GalleryWorkspace: View {
    let selection: CNGallerySelection
    @Binding var mode: GalleryWorkspaceMode
    let isWide: Bool
    @State private var revision = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 2) {
                    ForEach(GalleryWorkspaceMode.allCases, id: \.self) { tab in
                        CNButton(variant: modeVariant(for: tab), size: .small,
                                 classes: cn("text-xs px-3 rounded-md",
                                     mode == tab ? "bg-surface border shadow-sm hover:bg-accent pressed:bg-border" : ""),
                                 action: { mode = tab }) {
                            Label(tab.rawValue, systemImage: tab.icon).fixedSize()
                        }
                        .accessibilityLabel("\(tab.rawValue) mode")
                        .accessibilityAddTraits(mode == tab ? .isSelected : [])
                    }
                }.tw("p-1 bg-muted rounded-lg").galleryChrome()
                Spacer()
                Text(selection.symbol).font(.system(size: 11, design: .monospaced))
                    .tw("text-mutedForeground").lineLimit(1).minimumScaleFactor(0.8)
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
                                 fillsWidth: mode == .code)
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

    private func modeVariant(for tab: GalleryWorkspaceMode) -> CNButtonVariant {
        #if os(macOS)
        .ghost
        #else
        mode == tab ? .outline : .ghost
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
            selection.example.id(revision)
                .padding(28)
                .frame(maxWidth: .infinity, minHeight: 390, alignment: .center)
                .background { GalleryPreviewGrid() }
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
            for x in stride(from: 12.0, to: size.width, by: 20) {
                for y in stride(from: 12.0, to: size.height, by: 20) {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(color))
                }
            }
        }.accessibilityHidden(true).allowsHitTesting(false)
    }
}
