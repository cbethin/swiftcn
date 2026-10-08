import XCTest
import XCUIAutomation

final class GalleryInteractionTests: XCTestCase {
    @MainActor func testCheckboxLabelAndTrailingSpaceToggleTheValue() {
        let app = launch("checkbox")
        defer { capture(app); app.terminate() }
        #if os(macOS)
        let checkbox = app.checkBoxes["Accept the terms"]
        #else
        let checkbox = app.switches["Accept the terms"]
        #endif
        let checked = "1", unchecked = "0"
        XCTAssertTrue(checkbox.waitForExistence(timeout: 5))
        XCTAssertEqual(String(describing: checkbox.value ?? ""), checked)
        // The right side is empty styled space, beyond the indicator and label.
        activate(checkbox.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        expectValue(checkbox, unchecked)
        activate(checkbox.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
            .withOffset(CGVector(dx: 55, dy: 0)))
        expectValue(checkbox, checked)
    }

    @MainActor func testDropdownReopensAndInvokesOnlyTheSelectedAction() {
        let app = launch("dropdown_menu")
        defer { capture(app); app.terminate() }
        let trigger = app.buttons["Workspace actions"]
        XCTAssertTrue(trigger.waitForExistence(timeout: 5))
        for _ in 0..<3 {
            activate(trigger)
            expectValue(trigger, "Expanded")
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Rename'")).firstMatch.waitForExistence(timeout: 5))
            activate(trigger)
            expectValue(trigger, "Collapsed")
        }
        activate(trigger)
        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5))
        activate(duplicate)
        expectValue(trigger, "Collapsed")
        XCTAssertTrue(app.staticTexts["Duplicate selected"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Delete selected"].exists)
        activate(trigger)
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5))
    }

    @MainActor func testDialogRetainsEditsAfterDismissalAndReopening() {
        let app = launch("dialog")
        defer { capture(app); app.terminate() }
        let trigger = app.buttons["Edit workspace"]
        XCTAssertTrue(trigger.waitForExistence(timeout: 5))
        activate(trigger)
        let editor = app.textFields["Name"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        #if os(macOS)
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText("Interaction draft")
        app.typeKey(.escape, modifierFlags: [])
        #else
        editor.typeText(" draft")
        activate(app.buttons["Close"])
        #endif
        let closed = NSPredicate(format: "exists == false")
        XCTAssertTrue(wait(for: closed, on: editor))
        #if os(macOS)
        // Reopen through the restored trigger's native keyboard focus.
        app.typeKey(.return, modifierFlags: [])
        #else
        activate(trigger)
        #endif
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        #if os(macOS)
        XCTAssertEqual(editor.value as? String, "Interaction draft")
        #else
        XCTAssertTrue((editor.value as? String)?.contains("draft") == true)
        #endif
    }

    @MainActor func testCustomResizeHandleTracksRealDraggingInBothDirections() {
        let app = launch("resizable")
        defer { capture(app); app.terminate() }
        let handle = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Resize panels'")).firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        let original = handle.frame.midX
        drag(handle, by: 75)
        XCTAssertTrue(wait(for: NSPredicate { object, _ in
            (object as? XCUIElement).map { $0.frame.midX > original + 40 } ?? false
        }, on: handle))
        let expanded = handle.frame.midX
        drag(handle, by: -65)
        XCTAssertTrue(wait(for: NSPredicate { object, _ in
            (object as? XCUIElement).map { $0.frame.midX < expanded - 40 } ?? false
        }, on: handle))
    }

    #if os(macOS)
    @MainActor func testNativeSplitDividerDragsWithoutLosingTheEditorDraft() {
        let app = launch("native:split")
        defer { capture(app); app.terminate() }
        let editor = app.textViews["Split editor draft"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText("Draft after divider dragging")
        let divider = app.splitters.element(boundBy: 1)
        XCTAssertTrue(divider.exists)
        let original = divider.frame.midX
        drag(divider, by: 130)
        XCTAssertGreaterThan(divider.frame.midX, original + 100)
        drag(divider, by: -200)
        XCTAssertLessThan(divider.frame.midX, original - 40)
        XCTAssertEqual(editor.value as? String, "Draft after divider dragging")
        editor.typeText("!")
        XCTAssertEqual(editor.value as? String, "Draft after divider dragging!")
    }

    @MainActor func testNativeNavigationDividerAndVisibilityPreserveTheDraft() {
        let app = launch("native:navigation")
        defer { capture(app); app.terminate() }
        activate(app.buttons["Open native navigation"])
        let editor = app.textViews["Project draft"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText("Navigation interaction draft")
        let window = app.windows.containing(.textView, identifier: "Project draft").firstMatch
        let divider = window.splitters.firstMatch
        let original = divider.frame.midX
        drag(divider, by: 200)
        XCTAssertGreaterThan(divider.frame.midX, original + 160)
        drag(divider, by: -200)
        XCTAssertLessThan(abs(divider.frame.midX - original), 20)
        activate(window.toolbars.buttons["Hide Sidebar"].firstMatch)
        activate(window.toolbars.buttons["Show Sidebar"].firstMatch)
        XCTAssertEqual(editor.value as? String, "Navigation interaction draft")
    }
    #endif

    @MainActor private func launch(_ example: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        #if os(macOS)
        app.launchArguments = ["-AppleKeyboardUIMode", "3"]
        #endif
        app.launchEnvironment["SWIFTCN_UI_EXAMPLE"] = example
        app.launch()
        return app
    }

    @MainActor private func activate(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        #if os(macOS)
        // AppKit hosting overlays expose visible controls through a scroll view.
        // Click their physical bounds instead of asking XCTest to scroll that overlay.
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        element.tap()
        #endif
    }

    @MainActor private func activate(_ coordinate: XCUICoordinate) {
        #if os(macOS)
        coordinate.click()
        #else
        coordinate.tap()
        #endif
    }

    @MainActor private func drag(_ element: XCUIElement, by distance: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: distance, dy: 0))
        #if os(macOS)
        start.click(forDuration: 0.1, thenDragTo: end)
        #else
        start.press(forDuration: 0.1, thenDragTo: end)
        #endif
    }

    @MainActor private func expectValue(_ element: XCUIElement, _ value: String) {
        XCTAssertTrue(wait(for: NSPredicate { object, _ in
            guard let element = object as? XCUIElement else { return false }
            return String(describing: element.value ?? "") == value
        }, on: element))
    }

    @MainActor private func wait(for predicate: NSPredicate, on element: XCUIElement) -> Bool {
        XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 5) == .completed
    }

    @MainActor private func capture(_ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
