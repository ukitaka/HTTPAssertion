import Foundation

/// Handles logging of HTTP requests and responses
final class HTTPRequestLogger {
    nonisolated(unsafe) static let shared = HTTPRequestLogger()
    
    private init() {}
    
    /// Logs an HTTP request
    func logRequest(_ request: URLRequest) {
        Task {
            let recordedRequest = RecordedHTTPRequest(
                id: UUID(),
                timestamp: Date(),
                request: request,
                response: nil,
                responseData: nil,
                error: nil
            )
            
            await HTTPRequestStorage.shared.store(recordedRequest)
        }
    }
    
    /// Logs an HTTP response
    func logResponse(for request: URLRequest, response: HTTPURLResponse, data: Data?, error: Error?) {
        Task {
            // Find the matching request and update it with response
            await HTTPRequestStorage.shared.updateResponse(
                for: request,
                response: response,
                data: data,
                error: error
            )
        }
    }
}