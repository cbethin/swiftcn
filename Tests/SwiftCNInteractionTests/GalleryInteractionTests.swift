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
    @MainActor func testComboboxKeepsEveryChoiceReachableAndCommitsOnlySelection() {
        let app = launch("combobox")
        defer { capture(app); app.terminate() }
        let trigger = app.buttons["Choose a workspace"]
        activate(trigger)
        let search = app.textFields["Search workspaces…"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        let design = app.buttons["Design system"]
        let mobile = app.buttons["Mobile app"]
        let archived = app.buttons["Archived"]
        XCTAssertTrue(design.isHittable)
        XCTAssertTrue(mobile.isHittable)
        XCTAssertTrue(archived.exists)
        XCTAssertFalse(archived.isEnabled)
        capture(app)
        #if os(iOS)
        XCTAssertFalse(app.keyboards.firstMatch.exists, "Opening choices must not summon the keyboard.")
        let usesSheet = app.buttons["Cancel"].exists
        if usesSheet { activate(app.buttons["Cancel"]) }
        else { activate(trigger) }
        XCTAssertTrue(wait(for: NSPredicate(format: "exists == false"), on: search))
        expectValue(trigger, "No selection, Collapsed")
        activate(trigger)
        #endif
        activate(search)
        search.typeText("xyzq")
        XCTAssertTrue(app.staticTexts["No results found."].waitForExistence(timeout: 5))
        XCTAssertFalse(mobile.exists)
        activate(app.buttons["Clear search"])
        XCTAssertTrue(mobile.waitForExistence(timeout: 5))
        XCTAssertTrue(mobile.isHittable, "Results must stay above the keyboard.")
        capture(app)
        search.typeText("Mobile")
        XCTAssertFalse(design.exists)
        XCTAssertTrue(mobile.isHittable)
        activate(mobile)
        XCTAssertTrue(wait(for: NSPredicate(format: "exists == false"), on: search))
        expectValue(trigger, "Mobile app, Collapsed")
        activate(trigger)
        XCTAssertTrue(mobile.waitForExistence(timeout: 5))
        XCTAssertTrue(mobile.isSelected)
        #if os(iOS)
        if usesSheet { activate(app.buttons["Cancel"]) }
        else { activate(trigger) }
        #else
        app.typeKey(.escape, modifierFlags: [])
        #endif
        expectValue(trigger, "Mobile app, Collapsed")
    }

    #if os(iOS)
    @MainActor func testComboboxLongListReachesItsFinalChoiceAndSurvivesRotation() throws {
        let app = launch("combobox", probe: "long-combobox")
        defer { XCUIDevice.shared.orientation = .portrait; capture(app); app.terminate() }
        let trigger = app.buttons["Choose a workspace"]
        activate(trigger)
        let search = app.textFields["Search workspaces…"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        guard app.buttons["Cancel"].exists else {
            throw XCTSkip("This regression covers compact iPhone sheets; regular-width choices use an anchored popover.")
        }
        let list = app.scrollViews.containing(.button, identifier: "Workspace 1").firstMatch
        XCTAssertTrue(list.exists)
        let frame = list.frame
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: frame.midX, dy: frame.maxY - 20))
        let end = origin.withOffset(CGVector(dx: frame.midX, dy: frame.minY + 20))
        let last = app.buttons["Workspace 40"]
        for _ in 0..<20 {
            if last.isHittable { break }
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(last.isHittable, "The final row must be reachable by scrolling the choices.")
        activate(last)
        expectValue(trigger, "Workspace 40, Collapsed")
        activate(trigger)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Cancel"].isHittable)
        XCUIDevice.shared.orientation = .portrait
        activate(search)
        search.typeText("Workspace 40")
        activate(app.keyboards.buttons["Search"])
        XCTAssertTrue(search.exists, "Search must not silently commit an unhighlighted result.")
        XCTAssertTrue(wait(for: NSPredicate(format: "exists == false"), on: app.keyboards.firstMatch))
        activate(app.buttons["Cancel"])
        expectValue(trigger, "Workspace 40, Collapsed")
    }
    #endif

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
    @MainActor func testDirectButtonStylePreservesCallerKeyboardFocus() throws {
        let app = launch("button", probe: "flat-button-focus")
        defer { capture(app); app.terminate() }
        let target = app.buttons["Styled focus target"]
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        activate(app.buttons["Focus styled button"])
        XCTAssertTrue(wait(for: NSPredicate(format: "hasKeyboardFocus == true"), on: target),
                      "The caller's focus binding must focus the native button.")
        let image = try XCTUnwrap(target.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let width = image.width, height = image.height
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let bytes = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        let green = stride(from: 0, to: width * height * 4, by: 4).filter {
            bytes[$0] < 50 && bytes[$0 + 1] > 200 && bytes[$0 + 2] < 50
        }.count
        XCTAssertGreaterThan(Double(green) / Double(width * height), 0.3,
                             "The caller's native focus state must activate focus: classes.")
    }

    @MainActor func testCommandCommaOpensOneSettingsWindowAndPersistsPreferences() {
        let app = launch("card")
        defer { capture(app); app.terminate() }
        app.typeKey(",", modifierFlags: .command)
        let settings = app.windows.containing(.button, identifier: "Restore defaults").firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        activate(settings.buttons["Restore defaults"])
        activate(settings.buttons["Use dark appearance"])
        XCTAssertTrue(settings.buttons["Use dark appearance"].isSelected)
        let grid = settings.descendants(matching: .any).matching(identifier: "gallery-preview-grid").firstMatch
        let originalGrid = String(describing: grid.value ?? "")
        activate(grid)
        XCTAssertTrue(wait(for: NSPredicate { object, _ in
            String(describing: (object as? XCUIElement)?.value ?? "") != originalGrid
        }, on: grid))
        let changedGrid = String(describing: grid.value ?? "")
        activate(settings.buttons["Default Preview view"])
        app.typeKey(",", modifierFlags: .command)
        XCTAssertEqual(app.windows.containing(.button, identifier: "Restore defaults").count, 1)
        app.terminate()
        app.launch()
        ensureGalleryWindow(app)
        let gallery = app.windows.containing(.button, identifier: "Preview mode").firstMatch
        XCTAssertTrue(gallery.buttons["Preview mode"].isSelected)
        XCTAssertTrue(gallery.buttons["Use dark appearance"].isSelected)
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        XCTAssertTrue(settings.buttons["Default Preview view"].isSelected)
        XCTAssertEqual(String(describing: grid.value ?? ""), changedGrid)
        activate(settings.buttons["Restore defaults"])
    }

    @MainActor func testGalleryKeepsPreviewEditsAcrossModesAndSearch() {
        let app = launch("card")
        defer { capture(app); app.terminate() }
        let editor = app.textFields["Workspace name"]
        activate(editor)
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText("Gallery draft")
        activate(app.buttons["Code mode"])
        XCTAssertTrue(app.buttons["Copy Swift code"].waitForExistence(timeout: 5))
        XCTAssertFalse(editor.exists, "Hidden previews must leave the accessibility tree.")
        activate(app.buttons["Preview mode"])
        XCTAssertFalse(app.buttons["Copy Swift code"].exists, "Hidden code must leave the accessibility tree.")
        expectValue(editor, "Gallery draft")
        #if os(macOS)
        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertTrue(wait(for: NSPredicate(format: "selected == true"), on: app.buttons["Code mode"]))
        XCTAssertFalse(editor.exists)
        app.typeKey(.leftArrow, modifierFlags: [])
        XCTAssertTrue(wait(for: NSPredicate(format: "selected == true"), on: app.buttons["Preview mode"]))
        expectValue(editor, "Gallery draft")
        #endif
        app.typeKey("k", modifierFlags: .command)
        let search = app.textFields["gallery-search"]
        search.typeText("zzzz-no-component")
        XCTAssertTrue(app.staticTexts["No results"].waitForExistence(timeout: 5))
        expectValue(editor, "Gallery draft")
        activate(app.buttons["Clear search"].firstMatch)
        XCTAssertTrue(wait(for: NSPredicate(format: "exists == false"), on: app.staticTexts["No results"]))
        expectValue(editor, "Gallery draft")
        activate(search)
        search.typeText("CNInputOTP")
        expectValue(search, "CNInputOTP")
        search.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["Input OTP"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(editor.exists)
    }

    @MainActor func testNativeSplitDividerDragsWithoutLosingTheEditorDraft() {
        let app = launch("native:split")
        defer { capture(app); app.terminate() }
        activate(app.buttons["Preview mode"])
        let editor = app.textViews["Split editor draft"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText("Draft after divider dragging")
        let divider = app.splitters.firstMatch
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
    @MainActor func testCompactSidebarSwipesPreserveScrollingAndTheEditorDraft() throws {
        let app = launch("card")
        defer { capture(app); app.terminate() }
        guard app.buttons["Open sidebar"].exists else {
            throw XCTSkip("A regular-width sidebar stays visible instead of presenting a drawer.")
        }
        let editor = app.textFields["Workspace name"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        activate(editor)
        editor.typeText(" 2468")
        let draft = try XCTUnwrap(editor.value as? String)
        let window = app.windows.firstMatch
        let search = app.textFields["gallery-search"]
        let edge = window.coordinate(withNormalizedOffset: CGVector(dx: 0.002, dy: 0.3))
        let inside = window.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.3))
        // A short pull that stops must return to the closed state.
        edge.press(forDuration: 0.05,
                   thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.3)),
                   withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertFalse(search.isHittable)
        for _ in 0..<2 {
            edge.press(forDuration: 0.05, thenDragTo: inside)
            XCTAssertTrue(wait(for: NSPredicate(format: "hittable == true"), on: search))
            let firstRow = app.buttons["Aspect Ratio"].firstMatch
            if firstRow.isHittable {
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.4))
                    .press(forDuration: 0.05,
                           thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.25)))
                XCTAssertTrue(wait(for: NSPredicate(format: "hittable == false"), on: firstRow))
                XCTAssertTrue(search.isHittable, "Vertical scrolling must keep the drawer open.")
            }
            // Start over the list, rather than an empty background strip.
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.4))
                .press(forDuration: 0.05,
                       thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.002, dy: 0.4)))
            XCTAssertTrue(wait(for: NSPredicate(format: "hittable == false"), on: search))
            expectValue(editor, draft)
        }
    }

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
        ensureGalleryWindow(app)
        return app
    }

    @MainActor private func ensureGalleryWindow(_ app: XCUIApplication) {
        #if os(macOS)
        // A terminated SwiftUI app can restore a session with no gallery window.
        // Open the normal scene through its public menu before checking controls.
        let gallery = app.windows.containing(.button, identifier: "Preview mode").firstMatch
        if !gallery.waitForExistence(timeout: 5) {
            app.menuBars.menuBarItems["File"].click()
            app.menuItems["New SwiftCN Component Gallery Window"].click()
            XCTAssertTrue(gallery.waitForExistence(timeout: 5))
        }
        #endif
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
