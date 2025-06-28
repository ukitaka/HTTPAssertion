import Foundation

/// Manages storage of HTTP requests to shared directory
public actor HTTPRequests {
    public static let shared = HTTPRequests()
    
    private let storage = FileStorage(subdirectory: "Requests")
    
    private init() {}
    
    /// Initializes the storage directory
    func initialize() {
        Task {
            await storage.initialize()
        }
    }
    
    /// Stores a recorded HTTP request
    func store(_ request: RecordedHTTPRequest) {
        Task {
            do {
                try await storage.store(request, forKey: request.id)
            } catch {
                print("HTTPAssertion: Failed to save request to disk: \(error)")
            }
        }
    }
    
    /// Updates a request with response information using UUID
    func updateResponse(requestID: String, response: HTTPURLResponse, data: Data?, error: Error?) {
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
    public func clear() {
        Task {
            await storage.clear()
        }
    }
    
    /// Gets all stored requests
    public func allRequests() async -> [RecordedHTTPRequest] {
        let loadedRequests = await storage.loadAll(RecordedHTTPRequest.self)
        return loadedRequests.sorted { $0.timestamp < $1.timestamp }
    }
    
}
