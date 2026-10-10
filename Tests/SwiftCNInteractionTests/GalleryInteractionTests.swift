import XCTest
import XCUIAutomation

final class GalleryInteractionTests: XCTestCase {
    @MainActor func testCalendarSelectionUpdatesTheFormattedDateInput() {
        let app = launch("date_picker")
        defer { capture(app); app.terminate() }
        let editor = app.textFields["Delivery date"]
        let trigger = app.buttons["Choose date"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        #if os(macOS)
        activate(editor)
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText("10/20/2025")
        #endif
        activate(trigger)
        expectValue(trigger, "Expanded")
        #if os(macOS)
        expectValue(editor, "10/20/2025")
        #endif
        let day = app.buttons.matching(NSPredicate(format: "label CONTAINS 'October' AND label CONTAINS '17' AND label CONTAINS '2025'")).firstMatch
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        activate(day)
        expectValue(trigger, "Collapsed")
        expectValue(editor, "10/17/2025")
        activate(trigger)
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        activate(trigger)
        expectValue(trigger, "Collapsed")
    }
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
        // Digits avoid locale-dependent autocorrection in this persistence test.
        editor.typeText(" 12345")
        expectValue(editor, "Design system 12345")
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(close.isHittable, "The keyboard must not collapse the dialog's viewport.")
        activate(close)
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
        expectValue(editor, "Design system 12345")
        #endif
    }

    @MainActor func testAdaptiveSurfacesKeepTapsTransitionsAndSheetTyping() {
        let app = launch("native:surfaces")
        defer { capture(app); app.terminate() }
        let share = app.buttons["Share"]
        for _ in 0..<8 { activate(share) }
        XCTAssertTrue(text(app, containing: "Shared 8 times").waitForExistence(timeout: 5))
        // Interrupt the glass morph repeatedly; the group must settle on the final state.
        let toggle = app.buttons.matching(NSPredicate(format: "label IN {'More tools', 'Fewer tools'}")).firstMatch
        for _ in 0..<5 { activate(toggle) }
        let reset = app.buttons["Reset tool"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        activate(app.buttons["Eraser"])
        XCTAssertTrue(text(app, containing: "Tool: eraser").waitForExistence(timeout: 5))
        activate(reset)
        XCTAssertTrue(text(app, containing: "Tool: pencil").waitForExistence(timeout: 5))
        for policy in ["Solid", "Glass", "Automatic"] {
            #if os(macOS)
            activate(app.radioButtons[policy])
            #else
            activate(app.buttons[policy])
            #endif
        }
        XCTAssertTrue(reset.exists, "Changing the appearance policy must not change the controls.")
        activate(app.buttons["Open note"])
        let note = app.textFields["Write a note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        activate(note)
        // Return ends the edit session. Without it, plain SwiftUI sheets on the iOS 27 simulator can drop the
        // final synthesized keystroke from the binding when Done dismisses the sheet immediately.
        note.typeText("Glass 12345\n")
        expectValue(note, "Glass 12345")
        activate(app.buttons["Done"])
        XCTAssertTrue(wait(for: NSPredicate(format: "exists == false"), on: note))
        activate(app.buttons["Open note"])
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        expectValue(note, "Glass 12345")
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

    #if os(iOS)
    @MainActor func testNativeProminentButtonsKeepTheirLabelColorUnderStyledAncestors() throws {
        // AppKit draws macOS button labels itself; iOS button styles adopt any explicit ancestor foreground.
        let app = launch("button", probe: "native-button-labels")
        defer { capture(app); app.terminate() }
        var labels = ["Bordered label", "Nested label"]
        // The probe shows the glass style only where the system provides it.
        if #available(iOS 26, *) { labels.append("Glass label") }
        for label in labels {
            let button = app.buttons[label]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(try lightLabelCoverage(button), 0.02, "\(label) lost its native light label color.")
        }
        XCTAssertLessThan(try lightLabelCoverage(app.buttons["Explicit label"]), 0.002,
                          "An explicit text-* class must still reach the native label.")
    }

    /// The share of near-white pixels across the label band, away from the rounded edges.
    @MainActor private func lightLabelCoverage(_ element: XCUIElement) throws -> Double {
        let image = try XCTUnwrap(element.screenshot().image.cgImage)
        let width = image.width, height = image.height
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let bytes = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        var light = 0, total = 0
        for y in (height * 3 / 10)..<(height * 7 / 10) {
            for x in (width * 15 / 100)..<(width * 85 / 100) {
                let index = (y * width + x) * 4
                if min(bytes[index], bytes[index + 1], bytes[index + 2]) > 215 { light += 1 }
                total += 1
            }
        }
        return Double(light) / Double(max(total, 1))
    }
    #endif

    @MainActor private func launch(_ example: String, probe: String? = nil) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["SWIFTCN_UI_PROBE"] = probe
        #if os(macOS)
        app.launchArguments = ["-AppleKeyboardUIMode", "3"]
        #endif
        if example == "date_picker" { app.launchArguments += ["-AppleLocale", "en_US"] }
        app.launchEnvironment["SWIFTCN_UI_EXAMPLE"] = example
        app.launch()
        return app
    }

    /// macOS exposes Text as a value; iOS exposes it as a label.
    @MainActor private func text(_ app: XCUIApplication, containing value: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", value, value)).firstMatch
    }

    @MainActor private func activate(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        // Hosting overlays expose visible controls through native scroll views.
        // Send physical input to their bounds instead of scrolling the overlay.
        activate(element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
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
        let matches = wait(for: NSPredicate { object, _ in
            guard let element = object as? XCUIElement else { return false }
            return String(describing: element.value ?? "") == value
        }, on: element)
        XCTAssertTrue(matches, "Expected \(value); received \(String(describing: element.value ?? ""))")
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
