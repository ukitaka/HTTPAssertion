import Foundation

/// Handles logging of HTTP requests and responses
final class HTTPRequestLogger {
    nonisolated(unsafe) static let shared = HTTPRequestLogger()
    
    private let queue = DispatchQueue(label: "com.httpassertion.logger", attributes: .concurrent)
    
    private init() {}
    
    /// Logs an HTTP request
    func logRequest(_ request: URLRequest) {
        queue.async(flags: .barrier) {
            let recordedRequest = RecordedHTTPRequest(
                id: UUID(),
                timestamp: Date(),
                request: request,
                response: nil,
                responseData: nil,
                error: nil
            )
            
            HTTPRequestStorage.shared.store(recordedRequest)
        }
    }
    
    /// Logs an HTTP response
    func logResponse(for request: URLRequest, response: HTTPURLResponse, data: Data?, error: Error?) {
        queue.async(flags: .barrier) {
            // Find the matching request and update it with response
            HTTPRequestStorage.shared.updateResponse(
                for: request,
                response: response,
                data: data,
                error: error
            )
        }
    }
}