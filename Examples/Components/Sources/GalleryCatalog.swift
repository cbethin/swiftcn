import Foundation

enum GalleryCategory: String, CaseIterable, Identifiable {
    case essentials = "Essentials"
    case forms = "Forms & selection"
    case navigation = "Navigation"
    case surfaces = "Layout & overlays"
    case data = "Data display"
    case feedback = "Feedback"
    case conversation = "Conversation"
    var id: Self { self }
}

extension CNComponentGallery {
    var icon: String {
        switch self {
        case .aspect_ratio: "aspectratio"
        case .avatar: "person.crop.circle"
        case .badge: "seal"
        case .button: "cursorarrow.click"
        case .button_group: "rectangle.split.3x1"
        case .card: "rectangle"
        case .direction: "arrow.left.arrow.right"
        case .item: "list.bullet.rectangle"
        case .kbd: "keyboard"
        case .label: "tag"
        case .separator: "minus"
        case .typography: "textformat"
        case .calendar, .date_picker: "calendar"
        case .checkbox: "checkmark.square"
        case .combobox, .select, .native_select: "chevron.up.chevron.down"
        case .field, .input, .input_group: "rectangle.and.pencil.and.ellipsis"
        case .input_otp: "number.square"
        case .radio_group: "smallcircle.filled.circle"
        case .slider: "slider.horizontal.3"
        case .switch, .toggle, .toggle_group, .segmented_control: "switch.2"
        case .textarea: "text.alignleft"
        case .breadcrumb: "chevron.right.2"
        case .command: "command"
        case .menubar, .navigation_menu: "menubar.rectangle"
        case .pagination: "ellipsis"
        case .sidebar: "sidebar.leading"
        case .tabs: "rectangle.topthird.inset.filled"
        case .accordion, .collapsible: "chevron.down"
        case .carousel: "rectangle.on.rectangle"
        case .context_menu, .dropdown_menu: "filemenu.and.selection"
        case .dialog, .alert_dialog: "macwindow"
        case .drawer, .sheet: "rectangle.bottomthird.inset.filled"
        case .hover_card, .popover, .tooltip: "bubble.right"
        case .resizable: "rectangle.split.2x1"
        case .scroll_area: "scroll"
        case .chart: "chart.bar.xaxis"
        case .data_table, .table: "tablecells"
        case .alert: "exclamationmark.circle"
        case .empty: "tray"
        case .progress: "chart.bar.fill"
        case .skeleton: "rectangle.dashed"
        case .spinner: "circle.dotted"
        case .toast: "bell"
        case .attachment: "paperclip"
        case .bubble, .message, .message_scroller: "bubble.left.and.bubble.right"
        case .marker: "bookmark"
        case .questionnaire: "list.clipboard"
        }
    }

    var category: GalleryCategory {
        switch self {
        case .button, .button_group, .badge, .avatar, .card, .typography, .label, .kbd,
             .separator, .aspect_ratio, .direction, .item: .essentials
        case .checkbox, .combobox, .date_picker, .field, .input, .input_group, .input_otp,
             .native_select, .radio_group, .select, .slider, .switch, .textarea,
             .toggle, .toggle_group, .segmented_control, .calendar: .forms
        case .breadcrumb, .command, .menubar, .navigation_menu, .pagination, .sidebar, .tabs: .navigation
        case .accordion, .alert_dialog, .collapsible, .context_menu, .dialog, .drawer, .dropdown_menu,
             .hover_card, .popover, .resizable, .scroll_area, .sheet, .tooltip, .carousel: .surfaces
        case .chart, .data_table, .table: .data
        case .alert, .empty, .progress, .skeleton, .spinner, .toast: .feedback
        case .attachment, .bubble, .marker, .message, .message_scroller, .questionnaire: .conversation
        }
    }

    func matches(_ query: String) -> Bool {
        query.isEmpty || title.localizedStandardContains(query)
            || category.rawValue.localizedStandardContains(query)
            || (Self.searchSymbols[rawValue]?.localizedStandardContains(query) ?? false)
    }

    // Extract source-derived names once, rather than parsing every example while the user types.
    private static let searchSymbols: [String: String] = Dictionary(uniqueKeysWithValues:
        allCases.map { ($0.rawValue, CNGallerySelection.component($0).symbol) })

    var summary: String {
        switch self {
        case .accordion: "Expandable sections with native disclosure controls and caller-owned state."
        case .alert: "Keep important context in view with an inline message and optional actions."
        case .alert_dialog: "Ask for a deliberate decision before an important or destructive action."
        case .aspect_ratio: "Keep images, media, and custom content in a consistent proportion."
        case .attachment: "Compose file previews, metadata, and actions in a compact attachment."
        case .avatar: "A familiar identity for people and teams, with a fallback when images are unavailable."
        case .badge: "Small, expressive labels for status, categories, and counts."
        case .breadcrumb: "A quiet trail that helps people understand where they are."
        case .bubble: "Message surfaces with clear roles and flexible content."
        case .button: "Native buttons with clear hierarchy, flexible labels, and styles you can make your own."
        case .button_group: "Bring related actions together while adapting to the available space."
        case .calendar: "Browse months and choose a date with keyboard and accessibility support."
        case .card: "A flexible surface for related content, with composable headers, footers, and actions."
        case .carousel: "Move through a collection with native scrolling and explicit navigation."
        case .chart: "Turn data into readable charts with native Swift Charts."
        case .checkbox: "A native checkbox with a generous activation area and caller-owned state."
        case .collapsible: "Reveal supporting content without leaving the current view."
        case .combobox: "Find and select an option from a searchable, keyboard-accessible list."
        case .command: "A searchable command surface with shared filtering, selection, and keyboard navigation."
        case .context_menu: "Put relevant native actions directly alongside the content they affect."
        case .data_table: "Native columns, sorting, and selection for structured collections."
        case .date_picker: "A formatted date input with a calendar and optional native time selection."
        case .dialog: "A focused surface for a short task, with clear dismissal and preserved edits."
        case .direction: "Compose interfaces that respect left-to-right and right-to-left layouts."
        case .drawer: "A native sheet with styled content, presentation detents, and caller-owned state."
        case .dropdown_menu: "Organize related actions in a menu anchored to its trigger."
        case .empty: "Give an empty view a clear explanation and a useful next action."
        case .field: "Bring labels, inputs, descriptions, and validation messages into one composition."
        case .hover_card: "Offer a little more context without interrupting the current task."
        case .input: "Native text editing with familiar focus, selection, and input behavior."
        case .input_group: "Compose an input with icons, prefixes, suffixes, and action buttons."
        case .input_otp: "A single native input for verification codes, with paste and autofill support."
        case .item: "A reusable row for an icon, title, description, and supporting actions."
        case .kbd: "Make keyboard shortcuts easy to recognize in labels and instructions."
        case .label: "Consistent labels that fit naturally beside native controls."
        case .marker: "Add clear milestones and annotations between conversation turns."
        case .menubar: "Compose groups of native menus for familiar desktop actions."
        case .message: "Compose conversation content, metadata, and actions in one readable message."
        case .message_scroller: "Follow new conversation content while respecting the reader's scroll position."
        case .native_select: "Use the platform's own picker presentation with SwiftCN styling."
        case .navigation_menu: "A compact menu of destinations with native interaction."
        case .pagination: "Navigate large collections with bounded page controls and adaptive labels."
        case .popover: "A lightweight, anchored surface for contextual content and controls."
        case .progress: "Show measurable progress or ongoing activity with native progress views."
        case .questionnaire: "Guide people through controlled questions, answers, and validation."
        case .radio_group: "Choose one option with native picker behavior and accessible labels."
        case .resizable: "Let people adjust neighboring panes with an accessible divider."
        case .scroll_area: "Native scrolling with configurable axes and indicators."
        case .segmented_control: "Compose a single selection with flexible labels, shared styling, and keyboard navigation."
        case .select: "Choose from a stable set of options through a native menu picker."
        case .separator: "Create a quiet boundary between related groups of content."
        case .sheet: "Present a focused panel from an edge, with reversible motion and clear dismissal."
        case .sidebar: "Persistent navigation that adapts from a desktop sidebar to a compact drawer."
        case .skeleton: "Reserve the shape of loading content with motion that respects system preferences."
        case .slider: "Adjust a numeric value using native gestures, keyboard controls, and accessibility."
        case .spinner: "A compact activity indicator with an accessible label and controlled motion."
        case .switch: "A native on/off control with a full activation row."
        case .table: "Compose structured rows, headers, and cells with selection and embedded controls."
        case .tabs: "Switch between related views with a native TabView and stable selection."
        case .textarea: "A styled native text editor for longer, freely editable content."
        case .toast: "Transient updates with optional actions and reading-aware dismissal."
        case .toggle: "A button-shaped toggle that keeps its native state and accessibility."
        case .toggle_group: "A coordinated set of toggles with stable options and adaptive layout."
        case .tooltip: "A short description that helps explain an icon or unfamiliar control."
        case .typography: "A consistent type hierarchy built from native text and semantic styles."
        }
    }
}

extension CNGallerySelection {
    var sectionTitle: String {
        switch self {
        case .component(let component): component.category.rawValue
        case .native: "Native composition"
        }
    }
    var summary: String {
        switch self {
        case .component(let component): component.summary
        case .native(let composition):
            switch composition {
            case .styles: "Use SwiftCN recipes directly on native buttons, inputs, toggles, and labels."
            case .drawer: "Build sheet content with SwiftCN while the platform owns its presentation."
            case .surfaces: "Compose adaptive surfaces and Liquid Glass with native controls and editable recipes."
            case .navigation: "A complete navigation root with native columns and compact navigation."
            case .split: "Arrange desktop workspaces with native split views and flexible detail panes."
            case .arrangement: "A complete workspace with panes that adapt to the available display."
            case .models: "Connect observable models to component content while keeping state in your app."
            }
        }
    }
    var symbol: String {
        switch self {
        case .component:
            // The example declaration preserves initialisms such as OTP and Kbd.
            "CN" + fileName.replacingOccurrences(of: "Example.swift", with: "")
        case .native: "import SwiftCN"
        }
    }
    var fileName: String {
        // Examples include a complete declaration. Read its name instead of deriving initialisms from a slug.
        if let start = source.range(of: "struct "),
           let end = source[start.upperBound...].firstIndex(of: ":") {
            return String(source[start.upperBound..<end]).trimmingCharacters(in: .whitespaces) + ".swift"
        }
        return "Example.swift"
    }
}
