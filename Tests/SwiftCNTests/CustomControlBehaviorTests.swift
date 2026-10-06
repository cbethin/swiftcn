import Foundation
import Testing
@testable import SwiftCN

@Suite("Custom calendar and dropdown behavior")
struct CustomControlBehaviorTests {
    private func gregorian(_ zone: String = "UTC", firstWeekday: Int = 1) -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: zone)!
        value.firstWeekday = firstWeekday
        return value
    }
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
    @Test func leapMonthAndWeekStartsHaveStableUniqueCells() {
        for first in [1, 2, 7] {
            let calendar = gregorian(firstWeekday: first)
            let month = date(2024, 2, 15, calendar: calendar)
            let days = CNCalendarGrid.days(in: month, calendar: calendar)
            #expect(days.count == 42)
            #expect(Set(days).count == 42)
            #expect(calendar.component(.weekday, from: days[0]) == first)
            #expect(days.filter { calendar.component(.month, from: $0) == 2 }.count == 29)
        }
    }
    @Test func gridKeepsConsecutiveLocalDaysAcrossDaylightSaving() {
        let calendar = gregorian("America/New_York")
        let days = CNCalendarGrid.days(in: date(2026, 3, 1, calendar: calendar), calendar: calendar)
        #expect(days.count == 42)
        for (first, second) in zip(days, days.dropFirst()) {
            #expect(calendar.dateComponents([.day], from: first, to: second).day == 1)
            #expect(calendar.component(.hour, from: second) == 0)
        }
        #expect(zip(days, days.dropFirst()).contains { $1.timeIntervalSince($0) == 23 * 3600 })
    }
    @Test func partialDayBoundsNeverProduceAnOutOfRangeSelection() {
        let calendar = gregorian()
        let lower = date(2026, 10, 6, hour: 15, calendar: calendar)
        let upper = date(2026, 10, 8, hour: 0, calendar: calendar)
        let range = lower...upper
        #expect(CNCalendarGrid.selection(for: date(2026, 10, 5, calendar: calendar), in: range, calendar: calendar) == nil)
        #expect(CNCalendarGrid.selection(for: date(2026, 10, 6, calendar: calendar), in: range, calendar: calendar) == lower)
        #expect(CNCalendarGrid.selection(for: upper, in: range, calendar: calendar) == upper)
        #expect(CNCalendarGrid.selection(for: date(2026, 10, 9, calendar: calendar), in: range, calendar: calendar) == nil)
    }
    @Test func navigationCannotLeaveTheAllowedMonths() {
        let calendar = gregorian()
        let start = date(2026, 1, 20, calendar: calendar)
        let end = date(2026, 3, 5, calendar: calendar)
        let range = start...end
        #expect(CNCalendarGrid.adjacent(to: start, offset: -1, in: range, calendar: calendar) == nil)
        #expect(CNCalendarGrid.adjacent(to: start, offset: 1, in: range, calendar: calendar) == date(2026, 2, 1, calendar: calendar))
        #expect(CNCalendarGrid.adjacent(to: end, offset: 1, in: range, calendar: calendar) == nil)
    }
    @Test func nonGregorianGridUsesTheEnvironmentCalendar() {
        var calendar = Calendar(identifier: .hebrew)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let input = Date(timeIntervalSince1970: 1_760_054_400)
        let start = CNCalendarGrid.month(containing: input, calendar: calendar)
        #expect(calendar.component(.day, from: start) == 1)
        let days = CNCalendarGrid.days(in: input, calendar: calendar)
        #expect(days.count == 42)
        #expect(days.contains(start))
    }
    @Test func menuFocusWrapsAndHandlesRemovedOrDisabledItems() {
        #expect(CNMenuNavigation.next([1, 3, 4], current: 4, step: 1) == 1)
        #expect(CNMenuNavigation.next([1, 3, 4], current: 1, step: -1) == 4)
        #expect(CNMenuNavigation.next([1, 3, 4], current: 2, step: 1) == 1)
        #expect(CNMenuNavigation.next([1, 3, 4], current: nil, step: -1) == 4)
        #expect(CNMenuNavigation.next([Int](), current: 1, step: 1) == nil)
    }
}
