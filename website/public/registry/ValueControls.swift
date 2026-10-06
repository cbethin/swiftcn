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
public struct CNSpinner: View {
    private let title: LocalizedStringKey
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey = "Loading", classes: TWClasses = "") { self.title = title; self.classes = classes }
    public var body: some View {
        ProgressView(title).progressViewStyle(.circular).tw(cn("spinner", classes)).cnControlUtilities()
    }
}
public struct CNCalendar: View {
    private let title: LocalizedStringKey
    @Binding private var date: Date
    private let range: ClosedRange<Date>
    private let classes: TWClasses
    public init(_ title: LocalizedStringKey = "Date", selection: Binding<Date>,
                in range: ClosedRange<Date> = Date.distantPast...Date.distantFuture, classes: TWClasses = "") {
        self.title = title; _date = selection; self.range = range; self.classes = classes
    }
    public var body: some View {
        DatePicker(title, selection: $date, in: range, displayedComponents: .date)
            .datePickerStyle(.graphical).tw(cn("calendar", classes)).cnControlUtilities()
    }
}
public struct CNDatePicker: View {
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
    public var body: some View {
        DatePicker(title, selection: $date, in: range, displayedComponents: components)
            .datePickerStyle(.compact).tw(cn("calendar", classes)).cnControlUtilities()
    }
}
