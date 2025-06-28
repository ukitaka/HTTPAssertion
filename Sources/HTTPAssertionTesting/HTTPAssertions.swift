import Foundation
import XCTest
import HTTPAssertionLogging

/// Asserts that a request matching the given criteria exists
public func HTTPAssertRequested(
    url: String? = nil,
    urlPattern: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    timeout: TimeInterval = 5.0,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    let expectation = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
            // Synchronous predicate check - cannot use async/await here
            // This is a limitation with current XCTest framework
            // We need to check the disk directly
            let storage = HTTPRequestStorage.shared
            // Use Task.detached to avoid actor isolation issues
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            Task.detached {
                let requests = await storage.allRequests()
                result = requests.contains { matcher.matches($0) }
                semaphore.signal()
            }
            semaphore.wait()
            return result
        },
        object: nil
    )
    
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    
    XCTAssertEqual(
        result,
        .completed,
        "No HTTP request found matching criteria: \(matcher.description)",
        file: (file),
        line: line
    )
}

/// Asserts that no request matching the given criteria exists
public func HTTPAssertNotRequested(
    url: String? = nil,
    urlPattern: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    timeout: TimeInterval = 2.0,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    // Wait a short time to ensure any pending requests are processed
    let expectation = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
            // Always return false to wait for the full timeout period
            false
        },
        object: nil
    )
    
    let _ = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
    
    // After waiting, check that no matching request exists
    let requests = await HTTPRequestStorage.shared.allRequests()
    let found = requests.contains { matcher.matches($0) }
    
    XCTAssertFalse(
        found,
        "Unexpected HTTP request found matching criteria: \(matcher.description)",
        file: (file),
        line: line
    )
}

/// Gets all requests matching the given criteria
public func HTTPRequests(
    url: String? = nil,
    urlPattern: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil
) async -> [RecordedHTTPRequest] {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    let requests = await HTTPRequestStorage.shared.allRequests()
    return requests.filter { matcher.matches($0) }
}

/// Asserts that exactly one request matching the given criteria exists
public func HTTPAssertRequestedOnce(
    url: String? = nil,
    urlPattern: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    timeout: TimeInterval = 5.0,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    let expectation = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
            let storage = HTTPRequestStorage.shared
            let semaphore = DispatchSemaphore(value: 0)
            var matchingCount = 0
            Task.detached {
                let requests = await storage.allRequests()
                matchingCount = requests.filter { matcher.matches($0) }.count
                semaphore.signal()
            }
            semaphore.wait()
            return matchingCount == 1
        },
        object: nil
    )
    
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    
    XCTAssertEqual(
        result,
        .completed,
        "Expected exactly one HTTP request matching criteria: \(matcher.description)",
        file: (file),
        line: line
    )
}

/// Clears all stored HTTP requests for test cleanup
public func HTTPClearRecordedRequests() async {
    await HTTPRequestStorage.shared.clear()
}

/// Clears all stored data (HTTP requests and contexts) for test cleanup
public func HTTPClearAllData() async {
    await HTTPRequestStorage.shared.clear()
    await Context.shared.clear()
}

