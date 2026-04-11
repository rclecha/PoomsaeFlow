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
}
