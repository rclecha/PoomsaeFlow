import XCTest

/// Regression guard for the Kukkiwon YouTube URL additions in v1.1.
///
/// Jitae, Cheonkwon, Hansu, and Ilyo had empty `videos` arrays before v1.1.
/// These tests verify that each form now shows a "Watch on YouTube" button
/// when encountered in a practice session, confirming the data source change
/// took effect. A missing button means `videos` is still empty for that form.
final class VideoResourceUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
        // Black belt, Sparta TKD — gives access to all nine black belt forms
        app.completeOnboarding(schoolIdentifier: "belt_system_row_spartaTKD", beltRowName: "Black")
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Video button presence

    func test_jitae_showsVideoButton() {
        startSingleFormSession(formName: "Jitae")
        assertVideoButtonVisible(for: "Jitae")
    }

    func test_cheonkwon_showsVideoButton() {
        startSingleFormSession(formName: "Cheonkwon")
        assertVideoButtonVisible(for: "Cheonkwon")
    }

    func test_hansu_showsVideoButton() {
        startSingleFormSession(formName: "Hansu")
        assertVideoButtonVisible(for: "Hansu")
    }

    func test_ilyo_showsVideoButton() {
        startSingleFormSession(formName: "Ilyo")
        assertVideoButtonVisible(for: "Ilyo")
    }

    // MARK: - Helpers

    /// Starts a single-form session by tapping the belt form row matching `formName`.
    /// Black belt users see all nine black belt forms in the Belt Forms section.
    private func startSingleFormSession(formName: String) {
        // Scroll down to Belt Forms section and find the form by name
        let formText = app.staticTexts[formName]
        // Scroll down to find it if not immediately visible
        app.swipeUp()
        XCTAssertTrue(
            formText.waitForExistence(timeout: 5),
            "'\(formName)' form row not found in Belt Forms section — is the belt set to Black?"
        )
        formText.tap()
    }

    private func assertVideoButtonVisible(for formName: String) {
        let videoButton = app.element(withIdentifier: "session_video_button")
        XCTAssertTrue(
            videoButton.waitForExistence(timeout: 5),
            "'\(formName)' must show a 'Watch on YouTube' button — check that VideoResource was added in FormsDataSource"
        )
    }
}
