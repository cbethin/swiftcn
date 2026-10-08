import SwiftUI
import SwiftCN

public struct CNSlider: View {
    private let title: LocalizedStringKey
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let classes: TWClasses
    private let onEditingChanged: (Bool) -> Void
    public init(_ title: LocalizedStringKey, value: Binding<Double>, in range: ClosedRange<Double> = 0...1,
                step: Double = 0.01, classes: TWClasses = "", onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        precondition(range.lowerBound.isFinite && range.upperBound.isFinite && step.isFinite && step > 0)
        self.title = title; _value = value; self.range = range; self.step = step
        self.classes = classes; self.onEditingChanged = onEditingChanged
    }
    public var body: some View {
        Slider(value: $value, in: range, step: step, onEditingChanged: onEditingChanged) { Text(title) }
            .tw(cn("slider", classes)).cnControlUtilities()
    }
}
public struct CNProgress: View {
    private let title: LocalizedStringKey
    private let value: Double?
    private let total: Double
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey, value: Double? = nil, total: Double = 1, classes: TWClasses = "") {
        precondition(total.isFinite && total > 0)
        self.title = title; self.value = value.map { $0.isFinite ? min(total, max(0, $0)) : 0 }
        self.total = total; self.classes = classes
    }
    public var body: some View {
        ProgressView(title, value: value, total: total).tw(cn("progress feedback-motion", classes), value: value, animationScope: .content).cnControlUtilities()
    }
}
public struct CNDatePicker: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone
    @FocusState private var fieldFocused: Bool
    @FocusState private var triggerFocused: Bool
    @State private var calendarPresented = false
    private let title: LocalizedStringKey
    @Binding private var date: Date
    private let range: ClosedRange<Date>
    private let components: DatePickerComponents
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey, selection: Binding<Date>,
                in range: ClosedRange<Date> = Date.distantPast...Date.distantFuture,
                displayedComponents: DatePickerComponents = .date, classes: TWClasses = "") {
        self.title = title; _date = selection; self.range = range; components = displayedComponents; self.classes = classes
    }
    private var format: Date.FormatStyle {
        Date.FormatStyle(date: .numeric, time: components.contains(.hourAndMinute) ? .shortened : .omitted,
                         locale: locale, calendar: calendar, timeZone: timeZone)
    }
    private var selection: Binding<Date> {
        Binding(get: { date }, set: { proposed in
            var localCalendar = calendar; localCalendar.timeZone = timeZone
            date = CNDatePickerSelection.resolve(proposed, preservingTimeFrom: date,
                preserveTime: !components.contains(.hourAndMinute), in: range, calendar: localCalendar)
        })
    }
    private var calendarSelection: Binding<Date> {
        Binding(get: { date }, set: { selected in
            var localCalendar = calendar; localCalendar.timeZone = timeZone
            date = CNDatePickerSelection.resolve(selected, preservingTimeFrom: date,
                preserveTime: true, in: range, calendar: localCalendar)
            if !components.contains(.hourAndMinute) { calendarPresented = false }
        })
    }
    private var field: some View {
        TextField(title, value: selection, format: format).textFieldStyle(.plain)
            .focused($fieldFocused).tw("input-group-field")
            .accessibilityLabel(Text(title))
    }
    private var calendarButton: some View {
        Button { fieldFocused = false; calendarPresented.toggle() } label: {
            Image(systemName: "calendar").accessibilityHidden(true)
        }
        .focused($triggerFocused)
        .buttonStyle(.tw("button-ghost px-2 py-0 text-mutedForeground"))
        .accessibilityLabel("Choose date")
        .accessibilityValue(calendarPresented ? Text("Expanded") : Text("Collapsed"))
    }
    private var calendarContent: some View {
        VStack(spacing: 8) {
            CNCalendar(title, selection: calendarSelection, in: range,
                       classes: "date-picker-calendar", dayClasses: calendarDayClasses)
            if components.contains(.hourAndMinute) {
                DatePicker("Time", selection: $date, in: range, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact).tw("px-3")
                CNButton("Done", variant: .ghost, action: { calendarPresented = false })
            }
        }.tw("popover p-1")
    }
    @ViewBuilder public var body: some View {
        if components.contains(.date) {
            VStack(alignment: .leading, spacing: 8) {
                CNLabel { Text(title) }
                CNInputGroup(focus: $fieldFocused) {
                    field
                    calendarButton
                }
                .cnPopover(isPresented: $calendarPresented, alignment: .center) { calendarContent }
            }.tw(cn("date-picker", classes)).cnControlUtilities()
                .onChange(of: calendarPresented) { _, open in
                    if open { fieldFocused = false }
                    else { triggerFocused = true }
                }
        } else {
            DatePicker(title, selection: $date, in: range, displayedComponents: components)
                .datePickerStyle(.compact).tw(cn("date-picker", classes)).cnControlUtilities()
        }
    }
    private var calendarDayClasses: TWClasses {
        #if os(iOS)
        ""
        #else
        "h-[32]"
        #endif
    }
}

enum CNDatePickerSelection {
    static func resolve(_ proposed: Date, preservingTimeFrom current: Date, preserveTime: Bool,
                        in range: ClosedRange<Date>, calendar: Calendar) -> Date {
        let resolved: Date
        if preserveTime {
            let time = calendar.dateComponents([.hour, .minute, .second], from: current)
            resolved = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0,
                                     second: time.second ?? 0, of: proposed) ?? proposed
        } else {
            resolved = proposed
        }
        return min(max(resolved, range.lowerBound), range.upperBound)
    }
}
