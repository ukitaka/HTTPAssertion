import Foundation
import XCTest
import HTTPAssertionLogging

/// Asserts that a request matching the given criteria exists
public func assertRequest(
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
    
    let deadline = Date().addingTimeInterval(timeout)
    var found = false
    
    while Date() < deadline && !found {
        let requests = HTTPRequestStorage.shared.loadRequestsFromDisk()
        found = requests.contains { matcher.matches($0) }
        
        if !found {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
    
    XCTAssertTrue(
        found,
        "No HTTP request found matching criteria: \(matcher.description)",
        file: (file),
        line: line
    )
}

/// Asserts that no request matching the given criteria exists
public func assertNoRequest(
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
    
    Thread.sleep(forTimeInterval: timeout)
    
    let requests = HTTPRequestStorage.shared.loadRequestsFromDisk()
    let found = requests.contains { matcher.matches($0) }
    
    XCTAssertFalse(
        found,
        "Unexpected HTTP request found matching criteria: \(matcher.description)",
        file: (file),
        line: line
    )
}


/// Clears all recorded requests (useful for test cleanup)
public func clearAllRequests() {
    HTTPRequestStorage.shared.clear()
}

