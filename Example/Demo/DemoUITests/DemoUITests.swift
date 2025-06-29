import XCTest
import HTTPAssertionTesting
import HTTPAssertionLogging
import Demo

final class DemoUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = await XCUIApplication()
        await app.launch()
    }
    

    override func tearDown() async throws {
        await Context.clear()
        await HTTPRequests.clear()
        app = nil
    }

    @MainActor
    func testMultipleAPICallsScenario() async throws {
        // Test scenario: User searches on Google and then calls various APIs
        
        // 1. Perform Google search and wait for request
        let searchField = app.textFields["Enter search query"]
        searchField.tap()
        searchField.typeText("Swift programming")
        
        let searchButton = app.buttons["Search on Google"]
        searchButton.tap()
        
        // Wait for Google search request to be fired
        let googleRequest = await waitForRequest(
            urlPattern: ".*google\\.com/search.*",
            method: "GET",
            timeout: 5.0
        )
        XCTAssertNotNil(googleRequest, "Google search request should be fired")
        
        // 2. Call GitHub API and wait for response
        let githubButton = app.buttons["Call GitHub API"]
        githubButton.tap()
        
        // Wait for GitHub API response
        let githubResponse = await waitForResponse(
            url: "https://api.github.com/zen",
            method: "GET",
            timeout: 5.0
        )
        XCTAssertNotNil(githubResponse, "GitHub API should respond")
        XCTAssertEqual(githubResponse?.response?.statusCode, 200, "GitHub API should return 200")
        
        // 3. Call HTTPBin API and wait for response
        let httpbinButton = app.buttons["Call HTTPBin API"]
        httpbinButton.tap()
        
        // Wait for HTTPBin API response
        let httpbinResponse = await waitForResponse(
            url: "https://httpbin.org/uuid",
            method: "GET",
            timeout: 5.0
        )
        XCTAssertNotNil(httpbinResponse, "HTTPBin API should respond")
        XCTAssertEqual(httpbinResponse?.response?.statusCode, 200, "HTTPBin API should return 200")
        
        // 4. Call JSONPlaceholder API and wait for response
        let jsonButton = app.buttons["Call JSONPlaceholder API"]
        jsonButton.tap()
        
        // Wait for JSONPlaceholder API response
        let jsonResponse = await waitForResponse(
            url: "https://jsonplaceholder.typicode.com/posts/1",
            method: "GET",
            timeout: 5.0
        )
        XCTAssertNotNil(jsonResponse, "JSONPlaceholder API should respond")
        XCTAssertEqual(jsonResponse?.response?.statusCode, 200, "JSONPlaceholder API should return 200")
        
        // Verify all requests were made using HTTPAssertRequested
        HTTPAssertRequested(
            urlPattern: ".*google\\.com/search.*",
            method: "GET", queryParameters: ["q": "Swift programming"]
        )
        
        // Test new methods: assert exactly one Google search
        HTTPAssertRequestedOnce(
            urlPattern: ".*google\\.com/search.*",
            method: "GET"
        )
        
        // Test getting requests and checking count
        let googleRequests = await HTTPRequests(urlPattern: ".*google\\.com/search.*")
        XCTAssertEqual(googleRequests.count, 1, "Should have exactly one Google search request")
    }
    
    @MainActor
    @available(macOS 13.3, iOS 16.4, *)
    func testContextUpdate() async throws {
        // Test the context update mechanism and verify that lastUpdated changes
        
        // Wait for initial user_context from periodic updates
        let initialUserContext: UserContext = try await waitForContextUpdate(
            forKey: "user_context",
        )
        
        XCTAssertEqual(initialUserContext.username, "TestUser")
        XCTAssertEqual(initialUserContext.currentScreen, "ContentView")
        XCTAssertEqual(initialUserContext.isLoggedIn, true)
        
        let initialTimestamp = initialUserContext.lastUpdated
        print("Initial lastUpdated: \(initialTimestamp)")
        
        // Wait for the next periodic update using since parameter (no sleep needed)
        let updatedUserContext: UserContext = try await waitForContextUpdate(
            forKey: "user_context",
        )
        
        let updatedTimestamp = updatedUserContext.lastUpdated
        print("Updated lastUpdated: \(updatedTimestamp)")
        
        // Verify that the timestamp has been updated
        XCTAssertGreaterThan(updatedTimestamp, initialTimestamp, "lastUpdated should be more recent after periodic update")
        
        // Verify other fields remain the same
        XCTAssertEqual(updatedUserContext.username, "TestUser")
        XCTAssertEqual(updatedUserContext.currentScreen, "ContentView")
        XCTAssertEqual(updatedUserContext.isLoggedIn, true)
        
        // Also test app_state context
        let appState: AppState = try await waitForContextUpdate(
            forKey: "app_state",
        )
        
        XCTAssertEqual(appState.version, "1.0.0")
        XCTAssertEqual(appState.environment, "debug")
        
        // Verify available context keys
        let allKeys = await Context.listKeys()
        print("All available context keys after update: \(allKeys)")
        XCTAssertTrue(allKeys.contains("user_context"), "Should have user_context key")
        XCTAssertTrue(allKeys.contains("app_state"), "Should have app_state key")
    }
    
    @MainActor
    func testConvenienceAssertionMethods() async throws {
        // Test the new convenience assertion methods
        
        // Example 1: Perform action and assert request was fired
        try await HTTPPerformActionAndAssertRequested(
            urlPattern: ".*google\\.com/search.*",
            method: "GET"
        ) {
            // Action: Search on Google
            let searchField = app.textFields["Enter search query"]
            searchField.tap()
            searchField.typeText("SwiftTesting")
            
            let searchButton = app.buttons["Search on Google"]
            searchButton.tap()
        } onRequested: { request in
            // Verify the request details
            print("Google search request fired: \(request.request.url?.absoluteString ?? "")")
            XCTAssertTrue(request.request.url?.query?.contains("SwiftTesting") == true)
        }
        
        // Example 2: Perform action and wait for response
        try await HTTPPerformActionAndAssertResponse(
            url: "https://api.github.com/zen",
            method: "GET"
        ) {
            // Action: Call GitHub API
            let githubButton = app.buttons["Call GitHub API"]
            githubButton.tap()
        } onRequested: { request in
            // Called when request is fired
            print("GitHub API request fired")
            XCTAssertEqual(request.request.httpMethod, "GET")
        } onResponse: { request in
            // Called when response is received
            print("GitHub API response received")
            XCTAssertNotNil(request.response)
            XCTAssertEqual(request.response?.statusCode, 200)
        }
        
        // Example 3: Multiple actions with different APIs
        try await HTTPPerformActionAndAssertRequested(
            url: "https://httpbin.org/uuid",
            method: "GET"
        ) {
            let httpbinButton = app.buttons["Call HTTPBin API"]
            httpbinButton.tap()
        } onRequested: { request in
            print("HTTPBin request completed")
            XCTAssertEqual(request.request.url?.absoluteString, "https://httpbin.org/uuid")
        }
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = value as? String else { return }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
