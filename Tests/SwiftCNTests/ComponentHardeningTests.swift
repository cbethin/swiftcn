import SwiftUI
import Testing
@testable import SwiftCN

@Suite("Prepared table records and hover intent")
struct ComponentHardeningTests {
    @Test func nativeSelectionProjectionHasNoMainQueueRequirement() async {
        let selection = CNTableSelection(Set(1...20)).binding(.constant([1, 21]))
        let visible = await Task.detached { selection.wrappedValue }.value
        #expect(visible == [1])
    }
    @MainActor @Test func visibleSelectionEditsRetainOtherPagesAndRejectUnknownIDs() {
        var selected: Set<Int> = [1, 21]
        let selection = Binding(get: { selected }, set: { selected = $0 })
        let first = CNTableSelection(Set(1...20)).binding(selection)
        let second = CNTableSelection(Set(21...40)).binding(selection)
        #expect(first.wrappedValue == [1] && second.wrappedValue == [21])
        first.wrappedValue = [2, 999]
        #expect(selected == [2, 21])
        second.wrappedValue = [22]
        #expect(selected == [2, 22])
        first.wrappedValue = []
        #expect(selected == [22])
        selection.wrappedValue = []
        #expect(first.wrappedValue.isEmpty && second.wrappedValue.isEmpty)
    }
    private struct Record: Identifiable {
        let id: Int
        let title: String
    }
    @Test func filtersAndSortsBeforePagingWithoutLosingRecordIdentity() {
        let source = (0..<10_000).map { Record(id: $0, title: "Record \($0)") }
        var evaluations = 0
        let records = CNTableRecords(source, sortOrder: [KeyPathComparator(\.id, order: .reverse)]) {
            evaluations += 1
            return $0.id.isMultiple(of: 2)
        }
        #expect(evaluations == source.count)
        let first = records.page(1, size: 50)
        let second = records.page(2, size: 50)
        #expect(first.rows.first?.id == 9998)
        #expect(second.rows.first?.id == 9898)
        #expect(first.pageCount == 100 && first.totalCount == 5000)
        #expect(evaluations == source.count, "Changing pages must not rerun filtering or sorting.")
        #expect(Set(first.rows.map(\.id)).isDisjoint(with: Set(second.rows.map(\.id))))
    }
    @Test func emptyAndExtremePagesStayBounded() {
        let empty = CNTableRecords([Record]()).page(Int.max, size: Int.max)
        #expect(empty.rows.isEmpty && empty.number == 0 && empty.pageCount == 0)
        let records = CNTableRecords((0..<5).map { Record(id: $0, title: "\($0)") })
        #expect(records.page(Int.min, size: 2).rows.map(\.id) == [0, 1])
        #expect(records.page(Int.max, size: 2).rows.map(\.id) == [4])
        #expect(records.page(1, size: Int.max).rows.count == 5)
    }
    @Test func explicitDismissalSuppressesHoverReopeningUntilPointerLeaves() {
        var intent = CNHoverIntent()
        #expect(intent.schedule(hovering: true) == .open)
        intent.activate(hovering: true)
        #expect(intent.isPresented && intent.pinned)
        #expect(intent.schedule(hovering: false) == nil)
        intent.activate(hovering: true)
        #expect(!intent.isPresented && intent.schedule(hovering: true) == nil)
        intent.suppressed = false
        #expect(intent.schedule(hovering: true) == .open)
    }
    @Test func travelIntoContentCancelsCloseAndPinningCancelsHoverDismissal() {
        var intent = CNHoverIntent()
        intent.complete(.open)
        #expect(intent.schedule(hovering: false) == .close)
        #expect(intent.schedule(hovering: true) == nil)
        intent.dismiss(hovering: false)
        intent.activate(hovering: false)
        #expect(intent.schedule(hovering: false) == nil)
        intent.dismiss(hovering: false)
        #expect(!intent.isPresented && !intent.pinned)
    }
}
