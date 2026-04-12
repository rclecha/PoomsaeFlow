import XCTest

extension XCUIApplication {
    /// Searches all element types for the given accessibility identifier.
    /// Use this instead of type-specific queries (buttons, cells, etc.) when the
    /// exact element type may vary by iOS version or SwiftUI rendering.
    func element(withIdentifier identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Returns the full query for elements with the given identifier, for index-based access.
    func elements(withIdentifier identifier: String) -> XCUIElementQuery {
        descendants(matching: .any).matching(identifier: identifier)
    }

    /// Completes the full onboarding flow with the specified school and belt.
    ///
    /// Leaves the app on the Home screen. Call from `setUp` in any UITest class that needs
    /// a pre-onboarded state. `beltRowName` must match the `name` field of a `BeltLevel` in
    /// the chosen school's profile (e.g. "White", "Black").
    func completeOnboarding(
        schoolIdentifier: String = "belt_system_row_spartaTKD",
        beltRowName: String = "White"
    ) {
        let getStarted = buttons["Get started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5), "Welcome screen not visible")
        getStarted.tap()

        let schoolRow = element(withIdentifier: schoolIdentifier)
        XCTAssertTrue(schoolRow.waitForExistence(timeout: 3), "School picker not visible")
        schoolRow.tap()

        let beltRow = element(withIdentifier: "belt_row_\(beltRowName)")
        XCTAssertTrue(beltRow.waitForExistence(timeout: 3), "Belt picker not visible")
        beltRow.tap()

        let doneButton = buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Family step Done button not visible")
        doneButton.tap()

        let homeNav = navigationBars["PoomsaeFlow"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5), "Home screen not visible after onboarding")
    }
}
