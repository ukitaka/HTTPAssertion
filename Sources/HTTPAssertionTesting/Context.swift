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
    }
}
