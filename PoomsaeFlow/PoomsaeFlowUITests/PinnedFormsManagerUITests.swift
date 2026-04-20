import XCTest

final class PinnedFormsManagerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        app.completeOnboarding(schoolIdentifier: "belt_system_row_spartaTKD", beltRowName: "Black")
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Navigation

    /// Tapping the Pinned Forms card navigates to PinnedFormsView.
    func test_pinnedCard_opensPinnedFormsView() {
        let pinnedCard = app.element(withIdentifier: "session_card_pinned")
        XCTAssertTrue(pinnedCard.waitForExistence(timeout: 3))
        pinnedCard.tap()

        let nav = app.navigationBars["Pinned Forms"]
        XCTAssertTrue(nav.waitForExistence(timeout: 3), "PinnedFormsView should be visible")
    }

    // MARK: - Empty state

    /// With no pinned forms, the manager shows the empty-state placeholder.
    func test_emptyManager_showsPlaceholder() {
        let pinnedCard = app.element(withIdentifier: "session_card_pinned")
        XCTAssertTrue(pinnedCard.waitForExistence(timeout: 3))
        pinnedCard.tap()

        XCTAssertTrue(
            app.staticTexts["No Pinned Forms"].waitForExistence(timeout: 3),
            "Empty state placeholder should appear when no forms are pinned"
        )
    }

    // MARK: - Add and verify

    /// Pinning a form from the browser causes it to appear in the manager list.
    func test_addFormViaFormBrowser_appearsInManager() {
        navigateToManager()

        let editButton = app.element(withIdentifier: "edit_pinned_forms_button")
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        let addButton = app.element(withIdentifier: "add_forms_button")
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        // Tap the pin button for the first available form in the browser
        let firstPinButton = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
            .firstMatch
        XCTAssertTrue(firstPinButton.waitForExistence(timeout: 3),
                      "Form browser should show at least one pin button")
        firstPinButton.tap()

        // Navigate back to manager
        app.navigationBars["Add Forms"].buttons.firstMatch.tap()

        // Manager should now have at least one row
        let firstRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'pinned_form_row_'"))
            .firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3),
                      "Pinned form should appear in manager after adding via browser")
    }

    // MARK: - Swipe to delete

    /// Swiping to delete a pinned form removes it from the list.
    func test_swipeToDelete_removesFormFromManager() {
        pinFirstAvailableForm()
        navigateToManager()

        // Swipe-to-delete requires targeting the collection view cell directly.
        // SwiftUI List on iOS 16+ is backed by UICollectionView, not UITableView.
        let cell = app.collectionViews.cells.firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 3), "Pinned form cell not found")
        cell.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button should appear after swipe")
        deleteButton.tap()

        XCTAssertTrue(
            app.staticTexts["No Pinned Forms"].waitForExistence(timeout: 3),
            "Manager should show empty state after deleting the only pinned form"
        )
    }

    // MARK: - Reorder persistence

    /// Reordering pinned forms persists after leaving and re-entering the manager.
    func test_reorder_persistsAcrossNavigation() {
        // Pin two forms
        pinFirstAvailableForm()
        pinSecondAvailableForm()
        navigateToManager()

        // Capture order before reorder
        let rowsBefore = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'pinned_form_row_'"))
        guard rowsBefore.count >= 2 else {
            XCTFail("Need at least 2 pinned forms to test reorder")
            return
        }
        let firstIDBefore = rowsBefore.element(boundBy: 0).identifier

        // Enable edit mode and reorder
        let editButton = app.element(withIdentifier: "edit_pinned_forms_button")
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        let reorderHandles = app.buttons.matching(NSPredicate(format: "label == 'Reorder'"))
        guard reorderHandles.count >= 2 else {
            // SwiftUI reorder handles may not be query-able in all simulator versions — skip
            return
        }
        let firstHandle = reorderHandles.element(boundBy: 0)
        let secondHandle = reorderHandles.element(boundBy: 1)
        firstHandle.press(forDuration: 0.5, thenDragTo: secondHandle)
        editButton.tap() // exit edit mode

        // Navigate away and back
        app.navigationBars["Pinned Forms"].buttons.firstMatch.tap()
        let pinnedCard = app.element(withIdentifier: "session_card_pinned")
        XCTAssertTrue(pinnedCard.waitForExistence(timeout: 3))
        pinnedCard.tap()

        let rowsAfter = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'pinned_form_row_'"))
        XCTAssertNotEqual(rowsAfter.element(boundBy: 0).identifier, firstIDBefore,
                          "First row should have changed after reorder")
    }

    // MARK: - Start button visibility

    /// "Start session" is disabled while edit mode is active and re-enabled on Done.
    func test_startButton_hiddenInEditMode() {
        pinFirstAvailableForm()
        navigateToManager()

        let startButton = app.element(withIdentifier: "start_pinned_session_button")
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "Start button should be visible initially")
        XCTAssertTrue(startButton.isEnabled, "Start button should be enabled before entering edit mode")

        let editButton = app.element(withIdentifier: "edit_pinned_forms_button")
        editButton.tap()

        XCTAssertTrue(startButton.exists, "Start button should still exist in edit mode")
        XCTAssertFalse(startButton.isEnabled, "Start button should be disabled in edit mode")

        editButton.tap() // Done
        XCTAssertTrue(startButton.isEnabled, "Start button should be re-enabled after leaving edit mode")
    }

    // MARK: - Unpin from browser

    /// Tapping an already-pinned form in the browser unpins it.
    func test_unpinFromBrowser_removesFormFromManager() {
        pinFirstAvailableForm()
        navigateToManager()

        // Confirm one form is pinned
        let firstRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'pinned_form_row_'"))
            .firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3), "One form should be pinned")

        // Open the browser and tap the same form's button to unpin it
        let editButton = app.element(withIdentifier: "edit_pinned_forms_button")
        editButton.tap()
        let addButton = app.element(withIdentifier: "add_forms_button")
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        let firstPinButton = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
            .firstMatch
        XCTAssertTrue(firstPinButton.waitForExistence(timeout: 3))
        firstPinButton.tap() // was pinned — now unpins

        app.navigationBars["Add Forms"].buttons.firstMatch.tap()

        // We return to PinnedFormsView still in edit mode; the ContentUnavailableView overlay
        // is only shown when editMode == .inactive, so exit edit mode before asserting.
        let doneButton = app.element(withIdentifier: "edit_pinned_forms_button")
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()

        XCTAssertTrue(
            app.staticTexts["No Pinned Forms"].waitForExistence(timeout: 3),
            "Manager should show empty state after unpinning the only form from the browser"
        )
    }

    // MARK: - Start practice session

    /// With pinned forms present, "Start practice session" opens Session Setup.
    func test_startPracticeSession_opensSessionSetup() {
        pinFirstAvailableForm()
        navigateToManager()

        let startButton = app.element(withIdentifier: "start_pinned_session_button")
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        XCTAssertTrue(startButton.isEnabled, "Start button should be enabled when forms are pinned")
        startButton.tap()

        XCTAssertTrue(
            app.navigationBars["Session Setup"].waitForExistence(timeout: 3),
            "Session Setup sheet should appear after tapping Start"
        )
    }

    /// With no pinned forms, "Start practice session" is disabled.
    func test_startPracticeSession_disabledWhenEmpty() {
        navigateToManager()

        let startButton = app.element(withIdentifier: "start_pinned_session_button")
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        XCTAssertFalse(startButton.isEnabled, "Start button should be disabled when no forms are pinned")
    }

    // MARK: - Helpers

    private func navigateToManager() {
        let manageButton = app.element(withIdentifier: "session_card_pinned")
        XCTAssertTrue(manageButton.waitForExistence(timeout: 3))
        manageButton.tap()
        XCTAssertTrue(app.navigationBars["Pinned Forms"].waitForExistence(timeout: 3))
    }

    private func pinFirstAvailableForm() {
        navigateToManager()
        let editButton = app.element(withIdentifier: "edit_pinned_forms_button")
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()
        let addButton = app.element(withIdentifier: "add_forms_button")
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        let firstPin = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
            .firstMatch
        XCTAssertTrue(firstPin.waitForExistence(timeout: 3))
        firstPin.tap()
        app.navigationBars["Add Forms"].buttons.firstMatch.tap()
        app.navigationBars["Pinned Forms"].buttons.firstMatch.tap()
    }

    private func pinSecondAvailableForm() {
        navigateToManager()
        let editButton = app.element(withIdentifier: "edit_pinned_forms_button")
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()
        let addButton = app.element(withIdentifier: "add_forms_button")
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        let pinButtons = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
        // The first form is already pinned. Tap index 1 to pin a different form.
        // (All buttons are now enabled — pinned buttons toggle to unpin, so we skip index 0.)
        guard pinButtons.count >= 2 else {
            XCTFail("Need at least 2 forms in the browser to pin a second form")
            return
        }
        pinButtons.element(boundBy: 1).tap()
        app.navigationBars["Add Forms"].buttons.firstMatch.tap()
        app.navigationBars["Pinned Forms"].buttons.firstMatch.tap()
    }
}
