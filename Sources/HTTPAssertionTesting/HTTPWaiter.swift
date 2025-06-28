import Foundation
import XCTest
import HTTPAssertionLogging

/// Namespace for wait-related HTTP testing methods
public enum HTTPWaiter {
    
    /// Waits for a request matching the given criteria to receive a response
    public static func waitForResponse(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> RecordedHTTPRequest? {
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
                var foundRequest: RecordedHTTPRequest? = nil
                Task.detached {
                    let requests = await storage.allRequests()
                    foundRequest = requests.first { matcher.matches($0) && $0.response != nil }
                    semaphore.signal()
                }
                semaphore.wait()
                return foundRequest != nil
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            let requests = await HTTPRequestStorage.shared.allRequests()
            return requests.first { matcher.matches($0) && $0.response != nil }
        } else {
            XCTFail(
                "Request matching criteria did not receive response within timeout: \(matcher.description)",
                file: file,
                line: line
            )
            return nil
        }
    }
    
    /// Waits for a specific recorded request to receive a response
    public static func waitForResponse(
        for recordedRequest: RecordedHTTPRequest,
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> RecordedHTTPRequest? {
        let requestID = recordedRequest.id
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                let storage = HTTPRequestStorage.shared
                let semaphore = DispatchSemaphore(value: 0)
                var foundRequest: RecordedHTTPRequest? = nil
                Task.detached {
                    let requests = await storage.allRequests()
                    foundRequest = requests.first { $0.id == requestID && $0.response != nil }
                    semaphore.signal()
                }
                semaphore.wait()
                return foundRequest != nil
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            let requests = await HTTPRequestStorage.shared.allRequests()
            return requests.first { $0.id == requestID && $0.response != nil }
        } else {
            XCTFail(
                "Request with ID \(requestID) did not receive response within timeout",
                file: file,
                line: line
            )
            return nil
        }
    }
}