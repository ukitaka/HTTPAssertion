import XCTest
import HTTPAssertionTesting

final class DemoUITests: XCTestCase {
    var app: XCUIApplication!
    var httpTester: HTTPAssertionTester!

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
        
        httpTester = HTTPAssertionTester()
    }

    override func tearDownWithError() throws {
        app = nil
        httpTester = nil
    }

    @MainActor
    func testMultipleAPICallsScenario() throws {
        // Test scenario: User searches on Google and then calls various APIs
        
        // 1. Perform Google search
        let searchField = app.textFields["Enter search query"]
        searchField.tap()
        searchField.typeText("Swift programming")
        
        let searchButton = app.buttons["Search on Google"]
        searchButton.tap()
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // 2. Call GitHub API
        let githubButton = app.buttons["Call GitHub API"]
        githubButton.tap()
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // 3. Call HTTPBin API
        let httpbinButton = app.buttons["Call HTTPBin API"]
        httpbinButton.tap()
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // 4. Call JSONPlaceholder API
        let jsonButton = app.buttons["Call JSONPlaceholder API"]
        jsonButton.tap()
        
        Thread.sleep(forTimeInterval: 2.0)
        
        // Verify all requests were made using assertRequest
        httpTester.assertRequest(
            urlPattern: ".*google\\.com/search.*",
            method: "GET", queryParameters: ["q": "Swift programming"]
        )
        
        httpTester.assertRequest(
            url: "https://api.github.com/zen",
            method: "GET"
        )
        
        httpTester.assertRequest(
            url: "https://httpbin.org/uuid",
            method: "GET"
        )
        
        httpTester.assertRequest(
            url: "https://jsonplaceholder.typicode.com/posts/1",
            method: "GET"
        )
        
        // Verify we can get all requests at once
        let allRequests = httpTester.requests()
        XCTAssertGreaterThanOrEqual(allRequests.count, 4, "Should have at least 4 requests")
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = value as? String else { return }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
