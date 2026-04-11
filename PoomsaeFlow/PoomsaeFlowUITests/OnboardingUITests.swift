import XCTest

final class OnboardingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Belt system picker regression

    /// Regression guard for the tap-target bug fixed in the previous session.
    ///
    /// Before the fix, tapping a belt system picker row did not register. This test
    /// verifies that a tap on the Sparta TKD row successfully navigates to the belt
    /// picker — if the row is untappable the navigation title never appears and the
    /// test fails, surfacing the regression immediately.
    func test_tappingBeltSystemRow_navigatesToBeltPicker() {
        let getStarted = app.buttons["Get started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        // Tap the Sparta TKD row
        let spartaRow = app.element(withIdentifier: "belt_system_row_spartaTKD")
        XCTAssertTrue(spartaRow.waitForExistence(timeout: 3))
        spartaRow.tap()

        // Selection registers → BeltPickerView is pushed onto the navigation stack
        let beltPickerNav = app.navigationBars["Select Belt"]
        XCTAssertTrue(
            beltPickerNav.waitForExistence(timeout: 3),
            "BeltPickerView should appear after tapping a belt system row"
        )
    }

    // MARK: - Belt picker navigation

    /// Supplemental: tapping a belt row in BeltPickerView advances to the family step.
    /// Guards against the same class of tap-target regression on the belt list.
    func test_tappingBeltRow_navigatesToFamilyStep() {
        app.buttons["Get started"].tap()

        let spartaRow = app.element(withIdentifier: "belt_system_row_spartaTKD")
        XCTAssertTrue(spartaRow.waitForExistence(timeout: 3))
        spartaRow.tap()

        let whiteRow = app.element(withIdentifier: "belt_row_White")
        XCTAssertTrue(whiteRow.waitForExistence(timeout: 3))
        whiteRow.tap()

        let familyNav = app.navigationBars["Form Families"]
        XCTAssertTrue(
            familyNav.waitForExistence(timeout: 3),
            "FamilyPickerView should appear after tapping a belt row"
        )
    }
}
