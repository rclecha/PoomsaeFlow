import XCTest

/// End-to-end tests for the session flow, covering outcome recording and the
/// session summary screen.
final class SessionUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        // White belt, Sparta TKD — guarantees at least one belt form (Taegeuk Il Jang)
        app.completeOnboarding()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Full Set card

    /// Tapping the Full Set card must open the Session Setup sheet.
    /// Replaces the removed toolbar play button as the primary entry point for a full-set session.
    func test_fullSetCard_opensSessionSetup() {
        let fullSetCard = app.staticTexts["Full set"]
        XCTAssertTrue(fullSetCard.waitForExistence(timeout: 3),
                      "Full Set card must be visible on the home screen")
        fullSetCard.tap()

        XCTAssertTrue(
            app.navigationBars["Session Setup"].waitForExistence(timeout: 3),
            "Tapping the Full Set card must open the Session Setup sheet"
        )
    }

    /// The toolbar play button must no longer appear on the home screen.
    func test_homeScreen_hasNoPlayButtonInToolbar() {
        XCTAssertTrue(
            app.navigationBars["PoomsaeFlow"].waitForExistence(timeout: 3),
            "Home screen must be visible before asserting button absence"
        )
        XCTAssertFalse(
            app.buttons["Start"].exists,
            "Play button must no longer appear in the home screen toolbar"
        )
    }

    // MARK: - Retry → Skip

    /// Tapping Retry then Skip must record the retry in the session summary.
    ///
    /// Regression for the bug where SessionCompleteView.retriedCount only counted
    /// .passedAfterRetry outcomes, silently ignoring .skipped attempts with retryCount > 0.
    ///
    /// Expected summary for a 1-form retry → skip session:
    ///   Nailed it       0
    ///   Retry attempts  1   ← would show 0 before the fix
    ///   Skipped         1
    func test_retryThenSkip_summaryShowsNeededRetriesOne() {
        // Start a single-form session from the Belt Forms section
        let firstRow = app.elements(withIdentifier: "belt_form_row").firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3),
                      "Belt form row must exist for a White belt user")
        firstRow.tap()

        // Tap Retry — form stays current, retryCount increments to 1
        let retryButton = app.buttons["Retry"]
        XCTAssertTrue(retryButton.waitForExistence(timeout: 3),
                      "Retry button must appear in the session view")
        retryButton.tap()

        // Tap Skip — terminal outcome; 1-form queue is now exhausted, summary appears
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3),
                      "Skip button must appear in the session view")
        skipButton.tap()

        // Session complete overlay must appear
        XCTAssertTrue(
            app.staticTexts["Session Complete"].waitForExistence(timeout: 3),
            "Session Complete screen must appear after the only form is skipped"
        )

        // "Retry attempts" label must be present in the summary table
        XCTAssertTrue(
            app.staticTexts["Retry attempts"].exists,
            "'Retry attempts' label must appear in the session summary"
        )

        // SummaryRow renders label and count as separate Text elements (no .combine modifier).
        // In a 1-form retry→skip session the count column shows: 0, 1, 1.
        // Exactly two staticTexts with label "1" proves Retry attempts = 1.
        // Before the fix, Retry attempts showed 0, leaving only one "1" (Skipped).
        let oneLabels = app.staticTexts.matching(NSPredicate(format: "label == '1'"))
        XCTAssertEqual(
            oneLabels.count, 2,
            "'Retry attempts' and 'Skipped' must each show 1. " +
            "Count of 1 means Retry attempts is still showing 0 — retry was not counted."
        )
    }
}
