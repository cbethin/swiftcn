import SwiftUI

/// A custom month grid. SwiftUI Buttons retain native activation and accessibility.
public struct CNCalendar: View {
    @Environment(\.calendar) private var environmentCalendar
    @Environment(\.timeZone) private var timeZone
    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var direction
    @Binding private var date: Date
    @State private var visibleMonth: Date?
    @State private var focusedDate: Date?
    private let title: LocalizedStringKey
    private let range: ClosedRange<Date>
    private let classes: TWClasses
    private let dayClasses: TWClasses
    public init(_ title: LocalizedStringKey = "Date", selection: Binding<Date>,
                in range: ClosedRange<Date> = Date.distantPast...Date.distantFuture,
                classes: TWClasses = "", dayClasses: TWClasses = "") {
        self.title = title; _date = selection; self.range = range
        self.classes = classes; self.dayClasses = dayClasses
    }
    private var calendar: Calendar {
        var value = environmentCalendar; value.timeZone = timeZone; value.locale = locale; return value
    }
    private var month: Date {
        CNCalendarGrid.month(containing: visibleMonth ?? date, in: range, calendar: calendar)
    }
    private var days: [Date] { CNCalendarGrid.days(in: month, calendar: calendar) }
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }
    private var monthLabel: String {
        let formatter = DateFormatter(); formatter.locale = locale; formatter.calendar = calendar
        formatter.timeZone = timeZone; formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: month)
    }
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                navigationButton(-1, title: "Previous month", image: "chevron.backward")
                Text(monthLabel).tw("calendar-heading w-full text-center").accessibilityAddTraits(.isHeader)
                navigationButton(1, title: "Next month", image: "chevron.forward")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(weekdaySymbols[index]).tw("calendar-weekday w-full text-center h-6")
                        .accessibilityHidden(true)
                }
                ForEach(days, id: \.self) { day in
                    CNCalendarDay(day, calendar: calendar, locale: locale,
                                  isSelected: calendar.isDate(day, inSameDayAs: date),
                                  isToday: calendar.isDateInToday(day),
                                  isOutsideMonth: !calendar.isDate(day, equalTo: month, toGranularity: .month),
                                  classes: dayClasses, focus: $focusedDate) {
                        if let selected = CNCalendarGrid.selection(for: day, in: range, calendar: calendar) { date = selected }
                    }
                    .disabled(CNCalendarGrid.selection(for: day, in: range, calendar: calendar) == nil)
                    .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow, .pageUp, .pageDown]) { key in
                        moveFocus(from: day, key: key.key); return .handled
                    }
                }
            }
            .id(month)
            .transition(.opacity)
        }
        .tw(cn("calendar", widthClasses, "disclosure-motion", classes), value: month, animationScope: .content)
        .accessibilityElement(children: .contain).accessibilityLabel(Text(title))
        .onChange(of: date) { _, _ in visibleMonth = nil }
        .onChange(of: timeZone) { _, _ in visibleMonth = nil }
        .onChange(of: environmentCalendar) { _, _ in visibleMonth = nil }
        .onChange(of: range) { _, _ in
            visibleMonth = month
            if let focusedDate, CNCalendarGrid.selection(for: focusedDate, in: range, calendar: calendar) == nil {
                self.focusedDate = nil
            }
        }
    }
    private func moveFocus(from day: Date, key: KeyEquivalent) {
        let component: Calendar.Component = key == .pageUp || key == .pageDown ? .month : .day
        let offset: Int
        switch key {
        case .leftArrow: offset = direction == .rightToLeft ? 1 : -1
        case .rightArrow: offset = direction == .rightToLeft ? -1 : 1
        case .upArrow: offset = -7
        case .downArrow: offset = 7
        case .pageUp: offset = -1
        default: offset = 1
        }
        guard let next = calendar.date(byAdding: component, value: offset, to: day),
              CNCalendarGrid.selection(for: next, in: range, calendar: calendar) != nil else { return }
        focusedDate = next
        visibleMonth = CNCalendarGrid.month(containing: next, calendar: calendar)
    }
    private var widthClasses: TWClasses {
        #if os(iOS)
        "w-full max-w-[356]"
        #else
        "w-full max-w-[300]"
        #endif
    }
    private func navigationButton(_ offset: Int, title: LocalizedStringKey, image: String) -> some View {
        CNButton(variant: .ghost, size: .icon, classes: "border px-0 py-0", action: {
            guard let next = CNCalendarGrid.adjacent(to: month, offset: offset, in: range, calendar: calendar) else { return }
            visibleMonth = next
        }) { Image(systemName: image).tw("text-xs").accessibilityHidden(true) }
            .accessibilityLabel(Text(title))
            .disabled(CNCalendarGrid.adjacent(to: month, offset: offset, in: range, calendar: calendar) == nil)
    }
}

/// Reuse a day cell in a custom calendar layout, or override its shared recipes.
public struct CNCalendarDay: View {
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var focused: Bool
    private let date: Date
    private let calendar: Calendar
    private let locale: Locale
    private let selected: Bool
    private let today: Bool
    private let outside: Bool
    private let classes: TWClasses
    private let action: () -> Void
    private let externalFocus: Binding<Date?>?
    public init(_ date: Date, calendar: Calendar = .current, locale: Locale = .current,
                isSelected: Bool = false, isToday: Bool = false, isOutsideMonth: Bool = false,
                classes: TWClasses = "", focus: Binding<Date?>? = nil, action: @escaping () -> Void) {
        self.date = date; self.calendar = calendar; self.locale = locale
        selected = isSelected; today = isToday; outside = isOutsideMonth
        self.classes = classes; self.action = action; externalFocus = focus
    }
    private var dayLabel: String {
        date.formatted(Date.FormatStyle(date: .complete, time: .omitted, locale: locale,
                                       calendar: calendar, timeZone: calendar.timeZone))
    }
    public var body: some View {
        Button(action: action) { Text(calendar.component(.day, from: date), format: .number.locale(locale)).tw("w-full") }
            .focusable().focusEffectDisabled().focused($focused)
            .buttonStyle(.tw(cn("calendar-day", cellHeight,
                                outside ? "calendar-outside" : "",
                                today && !selected ? "calendar-today" : "",
                                selected ? "calendar-selected" : "", classes), state: .init(isFocused: focused)))
            .onChange(of: externalFocus?.wrappedValue, initial: true) { _, value in
                focused = value == date
            }
            .onChange(of: focused) { _, value in if value { externalFocus?.wrappedValue = date } }
            .onKeyPress(keys: [.return, .space]) { _ in guard isEnabled else { return .ignored }; action(); return .handled }
            .accessibilityLabel(dayLabel)
            .accessibilityValue(today ? Text("Today") : Text(""))
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
    private var cellHeight: TWClasses {
        #if os(iOS)
        "h-[44]"
        #else
        "h-9"
        #endif
    }
}

// Calendar arithmetic uses day addition rather than fixed seconds across DST.
enum CNCalendarGrid {
    static func month(containing date: Date, in range: ClosedRange<Date>, calendar: Calendar) -> Date {
        month(containing: min(max(date, range.lowerBound), range.upperBound), calendar: calendar)
    }
    static func month(containing date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }
    static func days(in month: Date, calendar: Calendar) -> [Date] {
        let start = self.month(containing: month, calendar: calendar)
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        guard let first = calendar.date(byAdding: .day, value: -offset, to: start) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
    }
    static func selection(for day: Date, in range: ClosedRange<Date>, calendar: Calendar) -> Date? {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start),
              end > range.lowerBound, start <= range.upperBound else { return nil }
        return max(start, range.lowerBound)
    }
    static func adjacent(to month: Date, offset: Int, in range: ClosedRange<Date>, calendar: Calendar) -> Date? {
        guard let next = calendar.date(byAdding: .month, value: offset, to: self.month(containing: month, calendar: calendar)),
              let interval = calendar.dateInterval(of: .month, for: next),
              interval.end > range.lowerBound, interval.start <= range.upperBound else { return nil }
        return interval.start
    }
}
