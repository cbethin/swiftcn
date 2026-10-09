import XCTest
import UIKit

final class ShowcaseUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    @MainActor private var runningApp: XCUIApplication?
    @MainActor private func launch(reset: Bool = true) -> XCUIApplication {
        // Exercise iPad's two-pane layout, rather than its default portrait sidebar overlay.
        if UIDevice.current.userInterfaceIdiom == .pad { XCUIDevice.shared.orientation = .landscapeLeft }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + (reset ? ["--reset-test-data"] : [])
        app.launch()
        runningApp = app
        return app
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor private func enter(_ text: String, into field: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        tap(field, file: file, line: line)
        // Individual events let the simulator settle between keystrokes under host load.
        for character in text { field.typeText(String(character)) }
        XCTAssertEqual(field.value as? String, text, "The native editor must contain the full draft before Save", file: file, line: line)
    }
    @MainActor private func tap(_ element: XCUIElement, scrolling scrollView: XCUIElement? = nil, file: StaticString = #filePath, line: UInt = #line) {
        _ = element.waitForExistence(timeout: 2)
        for _ in 0..<6 {
            if element.exists && element.isHittable { break }
            // Target the native scroll container. Duo's application frame can refer to its outer display.
            (scrollView ?? runningApp?.scrollViews.firstMatch)?.swipeUp()
            _ = element.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(element.exists && element.isHittable, file: file, line: line)
        element.tap()
    }
    // Run this test on Duo in its book pose. It checks both directions, not a fixed sheet position.
    @MainActor func testSheetsFollowTheirTriggers() throws {
        let app = launch()
        guard #available(iOS 27.0, *) else { throw XCTSkip("Requires native sheet placement") }
        tap(app.buttons["launch-fieldnotes"])
        let create = app.buttons["new-entry"]
        let edit = app.buttons["Edit"]
        _ = create.waitForExistence(timeout: 5)
        _ = edit.waitForExistence(timeout: 3)
        try XCTSkipUnless(create.isHittable && edit.isHittable, "Requires two visible panes")
        // Duo reports the application frame in its display coordinate space. Compare visible triggers instead.
        let boundary = (create.frame.midX + edit.frame.midX) / 2
        XCTAssertGreaterThan(edit.frame.midX - create.frame.midX, 150)
        tap(create)
        let title = app.textFields["entry-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertLessThan(title.frame.midX, boundary, "The collection editor belongs on the triggering half")
        capture(app, "Sheet from collection")
        tap(app.buttons["Cancel"])
        tap(edit)
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(title.frame.midX, boundary, "The detail editor belongs on the triggering half")
        capture(app, "Sheet from detail")
        tap(app.buttons["Cancel"])
    }
    @MainActor func testTaskCreationCompletionAndRelaunch() {
        var app = launch()
        capture(app, "Launcher")
        tap(app.buttons["launch-daylight"])
        capture(app, "Daylight")
        tap(app.buttons["add-task"])
        enter("Walk the garden", into: app.textFields["task-title"])
        tap(app.buttons["save-editor"])
        tap(app.descendants(matching: .any)["task-Walk the garden"].firstMatch)
        tap(app.buttons["toggle-completed"])
        XCTAssertTrue(app.staticTexts["Walk the garden"].waitForExistence(timeout: 5))
        app.terminate()
        app = launch(reset: false)
        tap(app.buttons["launch-daylight"])
        tap(app.buttons["toggle-completed"])
        XCTAssertTrue(app.staticTexts["Walk the garden"].waitForExistence(timeout: 5))
    }
    @MainActor func testExpenseCreationChangesBalance() {
        let app = launch()
        tap(app.buttons["launch-ledger"])
        capture(app, "Ledger")
        app.scrollViews.firstMatch.swipeUp()
        tap(app.buttons["add-expense"])
        enter("Flowers", into: app.textFields["expense-title"])
        enter("15.25", into: app.textFields["expense-amount"])
        tap(app.buttons["save-editor"])
        XCTAssertTrue(app.staticTexts["Flowers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["$1,823.55"].exists)
    }
    @MainActor func testProjectTaskKeepsItsProject() {
        let app = launch()
        tap(app.buttons["launch-daylight"])
        tap(app.buttons["Projects"])
        tap(app.buttons.containing(.staticText, identifier: "Studio").firstMatch)
        tap(app.buttons["Add task"])
        XCTAssertTrue(app.segmentedControls.buttons["Studio"].isSelected)
        enter("Studio draft", into: app.textFields["task-title"])
        tap(app.buttons["save-editor"])
        XCTAssertTrue(app.staticTexts["Studio draft"].waitForExistence(timeout: 5))
    }
    @MainActor func testJournalCreationAndReading() {
        let app = launch()
        tap(app.buttons["launch-fieldnotes"])
        capture(app, "Fieldnotes")
        tap(app.buttons["new-entry"])
        enter("A new morning", into: app.textFields["entry-title"])
        enter("The garden was quiet and full of light.", into: app.textViews["entry-body"])
        XCTAssertEqual(app.textFields["entry-title"].value as? String, "A new morning", "The title draft must survive keyboard changes")
        tap(app.buttons["save-editor"])
        let notebook = app.collectionViews["notebook-collection"]
        tap(app.buttons.containing(.staticText, identifier: "A new morning").firstMatch, scrolling: notebook)
        XCTAssertTrue(app.staticTexts["The garden was quiet and full of light."].waitForExistence(timeout: 5))
        tap(app.buttons["Keep this"])
        XCTAssertTrue(app.buttons["Starred"].exists)
    }
    @MainActor func testTripCreationAndPacking() {
        let app = launch()
        tap(app.buttons["launch-roam"])
        capture(app, "Roam")
        let journeys = app.collectionViews["journey-collection"]
        tap(app.buttons["new-trip"], scrolling: journeys)
        enter("A mountain weekend", into: app.textFields["trip-title"])
        tap(app.buttons["save-editor"])
        journeys.swipeDown()
        journeys.swipeDown()
        tap(app.buttons.containing(.staticText, identifier: "A mountain weekend").firstMatch, scrolling: journeys)
        tap(app.segmentedControls.buttons["Packing"])
        tap(app.descendants(matching: .any)["packing-Passport"].firstMatch)
        XCTAssertTrue(app.staticTexts["1/3 packed"].exists)
        // Wide split views already expose the collection toolbar. Only compact navigation needs Back.
        if !app.buttons["all-apps"].isHittable { tap(app.navigationBars.buttons.element(boundBy: 0)) }
        tap(app.buttons["all-apps"])
        XCTAssertTrue(app.buttons["launch-daylight"].waitForExistence(timeout: 5))
    }
}
