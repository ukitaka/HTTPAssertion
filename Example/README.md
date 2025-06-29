# HTTPAssertion Example Project

This directory contains a demo iOS application that demonstrates how to use HTTPAssertion in your projects.

## Project Structure

```
Example/
└── Demo/
    ├── Demo.xcodeproj/           # Xcode project file
    ├── Demo/                     # Main app source code
    │   ├── DemoApp.swift         # App entry point with HTTPAssertion setup
    │   ├── ContentView.swift     # Main UI with HTTP request examples
    │   ├── UserContext.swift     # Example of Context API usage
    │   └── Assets.xcassets/      # App assets
    └── DemoUITests/              # XCUITest suite
        └── DemoUITests.swift     # UI tests demonstrating HTTPAssertion
```

## What This Example Demonstrates

### 1. **HTTPAssertion Setup**
- How to integrate HTTPAssertionLogging into your app
- Proper initialization in `DemoApp.swift`
- Using `#if DEBUG` preprocessor conditions

### 2. **HTTP Request Scenarios**
The demo app includes buttons that trigger various HTTP requests:
- **Simple GET Request**: Basic request to demonstrate logging
- **Search Request**: Google search with query parameters
- **POST Request**: JSON data submission
- **Headers Request**: Request with custom headers
- **Multiple Requests**: Sequential requests for batch testing

### 3. **Context API Usage**
- Sharing data between app and tests using `Context.store()`
- Retrieving shared data in tests using `Context.retrieve()`

### 4. **XCUITest Integration**
The `DemoUITests.swift` file shows:
- How to assert HTTP requests were made
- Waiting for asynchronous requests
- Testing different request types and parameters
- Using various assertion methods

## Running the Example

### Prerequisites

- Xcode 15.0 or later
- iOS Simulator (iOS 15.0 or later)
- **Important**: This example only works in the iOS Simulator, not on physical devices

### Steps

1. **Open the Project**
   ```bash
   cd Example/Demo
   open Demo.xcodeproj
   ```

2. **Build and Run the App**
   - Select iPhone simulator (iOS 15.0+)
   - Build and run the Demo target
   - Interact with the buttons to trigger HTTP requests

3. **Run the UI Tests**
   - Select the Demo scheme
   - Choose Product → Test or press ⌘+U
   - The tests will run automatically and verify HTTP requests

## Code Examples

### App Setup (DemoApp.swift)

```swift
import SwiftUI
import HTTPAssertionLogging

@main
struct DemoApp: App {
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

### Making HTTP Requests (ContentView.swift)

```swift
// Simple GET request
private func performSimpleRequest() {
    guard let url = URL(string: \"https://httpbin.org/get\") else { return }
    URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
}

// POST request with JSON
private func performPostRequest() {
    guard let url = URL(string: \"https://httpbin.org/post\") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = \"POST\"
    request.setValue(\"application/json\", forHTTPHeaderField: \"Content-Type\")
    
    let data = try? JSONSerialization.data(withJSONObject: [\"key\": \"value\"])
    request.httpBody = data
    
    URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
}
```

### Testing HTTP Requests (DemoUITests.swift)

```swift
import XCTest
import HTTPAssertionTesting

func testSimpleGetRequest() throws {
    let app = XCUIApplication()
    app.launch()
    
    app.buttons[\"Simple GET Request\"].tap()
    
    waitForRequest(\"https://httpbin.org/get\", timeout: 5.0)
    HTTPAssertRequestedOnce(\"https://httpbin.org/get\")
}

func testPostRequest() throws {
    let app = XCUIApplication()
    app.launch()
    
    app.buttons[\"POST Request\"].tap()
    
    HTTPAssertRequested(
        \"https://httpbin.org/post\",
        method: \"POST\",
        headers: [\"Content-Type\": \"application/json\"]
    )
}
```

## Learning Points

### 1. **Request Interception**
- All HTTP requests are automatically logged when `HTTPAssertionLogging.start()` is called
- No additional configuration needed for individual requests
- Works with any networking library that uses `URLSession`

### 2. **Cross-Process Communication**
- Data is shared between app and test processes via the simulator's shared directory
- JSON serialization handles complex data types automatically
- Both HTTP requests and custom context data can be shared

### 3. **Flexible Assertions**
- Match requests by URL, method, headers, query parameters
- Support for regular expressions and partial matching
- Built-in waiting functionality for asynchronous operations

### 4. **Best Practices**
- Use `#if DEBUG` to enable logging only in debug builds
- Clear context data between tests to avoid interference
- Use specific assertions (`HTTPAssertRequestedOnce`) when possible
- Set appropriate timeouts for waiting functions

## Troubleshooting

### Common Issues

1. **Tests timing out**
   - Ensure the app is actually making the expected HTTP request
   - Check that HTTPAssertionLogging is properly initialized
   - Verify the URL and parameters match exactly

2. **Requests not being logged**
   - Make sure `HTTPAssertionLogging.start()` is called before making requests
   - **Verify you're running in the iOS Simulator** (required for shared storage - does not work on physical devices)
   - Check that the request uses `URLSession` (directly or indirectly)

3. **Assertion failures**
   - Use `HTTPRequests()` to see all logged requests for debugging
   - Check exact URL matching (including query parameters)
   - Verify HTTP method and headers if specified

## Next Steps

After exploring this example:

1. **Integrate into Your App**: Follow the same pattern in your own application
2. **Customize Assertions**: Adapt the test patterns to your specific HTTP APIs
3. **Extend Context Usage**: Use the Context API for sharing test data
4. **Scale Up**: Apply these patterns to larger test suites and complex workflows

For more information, see the main [README.md](../../README.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md) files.