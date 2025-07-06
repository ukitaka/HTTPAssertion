# HTTPAssertion

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-blue.svg?style=flat)](https://swift.org)

HTTPAssertion is a Swift package that enables HTTP request assertion capabilities within XCUITest, allowing you to verify that specific HTTP requests are made during UI interactions that don't have visible UI feedback.

## Features

- 🔍 **HTTP Request Logging**: Automatically intercepts and logs all HTTP requests made by your app
- ✅ **Flexible Assertions**: Assert requests by URL, HTTP method, headers, query parameters, and more
- 💬 **Custom Failure Messages**: Support for custom failure messages in all assertion methods, just like XCTest
- ⏱️ **Wait for Requests**: Built-in waiting functionality for asynchronous request verification
- 📱 **Cross-Process Communication**: Seamless data sharing between app and test processes
- 🧪 **XCUITest Integration**: Designed specifically for XCUITest workflows
- 🚀 **Swift Concurrency**: Built with modern Swift concurrency features

## Architecture

HTTPAssertion consists of two Swift Package libraries:

1. **HTTPAssertionLogging**: Used in your app to log HTTP requests
2. **HTTPAssertionTesting**: Used in your XCUITests to make assertions about those requests

## Installation

### Swift Package Manager

Add HTTPAssertion to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ukitaka/HTTPAssertion.git", from: "0.1.0")
]
```

Add the appropriate targets to your app and test targets:

```swift
// For your app target
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "HTTPAssertionLogging", package: "HTTPAssertion")
    ]
)

// For your XCUITest target
.target(
    name: "YourAppUITests",
    dependencies: [
        .product(name: "HTTPAssertionTesting", package: "HTTPAssertion")
    ]
)
```

## Usage

### 1. Enable HTTP Logging in Your App

Add HTTP logging to your app, typically in your App delegate or main app file:

```swift
import HTTPAssertionLogging

#if DEBUG
HTTPAssertionLogging.start()
#endif
```

For SwiftUI apps, you can add it to your main App struct:

```swift
import SwiftUI
import HTTPAssertionLogging

@main
struct MyApp: App {
    init() {
        #if DEBUG
        HTTPAssertionLogging.start()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Write Assertions in Your XCUITests

Import HTTPAssertionTesting in your test files and use the assertion functions:

```swift
import XCTest
import HTTPAssertionTesting

class MyAppUITests: XCTestCase {
    
    func testSearchButtonSendsAnalytics() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Perform UI interaction
        app.buttons["Search"].tap()
        
        // Assert that the expected HTTP request was made
        HTTPAssertRequested("https://analytics.example.com/event")
        
        // Or with a custom failure message
        HTTPAssertRequested(
            "https://analytics.example.com/event",
            "Analytics event should be sent when search button is tapped"
        )
    }
    
    func testLoginRequest() async throws {
        let app = XCUIApplication()
        app.launch()
        
        app.textFields["username"].tap()
        app.textFields["username"].typeText("testuser")
        app.textFields["password"].tap()
        app.textFields["password"].typeText("password")
        app.buttons["Login"].tap()
        
        // Wait for and assert login request
        await waitForRequest(
            url: "https://api.example.com/login",
            method: "POST",
            timeout: 5.0
        )
        
        HTTPAssertRequestedOnce(
            "https://api.example.com/login",
            "Login API should be called exactly once"
        )
    }
}
```

## API Reference

### HTTPAssertionLogging

#### HTTPAssertionLogging

Main class for controlling HTTP request logging:

```swift
// Start logging HTTP requests
HTTPAssertionLogging.start()

// Stop logging HTTP requests
HTTPAssertionLogging.stop()
```

#### Context

Share data between your app and tests:

```swift
// In your app
Context.store("user_id", value: "12345")

// In your tests
let userId: String? = Context.retrieve("user_id")
```

### HTTPAssertionTesting

#### Assertion Functions

```swift
// Assert that a request was made
HTTPAssertRequested("https://api.example.com/data")

// Assert with custom failure message
HTTPAssertRequested(
    "https://api.example.com/data",
    "Data API should be called during app startup"
)

// Assert that a request was NOT made
await HTTPAssertNotRequested("https://api.example.com/sensitive")

// Assert with custom message for not requested
await HTTPAssertNotRequested(
    "https://api.example.com/sensitive",
    "Sensitive API should never be called in this test scenario"
)

// Assert that a request was made exactly once
HTTPAssertRequestedOnce(
    "https://api.example.com/analytics",
    "Analytics should be sent exactly once per user action"
)

// Get all matching requests
let requests = await HTTPRequests(url: "https://api.example.com/search")
```

#### Advanced Matching

```swift
// Match by HTTP method
HTTPAssertRequested(
    "https://api.example.com/data",
    method: "POST",
    "POST request should be made to data endpoint"
)

// Match by headers
HTTPAssertRequested(
    "https://api.example.com/data",
    headers: ["Authorization": "Bearer token123"],
    "Request should include proper authorization header"
)

// Match by query parameters
HTTPAssertRequested(
    "https://api.example.com/search",
    queryParameters: ["q": "swift", "limit": "10"],
    "Search request should include query and limit parameters"
)

// Use regular expressions for URL patterns
HTTPAssertRequested(
    urlPattern: "https://api\\.example\\.com/users/\\d+",
    "User API should be called with numeric user ID"
)
```

#### Waiting for Requests

```swift
// Wait for a request to be made (in XCTestCase)
await waitForRequest(url: "https://api.example.com/data", timeout: 10.0)

// Wait for a response to be received  
await waitForResponse(url: "https://api.example.com/data", timeout: 10.0)

// Wait with custom conditions
await waitForRequest(
    urlPattern: "https://api\\.example\\.com/analytics.*",
    method: "POST",
    timeout: 5.0
)
```

#### Perform Action and Assert Request

Combine UI actions with HTTP request assertions in a single call:

```swift
// Perform an action and wait for a specific HTTP request (in XCTestCase)
try await performActionAndAssertRequested(
    urlPattern: "https://api\\.example\\.com/search.*",
    method: "GET",
    "Search API should be called after tapping search button",
    timeout: 5.0
) {
    // UI action that should trigger the HTTP request
    app.textFields["searchField"].tap()
    app.textFields["searchField"].typeText("swift")
    app.buttons["Search"].tap()
} onRequested: { request in
    // Optional: Inspect the captured request
    print("Search request made: \(request.request.url?.absoluteString ?? "")")
    
    // Additional assertions on the request
    XCTAssertTrue(request.request.url?.query?.contains("q=swift") == true)
}

// Simplified version without request inspection
try await performActionAndAssertRequested(
    url: "https://analytics.example.com/event",
    method: "POST",
    "Analytics event should be triggered by button tap"
) {
    app.buttons["Track Event"].tap()
}

// Wait for both request and response
try await performActionAndAssertResponse(
    url: "https://api.example.com/login",
    method: "POST",
    "Login request should complete successfully"
) {
    app.buttons["Login"].tap()
} onRequested: { request in
    print("Login request sent")
} onResponse: { request in
    print("Login response received")
    XCTAssertEqual(request.response?.statusCode, 200)
}
```

## How It Works

1. **HTTP Interception**: HTTPAssertionLogging uses method swizzling to intercept `URLSessionConfiguration.default` and `URLSessionConfiguration.ephemeral`, adding a custom `URLProtocol` that logs all HTTP requests and responses.

2. **Cross-Process Storage**: Request data is stored in the simulator's shared resources directory (`SIMULATOR_SHARED_RESOURCES_DIRECTORY/Library/Caches/HTTPAssertion/`) as JSON files, allowing both app and test processes to access the same data.

3. **Flexible Matching**: HTTPAssertionTesting provides powerful matching capabilities using `HTTPRequestMatcher`, supporting exact matches, regular expressions, and multiple criteria combinations.

4. **Async Support**: Built with Swift concurrency features, providing thread-safe operations and efficient async/await APIs.

## Testing Best Practices

### When to Use HTTPAssertion

HTTPAssertion is designed for **integration testing scenarios** where you need to verify that UI interactions trigger the correct network requests. However, it's important to understand when this tool is appropriate and when other testing approaches are preferable.

#### ✅ **Good Use Cases**
- **End-to-end UI testing**: Verifying that user interactions (button taps, form submissions) trigger expected analytics or logging requests
- **Integration verification**: Ensuring UI flows correctly integrate with backend APIs
- **Third-party SDK validation**: Testing that external SDKs make expected network calls
- **Cross-component testing**: Verifying complex user journeys that span multiple app components

#### ❌ **Consider Unit Tests Instead**
- **HTTP client logic**: Test your networking layer directly with unit tests
- **Request formatting**: Use unit tests to verify URL construction, headers, and request bodies
- **Response parsing**: Test JSON decoding and data transformation in isolation
- **Business logic**: Test your service and repository layers independently
- **Error handling**: Unit test how your app handles network errors and edge cases

### Recommended Testing Strategy

Follow the **testing pyramid** principle:

```
    /\
   /  \     <- Few UI tests (including HTTPAssertion)
  /____\
 /      \    <- Some integration tests
/__________\  <- Many unit tests
```

1. **Unit Tests (Most)**: Test individual components, HTTP clients, and business logic in isolation
2. **Integration Tests (Some)**: Test how components work together, including API contracts
3. **UI Tests with HTTPAssertion (Few)**: Test critical user journeys and ensure UI properly triggers network requests

HTTPAssertion fills the gap between unit tests and pure UI testing, but it shouldn't replace proper unit testing of your networking layer.

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 15.0+
- **iOS Simulator only** (does not work on physical devices due to shared storage requirements)

## Example Project

Check out the included example project in the `Example/Demo` directory to see HTTPAssertion in action.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

HTTPAssertion is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Acknowledgments

This project was inspired by [netfox](https://github.com/kasketis/netfox) for HTTP interception techniques.