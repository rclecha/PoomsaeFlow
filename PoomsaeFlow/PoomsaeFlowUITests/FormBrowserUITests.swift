import XCTest

final class FormBrowserUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        // Use Sparta TKD + Black belt so the full catalog is available in the browser.
        app.completeOnboarding(schoolIdentifier: "belt_system_row_spartaTKD", beltRowName: "Black")
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Catalog scope

    /// Sparta TKD explicitly excludes Keecho Sam Jang from its formIDs catalog.
    /// The Form Browser must not show it when the active profile is Sparta TKD.
    func test_spartaTKD_keechoSamJang_absentFromBrowser() {
        openFormBrowser()

        let keechoSamJangText = app.staticTexts["Keecho Sam Jang"]
        // waitForExistence with a short timeout — we expect this to NOT exist
        let appeared = keechoSamJangText.waitForExistence(timeout: 2)
        XCTAssertFalse(appeared, "Keecho Sam Jang must not appear in the Sparta TKD Form Browser")
    }

    /// World Taekwondo has nil formIDs (unrestricted catalog), so Keecho Sam Jang
    /// must be visible when the active profile is World Taekwondo.
    func test_worldTaekwondo_keechoSamJang_presentInBrowser() {
        // Re-launch with a clean state and complete onboarding as World Taekwondo
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        app.completeOnboarding(schoolIdentifier: "belt_system_row_worldTaekwondo", beltRowName: "Black")

        openFormBrowser()

        let keechoSamJangText = app.staticTexts["Keecho Sam Jang"]
        XCTAssertTrue(keechoSamJangText.waitForExistence(timeout: 3),
                      "Keecho Sam Jang should be visible for World Taekwondo catalog")
    }

    // MARK: - Pin interaction

    /// Tapping a form's add button switches its accessibility label to "Unpin …".
    func test_tappingPinButton_showsCheckmark() {
        openFormBrowser()

        let firstPinButton = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
            .firstMatch
        XCTAssertTrue(firstPinButton.waitForExistence(timeout: 3))
        let buttonID = firstPinButton.identifier

        // Before tapping: label starts with "Pin"
        XCTAssertTrue(firstPinButton.isEnabled, "Pin button should be enabled before pinning")
        firstPinButton.tap()

        // After tapping: label switches to "Unpin …" (pinned state), button stays enabled
        let pinnedButton = app.buttons.matching(
            NSPredicate(format: "identifier == '\(buttonID)' AND label BEGINSWITH 'Unpin'")
        ).firstMatch
        XCTAssertTrue(pinnedButton.waitForExistence(timeout: 2),
                      "Pin button label should change to 'Unpin …' after pinning")
        XCTAssertTrue(pinnedButton.isEnabled,
                      "Pin button should remain enabled after pinning (tap again to unpin)")
    }

    /// After pinning a form in the browser, navigating to the Pinned Forms manager
    /// shows that form in the list.
    func test_pinningForm_appearsInPinnedManager() {
        openFormBrowser()

        let firstPinButton = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
            .firstMatch
        XCTAssertTrue(firstPinButton.waitForExistence(timeout: 3))
        firstPinButton.tap()

        // Navigate back to manager
        app.navigationBars["Add Forms"].buttons.firstMatch.tap()

        let firstRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'pinned_form_row_'"))
            .firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3),
                      "Pinned form should appear in the manager after pinning in browser")
    }

    /// Already-pinned forms remain visible in the browser — they show a checkmark and
    /// remain tappable (tap again to unpin).
    func test_alreadyPinnedForm_remainsVisibleInBrowser() {
        openFormBrowser()

        // Pin the first available form
        let firstPinButton = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'form_browser_pin_button_'"))
            .firstMatch
        XCTAssertTrue(firstPinButton.waitForExistence(timeout: 3))
        let pinnedButtonID = firstPinButton.identifier
        firstPinButton.tap()

        // The same button must still be in the list, enabled, with "Unpin …" label
        let pinnedButton = app.buttons.matching(
            NSPredicate(format: "identifier == '\(pinnedButtonID)' AND label BEGINSWITH 'Unpin'")
        ).firstMatch
        XCTAssertTrue(pinnedButton.waitForExistence(timeout: 2),
                      "Already-pinned form must remain visible in browser with 'Unpin …' label")
        XCTAssertTrue(pinnedButton.isEnabled,
                      "Already-pinned form pin button must stay enabled so the user can unpin it")
    }

    // MARK: - Belt-level grouping

    /// The Form Browser groups forms by belt level — a "Black Belt" or "Black" section
    /// should be visible for a black-belt user.
    func test_browser_showsBeltLevelSections() {
        openFormBrowser()

        // Scroll down to find Koryo — it's a black belt form at the bottom
        // of a list that starts with white belt forms.
        let koryoForm = app.staticTexts["Koryo"]
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(koryoForm.waitForExistence(timeout: 3),
                      "Koryo (black belt form) should appear in browser for a black belt user")
    }

    // MARK: - Helpers

    private func openFormBrowser() {
        let pinnedCard = app.element(withIdentifier: "session_card_pinned")
        XCTAssertTrue(pinnedCard.waitForExistence(timeout: 3))
        pinnedCard.tap()

        let editButton = app.element(withIdentifier: "edit_pinned_forms_button")
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        let addButton = app.element(withIdentifier: "add_forms_button")
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Forms"].waitForExistence(timeout: 3),
                      "Form browser navigation title should be 'Add Forms'")
    }
}
