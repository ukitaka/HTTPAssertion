import Foundation

/// Manages storage of HTTP requests to shared directory
public enum HTTPRequests {
    private static let storage = FileStorage(subdirectory: "Requests")
    
    /// Initializes the storage directory
    static func initialize() {
        Task {
            await storage.initialize()
        }
    }
    
    /// Stores a recorded HTTP request
    static func store(_ request: RecordedHTTPRequest) {
        Task {
            do {
                try await storage.store(request, forKey: request.id)
            } catch {
                print("HTTPAssertion: Failed to save request to disk: \(error)")
            }
        }
    }
    
    /// Updates a request with response information using UUID
    static func updateResponse(requestID: String, response: HTTPURLResponse, data: Data?, error: Error?) {
        Task {
            do {
                guard let request = try await storage.retrieve(RecordedHTTPRequest.self, forKey: requestID) else { return }
                
                // Update the request with response
                var updatedRequest = request
                updatedRequest.response = CodableHTTPURLResponse(response)
                updatedRequest.responseData = data
                updatedRequest.error = error.map(CodableError.init)
                
                try await storage.store(updatedRequest, forKey: requestID)
            } catch {
                print("HTTPAssertion: Failed to update response: \(error)")
            }
        }
    }
    
    /// Clears all stored requests
    public static func clear() {
        Task {
            await storage.clear()
        }
    }
    
    /// Gets all stored requests
    public static func allRequests() async -> [RecordedHTTPRequest] {
        let loadedRequests = await storage.loadAll(RecordedHTTPRequest.self)
        return loadedRequests.sorted { $0.timestamp < $1.timestamp }
    }
    
}
