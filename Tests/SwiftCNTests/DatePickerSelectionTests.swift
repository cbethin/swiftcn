import Foundation
import Testing
@testable import SwiftCN

@Suite("Date picker selection")
struct DatePickerSelectionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }
    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
    @Test func choosingADayPreservesLocalTimeAcrossDaylightSaving() {
        let result = CNDatePickerSelection.resolve(date(2026, 3, 9), preservingTimeFrom: date(2026, 3, 7, 14, 30),
            preserveTime: true, in: Date.distantPast...Date.distantFuture, calendar: calendar)
        #expect(result == date(2026, 3, 9, 14, 30))
    }
    @Test func typedDatesAndTimesRemainInsideTheAllowedRange() {
        let range = date(2026, 10, 8, 12)...date(2026, 10, 10, 16)
        #expect(CNDatePickerSelection.resolve(date(2026, 10, 8), preservingTimeFrom: date(2026, 10, 7, 9),
            preserveTime: true, in: range, calendar: calendar) == range.lowerBound)
        #expect(CNDatePickerSelection.resolve(date(2026, 10, 11, 18), preservingTimeFrom: range.lowerBound,
            preserveTime: false, in: range, calendar: calendar) == range.upperBound)
        #expect(CNDatePickerSelection.resolve(date(2026, 10, 9, 15, 20), preservingTimeFrom: range.lowerBound,
            preserveTime: false, in: range, calendar: calendar) == date(2026, 10, 9, 15, 20))
    }
}
