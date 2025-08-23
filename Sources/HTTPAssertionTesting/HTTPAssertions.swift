import Foundation
import XCTest
import HTTPAssertionLogging

/// Asserts that a request matching the given criteria exists
public func HTTPAssertRequested(
    url: String? = nil,
    urlPattern: String? = nil,
    host: String? = nil,
    relativePath: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    since: Date? = Date().addingTimeInterval(-30.0),
    timeout: TimeInterval = 5.0,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        host: host,
        relativePath: relativePath,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    let expectation = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
            // Synchronous predicate check - cannot use async/await here
            // This is a limitation with current XCTest framework
            // We need to check the disk directly
            let requests = HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
            return requests.contains { matcher.matches($0) }
        },
        object: nil
    )
    
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    
    XCTAssertEqual(
        result,
        .completed,
        message(),
        file: (file),
        line: line
    )
}

/// Asserts that no request matching the given criteria exists
public func HTTPAssertNotRequested(
    url: String? = nil,
    urlPattern: String? = nil,
    host: String? = nil,
    relativePath: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    since: Date? = Date().addingTimeInterval(-30.0),
    timeout: TimeInterval = 2.0,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        host: host,
        relativePath: relativePath,
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
    let requests = HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
    let found = requests.contains { matcher.matches($0) }
    
    XCTAssertFalse(
        found,
        message(),
        file: (file),
        line: line
    )
}

/// Gets all requests matching the given criteria
public func HTTPRequests(
    url: String? = nil,
    urlPattern: String? = nil,
    host: String? = nil,
    relativePath: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    since: Date? = Date().addingTimeInterval(-30.0)
) -> [HTTPRequests.HTTPRequest] {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        host: host,
        relativePath: relativePath,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    let requests = HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
    return requests.filter { matcher.matches($0) }
}

/// Asserts that exactly one request matching the given criteria exists
public func HTTPAssertRequestedOnce(
    url: String? = nil,
    urlPattern: String? = nil,
    host: String? = nil,
    relativePath: String? = nil,
    method: String? = nil,
    headers: [String: String]? = nil,
    queryParameters: [String: String]? = nil,
    since: Date? = Date().addingTimeInterval(-30.0),
    timeout: TimeInterval = 5.0,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let matcher = HTTPRequestMatcher(
        url: url,
        urlPattern: urlPattern,
        host: host,
        relativePath: relativePath,
        method: method,
        headers: headers,
        queryParameters: queryParameters
    )
    
    let expectation = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
            // Use HTTPRequests static methods directly
            let requests = HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
            let matchingCount = requests.filter { matcher.matches($0) }.count
            return matchingCount == 1
        },
        object: nil
    )
    
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    
    XCTAssertEqual(
        result,
        .completed,
        message(),
        file: (file),
        line: line
    )
}



// MARK: - Query Parameter Assertions

/// Asserts that a request contains a specific query parameter with the expected value
/// URL-encoded values are automatically decoded for comparison
public func HTTPAssertQueryParameter(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    value: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let url = request.request.url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        XCTFail("Request does not contain any query parameters", file: file, line: line)
        return
    }
    
    let matchingItems = queryItems.filter { $0.name == name }
    
    guard !matchingItems.isEmpty else {
        let availableParams = queryItems.map { $0.name }.joined(separator: ", ")
        XCTFail("Query parameter '\(name)' not found. Available parameters: \(availableParams)", file: file, line: line)
        return
    }
    
    // Check if any of the matching parameters has the expected value
    let foundMatch = matchingItems.contains { item in
        guard let paramValue = item.value else { return value.isEmpty }
        // URL decode the parameter value for comparison
        let decodedValue = paramValue.removingPercentEncoding ?? paramValue
        return decodedValue == value
    }
    
    if !foundMatch {
        let actualValues = matchingItems.compactMap { 
            guard let val = $0.value else { return "nil" }
            return val.removingPercentEncoding ?? val
        }.joined(separator: ", ")
        XCTFail("Query parameter '\(name)' found but value mismatch. Expected: '\(value)', Actual: '\(actualValues)'", file: file, line: line)
    }
}

/// Asserts that a request contains a specific query parameter (regardless of value)
public func HTTPAssertQueryParameterExists(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let url = request.request.url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        XCTFail("Request does not contain any query parameters", file: file, line: line)
        return
    }
    
    let exists = queryItems.contains { $0.name == name }
    
    if !exists {
        let availableParams = queryItems.map { $0.name }.joined(separator: ", ")
        XCTFail("Query parameter '\(name)' not found. Available parameters: \(availableParams)", file: file, line: line)
    }
}

/// Asserts that a request does not contain a specific query parameter
public func HTTPAssertQueryParameterNotExists(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let url = request.request.url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        // If there are no query parameters at all, the assertion passes
        return
    }
    
    let exists = queryItems.contains { $0.name == name }
    
    if exists {
        XCTFail("Query parameter '\(name)' should not exist but was found", file: file, line: line)
    }
}

/// Asserts that a request contains all specified query parameters with their expected values
/// URL-encoded values are automatically decoded for comparison
public func HTTPAssertQueryParameters(
    _ request: HTTPRequests.HTTPRequest?,
    _ expectedParams: [String: String],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    for (name, expectedValue) in expectedParams {
        HTTPAssertQueryParameter(request, name: name, value: expectedValue, file: file, line: line)
    }
}

/// Asserts that a request does NOT contain a specific query parameter with the given value
/// This is useful for testing negative cases where you want to ensure a parameter doesn't have a specific value
/// URL-encoded values are automatically decoded for comparison
public func HTTPAssertQueryParameterNotEqual(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    value: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let url = request.request.url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        // If there are no query parameters at all, the assertion passes
        return
    }
    
    let matchingItems = queryItems.filter { $0.name == name }
    
    // If parameter doesn't exist, assertion passes
    guard !matchingItems.isEmpty else {
        return
    }
    
    // Check if any of the matching parameters has the unwanted value
    let foundMatch = matchingItems.contains { item in
        guard let paramValue = item.value else { return value.isEmpty }
        // URL decode the parameter value for comparison
        let decodedValue = paramValue.removingPercentEncoding ?? paramValue
        return decodedValue == value
    }
    
    if foundMatch {
        XCTFail("Query parameter '\(name)' should not have value '\(value)' but it does", file: file, line: line)
    }
}

// MARK: - Response Status Assertions

/// Asserts that a request has a specific HTTP response status code
public func HTTPAssertResponseStatus(
    _ request: HTTPRequests.HTTPRequest?,
    statusCode: Int,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail(message().isEmpty ? "Request is nil" : message(), file: file, line: line)
        return
    }
    
    guard let response = request.response else {
        XCTFail(message().isEmpty ? "Request has no response" : message(), file: file, line: line)
        return
    }
    
    let actualStatusCode = response.statusCode
    if actualStatusCode != statusCode {
        XCTFail(
            message().isEmpty ? "Response status code mismatch. Expected: \(statusCode), Actual: \(actualStatusCode)" : message(),
            file: file,
            line: line
        )
    }
}

// MARK: - Header Assertions

/// Asserts that a request contains a specific header with the expected value
/// Header names are case-insensitive
public func HTTPAssertHeader(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    value: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let headers = request.request.allHTTPHeaderFields else {
        XCTFail("Request does not contain any headers", file: file, line: line)
        return
    }
    
    // Find header with case-insensitive name matching
    let matchingHeader = headers.first { key, _ in
        key.lowercased() == name.lowercased()
    }
    
    guard let (actualName, actualValue) = matchingHeader else {
        let availableHeaders = headers.keys.joined(separator: ", ")
        XCTFail("Header '\(name)' not found. Available headers: \(availableHeaders)", file: file, line: line)
        return
    }
    
    if actualValue != value {
        XCTFail("Header '\(actualName)' found but value mismatch. Expected: '\(value)', Actual: '\(actualValue)'", file: file, line: line)
    }
}

/// Asserts that a request contains a specific header (regardless of value)
/// Header names are case-insensitive
public func HTTPAssertHeaderExists(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let headers = request.request.allHTTPHeaderFields else {
        XCTFail("Request does not contain any headers", file: file, line: line)
        return
    }
    
    let exists = headers.keys.contains { key in
        key.lowercased() == name.lowercased()
    }
    
    if !exists {
        let availableHeaders = headers.keys.joined(separator: ", ")
        XCTFail("Header '\(name)' not found. Available headers: \(availableHeaders)", file: file, line: line)
    }
}

/// Asserts that a request does not contain a specific header
/// Header names are case-insensitive
public func HTTPAssertHeaderNotExists(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let headers = request.request.allHTTPHeaderFields else {
        // If there are no headers at all, the assertion passes
        return
    }
    
    let exists = headers.keys.contains { key in
        key.lowercased() == name.lowercased()
    }
    
    if exists {
        XCTFail("Header '\(name)' should not exist but was found", file: file, line: line)
    }
}

/// Asserts that a request contains all specified headers with their expected values
/// Header names are case-insensitive
public func HTTPAssertHeaders(
    _ request: HTTPRequests.HTTPRequest?,
    _ expectedHeaders: [String: String],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    for (name, expectedValue) in expectedHeaders {
        HTTPAssertHeader(request, name: name, value: expectedValue, file: file, line: line)
    }
}

/// Asserts that a request does NOT contain a specific header with the given value
/// This is useful for testing negative cases where you want to ensure a header doesn't have a specific value
/// Header names are case-insensitive
public func HTTPAssertHeaderNotEqual(
    _ request: HTTPRequests.HTTPRequest?,
    name: String,
    value: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let request = request else {
        XCTFail("Request is nil", file: file, line: line)
        return
    }
    
    guard let headers = request.request.allHTTPHeaderFields else {
        // If there are no headers at all, the assertion passes
        return
    }
    
    // Find header with case-insensitive name matching
    let matchingHeader = headers.first { key, _ in
        key.lowercased() == name.lowercased()
    }
    
    // If header doesn't exist, assertion passes
    guard let (actualName, actualValue) = matchingHeader else {
        return
    }
    
    if actualValue == value {
        XCTFail("Header '\(actualName)' should not have value '\(value)' but it does", file: file, line: line)
    }
}


