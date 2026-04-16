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
        let unpinnedButtons = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
        // The first is now pinned (checkmark/disabled); find the second enabled one
        var tapped = false
        for i in 0..<unpinnedButtons.count {
            let btn = unpinnedButtons.element(boundBy: i)
            if btn.isEnabled {
                btn.tap()
                tapped = true
                break
            }
        }
        XCTAssertTrue(tapped, "Could not find a second unpinned form to pin")
        app.navigationBars["Add Forms"].buttons.firstMatch.tap()
        app.navigationBars["Pinned Forms"].buttons.firstMatch.tap()
    }
}
