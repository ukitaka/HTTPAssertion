import XCTest
@testable import HTTPAssertion

final class HTTPAssertionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        HTTPAssertion.clearRecordedRequests()
    }
    
    override func tearDown() {
        HTTPAssertion.stop()
        super.tearDown()
    }
    
    func testStartAndStop() {
        // Test that start and stop can be called without issues
        HTTPAssertion.start()
        HTTPAssertion.stop()
        
        // Can be called multiple times safely
        HTTPAssertion.start()
        HTTPAssertion.start()
        HTTPAssertion.stop()
        HTTPAssertion.stop()
    }
    
    func testClearRecordedRequests() {
        // Test that clear can be called without issues
        HTTPAssertion.clearRecordedRequests()
    }
    
    func testRecordedHTTPRequestCodable() throws {
        // Test that RecordedHTTPRequest can be encoded and decoded
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        let recordedRequest = RecordedHTTPRequest(
            id: UUID(),
            timestamp: Date(),
            request: request,
            response: HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ),
            responseData: Data("test".utf8),
            error: nil
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encoded = try encoder.encode(recordedRequest)
        let decoded = try decoder.decode(RecordedHTTPRequest.self, from: encoded)
        
        XCTAssertEqual(decoded.id, recordedRequest.id)
        XCTAssertEqual(decoded.request.url, recordedRequest.request.url)
        XCTAssertEqual(decoded.response?.statusCode, recordedRequest.response?.statusCode)
    }
}