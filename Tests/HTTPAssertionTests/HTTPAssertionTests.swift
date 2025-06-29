import XCTest
@testable import HTTPAssertionLogging

final class HTTPAssertionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        HTTPAssertionLogging.stop()
        super.tearDown()
    }
    
    func testStartAndStop() {
        // Test that start and stop can be called without issues
        HTTPAssertionLogging.start()
        HTTPAssertionLogging.stop()
        
        // Can be called multiple times safely
        HTTPAssertionLogging.start()
        HTTPAssertionLogging.start()
        HTTPAssertionLogging.stop()
        HTTPAssertionLogging.stop()
    }
    
    
    func testRecordedHTTPRequestCodable() throws {
        // Test that RecordedHTTPRequest can be encoded and decoded
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        let recordedRequest = HTTPRequests.HTTPRequest(
            id: UUID().uuidString,
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
        let decoded = try decoder.decode(HTTPRequests.HTTPRequest.self, from: encoded)
        
        XCTAssertEqual(decoded.id, recordedRequest.id)
        XCTAssertEqual(decoded.request.url, recordedRequest.request.url)
        XCTAssertEqual(decoded.response?.statusCode, recordedRequest.response?.statusCode)
    }
    
    func testRecentRequestsWithDateFilter() async throws {
        // Clear any existing requests
        await HTTPRequests.clear()
        
        // Create first request
        let request1 = HTTPRequests.HTTPRequest(
            id: "test-1",
            timestamp: Date(),
            request: URLRequest(url: URL(string: "https://example.com/1")!),
            response: nil,
            responseData: nil,
            error: nil
        )
        try await HTTPRequests.store(request1)
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Get time after first request
        let midTime = Date()
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Create remaining requests
        for i in 2...3 {
            let request = HTTPRequests.HTTPRequest(
                id: "test-\(i)",
                timestamp: Date(),
                request: URLRequest(url: URL(string: "https://example.com/\(i)")!),
                response: nil,
                responseData: nil,
                error: nil
            )
            try await HTTPRequests.store(request)
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        // Test filtering by creation time
        let recentRequests = await HTTPRequests.recentRequests(since: midTime)
        
        // Should get requests 2 and 3 (created after midTime)
        XCTAssertEqual(recentRequests.count, 2)
        XCTAssertTrue(recentRequests.contains { $0.id == "test-2" })
        XCTAssertTrue(recentRequests.contains { $0.id == "test-3" })
        XCTAssertFalse(recentRequests.contains { $0.id == "test-1" })
        
        // Test with date filter only
        let filteredRecent = await HTTPRequests.recentRequests(since: midTime)
        XCTAssertEqual(filteredRecent.count, 2)
        XCTAssertEqual(filteredRecent.first?.id, "test-3") // Most recent first
        
        // Test recentRequests with request time sorting and date filter
        let byRequestTime = await HTTPRequests.recentRequests(sortBy: .requestTime, ascending: true, since: midTime)
        XCTAssertEqual(byRequestTime.count, 2)
        XCTAssertEqual(byRequestTime.map { $0.id }, ["test-2", "test-3"]) // Ascending order
    }
}