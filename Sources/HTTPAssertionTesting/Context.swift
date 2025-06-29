import Foundation
import XCTest
import HTTPAssertionLogging

/// Context testing functionality for XCUITest
@available(macOS 13.3, iOS 16.4, *)
public extension Context {
    
    /// Requests context update from the app (for XCUITest)
    static func requestUpdate(app: XCUIApplication) async throws {
        let url = URL(string: "httpassertion://context/update")!
        await app.open(url)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }
    
    /// Waits for a context value to become available or change
    static func waitForContext<T: Codable & Sendable & Equatable>(
        _ type: T.Type,
        forKey key: String,
        expectedValue: T? = nil,
        app: XCUIApplication,
        timeout: TimeInterval = 10.0
    ) async throws -> T? {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            // Request context update
            try await requestUpdate(app: app)
            
            // Try to get the context
            if let value = try await Context.retrieve(type, forKey: key) {
                if let expected = expectedValue {
                    if value == expected {
                        return value
                    }
                } else {
                    return value
                }
            }
            
            // Wait before retrying
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        return nil
    }
    
    /// Waits for a dictionary context to become available or change
    static func waitForContext(
        forKey key: String,
        expectedValue: [String: String]? = nil,
        app: XCUIApplication,
        timeout: TimeInterval = 10.0
    ) async throws -> [String: String]? {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            // Request context update
            try await requestUpdate(app: app)
            
            // Try to get the context
            if let value = try await Context.retrieve(forKey: key) {
                if let expected = expectedValue {
                    if value == expected {
                        return value
                    }
                } else {
                    return value
                }
            }
            
            // Wait before retrying
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        return nil
    }
}