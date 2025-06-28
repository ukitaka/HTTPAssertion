import XCTest
import HTTPAssertionTesting
import HTTPAssertionLogging
import Demo

final class DemoUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        await HTTPClearAllData()
        app = await XCUIApplication()
        await app.launch()
    }
    

    override func tearDown() async throws {
        await HTTPClearRecordedRequests()
        app = nil
    }

    @MainActor
    func testMultipleAPICallsScenario() async throws {
        // Test scenario: User searches on Google and then calls various APIs
        
        // 1. Perform Google search
        let searchField = app.textFields["Enter search query"]
        searchField.tap()
        searchField.typeText("Swift programming")
        
        let searchButton = app.buttons["Search on Google"]
        searchButton.tap()
        
        try await Task.sleep(for: .seconds(1))
        
        // 2. Call GitHub API
        let githubButton = app.buttons["Call GitHub API"]
        githubButton.tap()
        
        try await Task.sleep(for: .seconds(1))
        
        // 3. Call HTTPBin API
        let httpbinButton = app.buttons["Call HTTPBin API"]
        httpbinButton.tap()
        
        try await Task.sleep(for: .seconds(1))
        
        // 4. Call JSONPlaceholder API
        let jsonButton = app.buttons["Call JSONPlaceholder API"]
        jsonButton.tap()
        
        try await Task.sleep(for: .seconds(2))
        
        // Verify all requests were made using HTTPAssertRequested
        HTTPAssertRequested(
            urlPattern: ".*google\\.com/search.*",
            method: "GET", queryParameters: ["q": "Swift programming"]
        )
        
        HTTPAssertRequested(
            url: "https://api.github.com/zen",
            method: "GET"
        )
        
        HTTPAssertRequested(
            url: "https://httpbin.org/uuid",
            method: "GET"
        )
        
        HTTPAssertRequested(
            url: "https://jsonplaceholder.typicode.com/posts/1",
            method: "GET"
        )
        
        // Test new methods: assert exactly one Google search
        HTTPAssertRequestedOnce(
            urlPattern: ".*google\\.com/search.*",
            method: "GET"
        )
        
        // Test getting requests and checking count
        let googleRequests = await HTTPRequests(urlPattern: ".*google\\.com/search.*")
        XCTAssertEqual(googleRequests.count, 1, "Should have exactly one Google search request")
        
        // Test waiting for response using URL criteria
        if let githubResponse = await HTTPWaiter.waitForResponse(url: "https://api.github.com/zen") {
            XCTAssertNotNil(githubResponse.response, "GitHub request should have received a response")
            XCTAssertEqual(githubResponse.response?.statusCode, 200, "GitHub API should return 200")
        }
        
        // Test waiting for response using specific RecordedHTTPRequest
        let httpbinRequests = await HTTPRequests(url: "https://httpbin.org/uuid")
        if let httpbinRequest = httpbinRequests.first {
            if let httpbinResponse = await HTTPWaiter.waitForResponse(for: httpbinRequest) {
                XCTAssertNotNil(httpbinResponse.response, "HTTPBin request should have received a response")
                XCTAssertEqual(httpbinResponse.response?.statusCode, 200, "HTTPBin API should return 200")
            }
        }
    }
    
    @MainActor
    func testContextStorage() async throws {
        // Wait for the context to be stored on app launch
        try await Task.sleep(for: .seconds(1))
        
        // Retrieve the stored user context
        if let userContext = try await HTTPRetrieveContext(UserContext.self, forKey: "currentUser") {
            XCTAssertEqual(userContext.userID, "test-user-123")
            XCTAssertEqual(userContext.username, "demouser")
            XCTAssertEqual(userContext.deviceInfo.deviceModel, "iPhone Simulator")
            XCTAssertNotNil(userContext.sessionStartTime)
        } else {
            XCTFail("User context should be available")
        }
        
        // Test context key listing
        let contextKeys = await HTTPListContextKeys()
        XCTAssertTrue(contextKeys.contains("currentUser"), "Should have currentUser context key")
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = value as? String else { return }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
