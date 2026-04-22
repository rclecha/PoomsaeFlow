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

    // MARK: - Retry → Skip

    /// Tapping Retry then Skip must record the retry in the session summary.
    ///
    /// Regression for the bug where SessionCompleteView.retriedCount only counted
    /// .passedAfterRetry outcomes, silently ignoring .skipped attempts with retryCount > 0.
    ///
    /// Expected summary for a 1-form retry → skip session:
    ///   Nailed it      0
    ///   Needed retries 1   ← would show 0 before the fix
    ///   Skipped        1
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

        // "Needed retries" label must be present in the summary table
        XCTAssertTrue(
            app.staticTexts["Needed retries"].exists,
            "'Needed retries' label must appear in the session summary"
        )

        // SummaryRow renders label and count as separate Text elements (no .combine modifier).
        // In a 1-form retry→skip session the count column shows: 0, 1, 1.
        // Exactly two staticTexts with label "1" proves Needed retries = 1.
        // Before the fix, Needed retries showed 0, leaving only one "1" (Skipped).
        let oneLabels = app.staticTexts.matching(NSPredicate(format: "label == '1'"))
        XCTAssertEqual(
            oneLabels.count, 2,
            "'Needed retries' and 'Skipped' must each show 1. " +
            "Count of 1 means Needed retries is still showing 0 — retry was not counted."
        )
    }
}
