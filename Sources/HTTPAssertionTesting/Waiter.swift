import Foundation
import XCTest
import HTTPAssertionLogging

/// XCTestCase extensions for HTTP assertion wait methods
public extension XCTestCase {
    
    // MARK: - HTTP Request Wait Methods
    
    /// Waits for a request matching the given criteria to receive a response
    func waitForResponse(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        since: Date? = Date().addingTimeInterval(-30.0),
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> HTTPRequests.HTTPRequest? {
        let matcher = HTTPRequestMatcher(
            url: url,
            urlPattern: urlPattern,
            method: method,
            headers: headers,
            queryParameters: queryParameters
        )
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                // Use HTTPRequests static methods directly
                let semaphore = DispatchSemaphore(value: 0)
                var foundRequest: HTTPRequests.HTTPRequest? = nil
                Task.detached {
                    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
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
            let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
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
    func waitForResponse(
        for recordedRequest: HTTPRequests.HTTPRequest,
        since: Date? = Date().addingTimeInterval(-30.0),
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> HTTPRequests.HTTPRequest? {
        let requestID = recordedRequest.id
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                // Use HTTPRequests static methods directly
                let semaphore = DispatchSemaphore(value: 0)
                var foundRequest: HTTPRequests.HTTPRequest? = nil
                Task.detached {
                    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
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
            let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
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
    
    /// Waits for a request matching the given criteria to be fired, regardless of response status
    func waitForRequest(
        url: String? = nil,
        urlPattern: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        since: Date? = Date().addingTimeInterval(-30.0),
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> HTTPRequests.HTTPRequest? {
        let matcher = HTTPRequestMatcher(
            url: url,
            urlPattern: urlPattern,
            method: method,
            headers: headers,
            queryParameters: queryParameters
        )
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                // Use HTTPRequests static methods directly
                let semaphore = DispatchSemaphore(value: 0)
                var foundRequest: HTTPRequests.HTTPRequest? = nil
                Task.detached {
                    let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
                    foundRequest = requests.first { matcher.matches($0) }
                    semaphore.signal()
                }
                semaphore.wait()
                return foundRequest != nil
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            let requests = await HTTPRequests.recentRequests(sortBy: .requestTime, since: since)
            return requests.first { matcher.matches($0) }
        } else {
            XCTFail(
                "Request matching criteria was not fired within timeout: \(matcher.description)",
                file: file,
                line: line
            )
            return nil
        }
    }
    
    // MARK: - Context Wait Methods
    
    /// Requests context update from the app (for XCUITest)
    @available(macOS 13.3, iOS 16.4, *)
    func requestContextUpdate(app: XCUIApplication) async throws {
        try await Context.requestUpdate(app: app)
    }
    
    // MARK: - Context Wait Methods
    
    /// Waits for a context value to be updated or become available
    @available(macOS 13.3, iOS 16.4, *)
    func waitForContextUpdate<T: Codable & Sendable>(
        forKey key: String,
        app: XCUIApplication,
        timeout: TimeInterval = 10.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T? {
        // Request initial context update
        try await Context.requestUpdate(app: app)
        
        // Small delay to ensure the URL has been processed
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Record the time after the delay
        let requestTime = Date()
        
        // Get the context file URL using FileStorage
        guard let fileURL = await Context.storage.fileURL(forKey: key) else {
            XCTFail("Could not determine context file path", file: file, line: line)
            return nil
        }
        
        let filePath = fileURL.path
        
        // Check if file existed before the request
        let fileExistedBefore = FileManager.default.fileExists(atPath: filePath)
        
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ -> Bool in
                let semaphore = DispatchSemaphore(value: 0)
                var fileWasUpdated = false
                
                Task.detached {
                    let fm = FileManager.default
                    // Check if file exists now
                    if fm.fileExists(atPath: filePath) {
                        if !fileExistedBefore {
                            // File was created after the request - this counts as an update
                            fileWasUpdated = true
                        } else if let attributes = try? fm.attributesOfItem(atPath: filePath),
                                  let modificationDate = attributes[.modificationDate] as? Date {
                            // File existed before, check if it was modified after the request
                            fileWasUpdated = modificationDate > requestTime
                        }
                    } else {
                        // File still doesn't exist
                        fileWasUpdated = false
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                return fileWasUpdated
            },
            object: nil
        )
        
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: timeout)
        
        if result == .completed {
            return try await Context.retrieve(T.self, forKey: key)
        } else {
            XCTFail(
                "Context value for key '\(key)' was not found within timeout",
                file: file,
                line: line
            )
            return nil
        }
    }
}
