import XCTest
import HTTPAssertionTesting
import HTTPAssertionLogging
import Demo

final class DemoUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    

    override func tearDown() {
        Context.clear()
        HTTPRequests.clear()
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
        let googleRequest = waitForRequest(
            urlPattern: ".*google\\.com/search.*",
            method: "GET",
            timeout: 5.0
        )
        XCTAssertNotNil(googleRequest, "Google search request should be fired")
        
        // 2. Call HTTPBin API and wait for response
        
        // 2. Call HTTPBin API and wait for response
        let httpbinButton = app.buttons["Call HTTPBin API"]
        httpbinButton.tap()
        
        // Wait for HTTPBin API response
        let httpbinResponse = waitForResponse(
            urlPattern: "https://httpbin.org/get*",
            method: "GET",
            timeout: 5.0
        )
        XCTAssertNotNil(httpbinResponse, "HTTPBin API should respond")
        HTTPAssertResponseStatus(httpbinResponse, statusCode: 200, "HTTPBin API should return 200 status")
        
        // 3. Call JSONPlaceholder API and wait for response
        let jsonButton = app.buttons["Call JSONPlaceholder API"]
        jsonButton.tap()
        
        // Wait for JSONPlaceholder API response
        let jsonResponse = waitForResponse(
            urlPattern: "https://jsonplaceholder.typicode.com/posts*",
            method: "GET",
            timeout: 5.0
        )
        XCTAssertNotNil(jsonResponse, "JSONPlaceholder API should respond")
        HTTPAssertResponseStatus(jsonResponse, statusCode: 200, "JSONPlaceholder API should return 200 status")
        
        // Verify all requests were made using HTTPAssertRequested
        HTTPAssertRequested(
            urlPattern: ".*google\\.com/search.*",
            method: "GET", queryParameters: ["q": "Swift programming"],
            "Google search request with 'Swift programming' query should exist"
        )
        
        // Test new methods: assert exactly one Google search
        HTTPAssertRequestedOnce(
            urlPattern: ".*google\\.com/search.*",
            method: "GET",
            "There should be exactly one Google search request"
        )
        
        // Test getting requests and checking count
        let googleRequests = HTTPRequests(urlPattern: ".*google\\.com/search.*")
        XCTAssertEqual(googleRequests.count, 1, "Should have exactly one Google search request")
    }
    
    @available(macOS 13.3, iOS 16.4, *)
    func testContextUpdate() throws {
        // Test the context update mechanism and verify that lastUpdated changes
        
        // Wait for initial user_context from periodic updates
        let initialUserContext: UserContext = try waitForContextUpdate(
            forKey: "user_context",
        )
        
        XCTAssertEqual(initialUserContext.username, "TestUser")
        XCTAssertEqual(initialUserContext.currentScreen, "ContentView")
        XCTAssertEqual(initialUserContext.isLoggedIn, true)
        
        let initialTimestamp = initialUserContext.lastUpdated
        print("Initial lastUpdated: \(initialTimestamp)")
        
        // Wait for the next periodic update using since parameter (no sleep needed)
        let updatedUserContext: UserContext = try waitForContextUpdate(
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
        let appState: AppState = try waitForContextUpdate(
            forKey: "app_state",
        )
        
        XCTAssertEqual(appState.version, "1.0.0")
        XCTAssertEqual(appState.environment, "debug")
        
        // Verify available context keys
        let allKeys = Context.listKeys()
        print("All available context keys after update: \(allKeys)")
        XCTAssertTrue(allKeys.contains("user_context"), "Should have user_context key")
        XCTAssertTrue(allKeys.contains("app_state"), "Should have app_state key")
    }
    
    @MainActor
    func testConvenienceAssertionMethods() async throws {
        // Test the new convenience assertion methods
        
        // Example 1: Perform action and assert request was fired
        try await performActionAndAssertRequested(
            urlPattern: ".*google\\.com/search.*",
            method: "GET",
            "SwiftTesting Google search request should be fired after clicking search button"
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
        
        // Example 2: Multiple actions with different APIs
        
        // Example 2: Multiple actions with different APIs
        try await performActionAndAssertRequested(
            urlPattern: "https://httpbin.org/get*",
            method: "GET",
            "HTTPBin GET request should be fired after clicking the button"
        ) {
            let httpbinButton = app.buttons["Call HTTPBin API"]
            httpbinButton.tap()
        } onRequested: { request in
            print("HTTPBin request completed")
            XCTAssertEqual(request.request.url?.absoluteString, "https://httpbin.org/get?source=demo&version=1.0&test_param=hello%20world")
        }
    }
    
    @MainActor
    func testHeaderAndQueryParameterAssertions() async throws {
        // Test header and query parameter assertions with various API calls
        
        // 1. Test HTTPBin API with query parameters and headers
        try await performActionAndAssertRequested(
            urlPattern: "https://httpbin.org/get*",
            method: "GET",
            "HTTPBin request should contain expected query parameters and headers"
        ) {
            let httpbinButton = app.buttons["Call HTTPBin API"]
            httpbinButton.tap()
        } onRequested: { request in
            // Test query parameter assertions
            HTTPAssertQueryParameter(request, name: "source", value: "demo")
            HTTPAssertQueryParameter(request, name: "version", value: "1.0")
            HTTPAssertQueryParameter(request, name: "test_param", value: "hello world") // URL decoded
            
            // Test query parameter existence
            HTTPAssertQueryParameterExists(request, name: "source")
            HTTPAssertQueryParameterExists(request, name: "version")
            HTTPAssertQueryParameterExists(request, name: "test_param")
            
            // Test query parameters that should not exist
            HTTPAssertQueryParameterNotExists(request, name: "api_key")
            HTTPAssertQueryParameterNotExists(request, name: "token")
            
            // Test negative query parameter assertions
            HTTPAssertQueryParameterNotEqual(request, name: "source", value: "production")
            HTTPAssertQueryParameterNotEqual(request, name: "version", value: "2.0")
            
            // Test all query parameters at once
            HTTPAssertQueryParameters(request, [
                "source": "demo",
                "version": "1.0",
                "test_param": "hello world"
            ])
            
            // Test header assertions for HTTPBin
            HTTPAssertHeader(request, name: "Accept", value: "application/json")
            HTTPAssertHeader(request, name: "User-Agent", value: "HTTPAssertion-Demo/1.0")
            HTTPAssertHeader(request, name: "X-Session-ID", value: "demo-session-123")
            
            // Test multiple headers at once
            HTTPAssertHeaders(request, [
                "Accept": "application/json",
                "User-Agent": "HTTPAssertion-Demo/1.0",
                "X-Session-ID": "demo-session-123"
            ])
        }
        
        // 2. Test JSONPlaceholder API with multiple query parameters
        try await performActionAndAssertRequested(
            urlPattern: ".*jsonplaceholder\\.typicode\\.com/posts.*",
            method: "GET",
            "JSONPlaceholder posts request should include userId and page parameters"
        ) {
            let jsonButton = app.buttons["Call JSONPlaceholder API"]
            jsonButton.tap()
        } onRequested: { request in
            // Test query parameter assertions
            HTTPAssertQueryParameter(request, name: "userId", value: "1")
            HTTPAssertQueryParameter(request, name: "page", value: "1")
            
            // Test query parameter convenience methods
            XCTAssertEqual(request.queryParameter(name: "userId"), "1")
            XCTAssertEqual(request.queryParameter(name: "page"), "1")
            XCTAssertNil(request.queryParameter(name: "nonexistent"))
            
            // Test all query parameters
            let allParams = request.allQueryParameters()
            XCTAssertEqual(allParams["userId"], "1")
            XCTAssertEqual(allParams["page"], "1")
            XCTAssertEqual(allParams.count, 2)
            
            // Test has query parameter
            XCTAssertTrue(request.hasQueryParameter(name: "userId"))
            XCTAssertTrue(request.hasQueryParameter(name: "page"))
            XCTAssertFalse(request.hasQueryParameter(name: "limit"))
            
            // Test header assertions
            HTTPAssertHeader(request, name: "Accept", value: "application/json")
            HTTPAssertHeader(request, name: "User-Agent", value: "HTTPAssertion-Demo/1.0")
            HTTPAssertHeader(request, name: "Accept-Language", value: "en-US")
        }
        
        // 3. Test Google search with query parameters (URL encoded)
        try await performActionAndAssertRequested(
            urlPattern: ".*google\\.com/search.*",
            method: "GET",
            "Google search with 'Swift HTTP Testing' query should be properly URL encoded"
        ) {
            let searchField = app.textFields["Enter search query"]
            searchField.tap()
            searchField.typeText("Swift HTTP Testing")
            
            let searchButton = app.buttons["Search on Google"]
            searchButton.tap()
        } onRequested: { request in
            // Test Google search query parameter
            HTTPAssertQueryParameter(request, name: "q", value: "Swift HTTP Testing")
            HTTPAssertQueryParameterExists(request, name: "q")
            
            // Test that the search query is properly URL decoded
            XCTAssertEqual(request.queryParameter(name: "q"), "Swift HTTP Testing")
            
            // Ensure no unwanted parameters
            HTTPAssertQueryParameterNotExists(request, name: "api_key")
            HTTPAssertQueryParameterNotExists(request, name: "session_id")
        }
    }
    
    @MainActor
    func testComplexHeaderAndQueryScenarios() async throws {
        // Test more complex scenarios with mixed headers and query parameters
        
        // Test scenario: Multiple API calls with different patterns
        let searchField = app.textFields["Enter search query"]
        searchField.tap()
        searchField.typeText("iOS Development")
        
        let searchButton = app.buttons["Search on Google"]
        searchButton.tap()
        
        // Wait for Google request and test it
        let googleRequest = waitForRequest(
            urlPattern: ".*google\\.com/search.*",
            method: "GET",
            timeout: 5.0
        )
        
        XCTAssertNotNil(googleRequest)
        if let request = googleRequest {
            // Test that Google search has the expected query parameter
            HTTPAssertQueryParameter(request, name: "q", value: "iOS Development")
            
            // Test using convenience method
            XCTAssertEqual(request.queryParameter(name: "q"), "iOS Development")
        }
        
        // Now test HTTPBin API
        let httpbinButton = app.buttons["Call HTTPBin API"]
        httpbinButton.tap()
        
        let httpbinRequest = waitForRequest(
            urlPattern: "https://httpbin.org/get*",
            method: "GET",
            timeout: 5.0
        )
        
        XCTAssertNotNil(httpbinRequest)
        if let request = httpbinRequest {
            // Test that all expected query parameters are present
            HTTPAssertQueryParameters(request, [
                "source": "demo",
                "version": "1.0",
                "test_param": "hello world"
            ])
            
            // Test that all expected headers are present
            HTTPAssertHeaders(request, [
                "Accept": "application/json",
                "User-Agent": "HTTPAssertion-Demo/1.0",
                "X-Session-ID": "demo-session-123"
            ])
            
            // Test convenience methods
            let queryParams = request.allQueryParameters()
            XCTAssertEqual(queryParams.count, 3)
            XCTAssertTrue(request.hasQueryParameter(name: "source"))
            XCTAssertTrue(request.hasQueryParameter(name: "version"))
            XCTAssertTrue(request.hasQueryParameter(name: "test_param"))
        }
        
        // Verify that we can distinguish between different requests
        let allRequests = HTTPRequests()
        let googleRequests = allRequests.filter { request in
            request.request.url?.host?.contains("google.com") == true
        }
        let httpbinRequests = allRequests.filter { request in
            request.request.url?.host?.contains("httpbin.org") == true
        }
        
        XCTAssertGreaterThan(googleRequests.count, 0, "Should have Google requests")
        XCTAssertGreaterThan(httpbinRequests.count, 0, "Should have HTTPBin requests")
        
        // Test that Google requests don't have HTTPBin-specific parameters
        for request in googleRequests {
            HTTPAssertQueryParameterNotExists(request, name: "source")
            HTTPAssertQueryParameterNotExists(request, name: "version")
        }
        
        // Test that HTTPBin requests don't have Google-specific parameters  
        for request in httpbinRequests {
            HTTPAssertQueryParameterNotExists(request, name: "q")
        }
        
        // Test HTTPAssertNotRequested with custom message
        HTTPAssertNotRequested(
            url: "https://api.example.com/unauthorized",
            method: "POST",
            "No unauthorized API calls should be made during the test"
        )
        
        // Test that no DELETE requests were made
        HTTPAssertNotRequested(
            method: "DELETE",
            "DELETE requests should not be made in this demo app"
        )
    }
    
    @MainActor
    func testXCTAttachmentSupport() async throws {
        // Make a simple HTTP request
        let httpbinButton = app.buttons["Call HTTPBin API"]
        httpbinButton.tap()
        
        // Wait for the response to complete
        let httpbinResponse = waitForResponse(
            urlPattern: "https://httpbin.org/get*",
            method: "GET",
            timeout: 5.0
        )
        
        XCTAssertNotNil(httpbinResponse, "HTTPBin response should be received")
        
        // Create XCTAttachment from the request and add it
        if let request = httpbinResponse {
            let attachment = try XCTAttachment(httpRequest: request)
            add(attachment)
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
