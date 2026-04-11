import XCTest

final class AppLaunchTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitesting"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// Smoke test: the app must reach the foreground without crashing on a clean launch.
    func test_appLaunchesWithoutCrashing() {
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
