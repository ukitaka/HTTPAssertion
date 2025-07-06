import Foundation
import XCTest
import HTTPAssertionLogging

/// Convenience extensions for XCTAttachment to handle HTTP requests
extension XCTAttachment {
    
    /// Creates an XCTAttachment containing the HTTPRequest as JSON
    /// - Parameter httpRequest: The HTTPRequest to convert to JSON
    /// - Throws: EncodingError if the request cannot be encoded to JSON
    public convenience init(httpRequest: HTTPRequests.HTTPRequest) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(httpRequest)
        
        self.init(data: jsonData, uniformTypeIdentifier: "public.json")
        self.name = "HTTPRequest-\(httpRequest.id)"
    }
}
