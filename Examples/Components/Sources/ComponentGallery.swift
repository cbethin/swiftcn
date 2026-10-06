import SwiftUI
import SwiftCN

enum CNComponentGallery: String, CaseIterable, Identifiable {
    case accordion
    case alert
    case alert_dialog
    case aspect_ratio
    case attachment
    case avatar
    case badge
    case breadcrumb
    case bubble
    case button
    case button_group
    case calendar
    case card
    case carousel
    case chart
    case checkbox
    case collapsible
    case combobox
    case command
    case context_menu
    case data_table
    case date_picker
    case dialog
    case direction
    case drawer
    case dropdown_menu
    case empty
    case field
    case hover_card
    case input
    case input_group
    case input_otp
    case item
    case kbd
    case label
    case marker
    case menubar
    case message
    case message_scroller
    case native_select
    case navigation_menu
    case pagination
    case popover
    case progress
    case questionnaire
    case radio_group
    case resizable
    case scroll_area
    case select
    case separator
    case sheet
    case sidebar
    case skeleton
    case slider
    case spinner
    case `switch`
    case table
    case tabs
    case textarea
    case toast
    case toggle
    case toggle_group
    case tooltip
    case typography
    var id: String { rawValue }
    @MainActor var previewExample: AnyView {
        switch self {
        case .dropdown_menu: AnyView(DropdownMenuExample(showsInlinePreview: true))
        case .sidebar: AnyView(SidebarExample(initialMobilePresented: true))
        default: example
        }
    }
    var title: String {
        switch self {
        case .accordion: "Accordion"
        case .alert: "Alert"
        case .alert_dialog: "Alert Dialog"
        case .aspect_ratio: "Aspect Ratio"
        case .attachment: "Attachment"
        case .avatar: "Avatar"
        case .badge: "Badge"
        case .breadcrumb: "Breadcrumb"
        case .bubble: "Bubble"
        case .button: "Button"
        case .button_group: "Button Group"
        case .calendar: "Calendar"
        case .card: "Card"
        case .carousel: "Carousel"
        case .chart: "Chart"
        case .checkbox: "Checkbox"
        case .collapsible: "Collapsible"
        case .combobox: "Combobox"
        case .command: "Command"
        case .context_menu: "Context Menu"
        case .data_table: "Data Table"
        case .date_picker: "Date Picker"
        case .dialog: "Dialog"
        case .direction: "Direction"
        case .drawer: "Drawer"
        case .dropdown_menu: "Dropdown Menu"
        case .empty: "Empty"
        case .field: "Field"
        case .hover_card: "Hover Card"
        case .input: "Input"
        case .input_group: "Input Group"
        case .input_otp: "Input OTP"
        case .item: "Item"
        case .kbd: "Kbd"
        case .label: "Label"
        case .marker: "Marker"
        case .menubar: "Menubar"
        case .message: "Message"
        case .message_scroller: "Message Scroller"
        case .native_select: "Native Select"
        case .navigation_menu: "Navigation Menu"
        case .pagination: "Pagination"
        case .popover: "Popover"
        case .progress: "Progress"
        case .questionnaire: "Questionnaire"
        case .radio_group: "Radio Group"
        case .resizable: "Resizable"
        case .scroll_area: "Scroll Area"
        case .select: "Select"
        case .separator: "Separator"
        case .sheet: "Sheet"
        case .sidebar: "Sidebar"
        case .skeleton: "Skeleton"
        case .slider: "Slider"
        case .spinner: "Spinner"
        case .switch: "Switch"
        case .table: "Table"
        case .tabs: "Tabs"
        case .textarea: "Textarea"
        case .toast: "Toast"
        case .toggle: "Toggle"
        case .toggle_group: "Toggle Group"
        case .tooltip: "Tooltip"
        case .typography: "Typography"
        }
    }
    @MainActor var example: AnyView {
        switch self {
        case .accordion: AnyView(AccordionExample())
        case .alert: AnyView(AlertExample())
        case .alert_dialog: AnyView(AlertDialogExample())
        case .aspect_ratio: AnyView(AspectRatioExample())
        case .attachment: AnyView(AttachmentExample())
        case .avatar: AnyView(AvatarExample())
        case .badge: AnyView(BadgeExample())
        case .breadcrumb: AnyView(BreadcrumbExample())
        case .bubble: AnyView(BubbleExample())
        case .button: AnyView(ButtonExample())
        case .button_group: AnyView(ButtonGroupExample())
        case .calendar: AnyView(CalendarExample())
        case .card: AnyView(CardExample())
        case .carousel: AnyView(CarouselExample())
        case .chart: AnyView(ChartExample())
        case .checkbox: AnyView(CheckboxExample())
        case .collapsible: AnyView(CollapsibleExample())
        case .combobox: AnyView(ComboboxExample())
        case .command: AnyView(CommandExample())
        case .context_menu: AnyView(ContextMenuExample())
        case .data_table: AnyView(DataTableExample())
        case .date_picker: AnyView(DatePickerExample())
        case .dialog: AnyView(DialogExample())
        case .direction: AnyView(DirectionExample())
        case .drawer: AnyView(DrawerExample())
        case .dropdown_menu: AnyView(DropdownMenuExample())
        case .empty: AnyView(EmptyExample())
        case .field: AnyView(FieldExample())
        case .hover_card: AnyView(HoverCardExample())
        case .input: AnyView(InputExample())
        case .input_group: AnyView(InputGroupExample())
        case .input_otp: AnyView(InputOTPExample())
        case .item: AnyView(ItemExample())
        case .kbd: AnyView(KbdExample())
        case .label: AnyView(LabelExample())
        case .marker: AnyView(MarkerExample())
        case .menubar: AnyView(MenubarExample())
        case .message: AnyView(MessageExample())
        case .message_scroller: AnyView(MessageScrollerExample())
        case .native_select: AnyView(NativeSelectExample())
        case .navigation_menu: AnyView(NavigationMenuExample())
        case .pagination: AnyView(PaginationExample())
        case .popover: AnyView(PopoverExample())
        case .progress: AnyView(ProgressExample())
        case .questionnaire: AnyView(QuestionnaireExample())
        case .radio_group: AnyView(RadioGroupExample())
        case .resizable: AnyView(ResizableExample())
        case .scroll_area: AnyView(ScrollAreaExample())
        case .select: AnyView(SelectExample())
        case .separator: AnyView(SeparatorExample())
        case .sheet: AnyView(SheetExample())
        case .sidebar: AnyView(SidebarExample())
        case .skeleton: AnyView(SkeletonExample())
        case .slider: AnyView(SliderExample())
        case .spinner: AnyView(SpinnerExample())
        case .switch: AnyView(SwitchExample())
        case .table: AnyView(TableExample())
        case .tabs: AnyView(TabsExample())
        case .textarea: AnyView(TextareaExample())
        case .toast: AnyView(ToastExample())
        case .toggle: AnyView(ToggleExample())
        case .toggle_group: AnyView(ToggleGroupExample())
        case .tooltip: AnyView(TooltipExample())
        case .typography: AnyView(TypographyExample())
        }
    }
}
