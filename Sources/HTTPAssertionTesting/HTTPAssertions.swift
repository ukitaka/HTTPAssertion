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
            let requests = HTTPRequestStorage.shared.loadRequestsFromDisk()
            return requests.contains { matcher.matches($0) }
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
) {
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
    
    let _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
    
    // After waiting, check that no matching request exists
    let requests = HTTPRequestStorage.shared.loadRequestsFromDisk()
    let found = requests.contains { matcher.matches($0) }
    
    XCTAssertFalse(
        found,
        "Unexpected HTTP request found matching criteria: \(matcher.description)",
        file: (file),
        line: line
    )
}
