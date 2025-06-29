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
    since: Date? = Date().addingTimeInterval(-30.0),
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
            // Use HTTPRequests static methods directly
            // Use Task.detached to avoid actor isolation issues
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            Task.detached {
                let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
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
    since: Date? = Date().addingTimeInterval(-30.0),
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
    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
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
    queryParameters: [String: String]? = nil,
    since: Date? = Date().addingTimeInterval(-30.0)
) async -> [HTTPRequests.HTTPRequest] {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
    return requests.filter { matcher.matches($0) }
}

/// Asserts that exactly one request matching the given criteria exists
public func HTTPAssertRequestedOnce(
    url: String? = nil,
    urlPattern: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    since: Date? = Date().addingTimeInterval(-30.0),
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
            // Use HTTPRequests static methods directly
            let semaphore = DispatchSemaphore(value: 0)
            var matchingCount = 0
            Task.detached {
                let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
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

