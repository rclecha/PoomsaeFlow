import XCTest

/// Tests the pin-a-form → Pinned card flow.
///
/// These tests are expected to FAIL, documenting a known bug: pinning a form during a
/// session does not update the Pinned card subtitle on HomeView. The tests express the
/// correct expected behaviour so they will turn green automatically when the bug is fixed.
final class PinnedFormsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        completeOnboarding()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Tests

    /// Known bug: pinning a form in session should show "1 pinned" on the Pinned card.
    func test_pinFirstForm_pinnedCardShowsOnePin() {
        // HomeView should show "No pinned forms yet" on the Pinned card before any pins
        XCTAssertTrue(
            app.staticTexts["No pinned forms yet"].waitForExistence(timeout: 3),
            "Pinned card should start with 'No pinned forms yet'"
        )

        pinFirstBeltForm()

        // After pinning, the Pinned card subtitle must update — this assertion documents the bug
        XCTAssertTrue(
            app.staticTexts["1 pinned"].waitForExistence(timeout: 3),
            "Pinned card should show '1 pinned' after pinning one form (known failing — bug not yet fixed)"
        )
    }

    /// Known bug: pinning a second form should show "2 pinned" on the Pinned card.
    func test_pinTwoForms_pinnedCardShowsTwoPins() {
        pinFirstBeltForm()

        // Pin a second form (second row in Belt Forms section)
        pinBeltFormAtIndex(1)

        XCTAssertTrue(
            app.staticTexts["2 pinned"].waitForExistence(timeout: 3),
            "Pinned card should show '2 pinned' after pinning two forms (known failing — bug not yet fixed)"
        )
    }

    // MARK: - Helpers

    /// Completes the onboarding flow with Sparta TKD at White belt so the app lands on HomeView.
    private func completeOnboarding() {
        let getStarted = app.buttons["Get started"]
        guard getStarted.waitForExistence(timeout: 5) else {
            XCTFail("Welcome screen did not appear")
            return
        }
        getStarted.tap()

        let spartaRow = app.element(withIdentifier: "belt_system_row_spartaTKD")
        guard spartaRow.waitForExistence(timeout: 3) else {
            XCTFail("Belt system picker did not appear")
            return
        }
        spartaRow.tap()

        let whiteRow = app.element(withIdentifier: "belt_row_White")
        guard whiteRow.waitForExistence(timeout: 3) else {
            XCTFail("Belt picker did not appear")
            return
        }
        whiteRow.tap()

        let doneButton = app.buttons["Done"]
        guard doneButton.waitForExistence(timeout: 3) else {
            XCTFail("Family picker Done button did not appear")
            return
        }
        doneButton.tap()

        // Wait for HomeView to settle
        XCTAssertTrue(
            app.navigationBars["PoomsaeFlow"].waitForExistence(timeout: 5),
            "HomeView should appear after completing onboarding"
        )
    }

    /// Pins the first belt form row: starts its session, taps the pin button, completes the session.
    private func pinFirstBeltForm() {
        pinBeltFormAtIndex(0)
    }

    private func pinBeltFormAtIndex(_ index: Int) {
        let beltFormRows = app.elements(withIdentifier: "belt_form_row")
        let row = beltFormRows.element(boundBy: index)
        XCTAssertTrue(row.waitForExistence(timeout: 3), "Belt form row at index \(index) must exist")
        row.tap()

        // SessionView appears — tap the pin button in the navigation toolbar
        let pinButton = app.element(withIdentifier: "pin_button")
        XCTAssertTrue(pinButton.waitForExistence(timeout: 3), "Pin button must appear in session")
        pinButton.tap()

        // Complete the single-form session
        let nailedIt = app.buttons["Nailed it"]
        XCTAssertTrue(nailedIt.waitForExistence(timeout: 3))
        nailedIt.tap()

        // Dismiss SessionCompleteView and return to HomeView
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()

        XCTAssertTrue(
            app.navigationBars["PoomsaeFlow"].waitForExistence(timeout: 3),
            "HomeView should reappear after session completes"
        )
    }
}
