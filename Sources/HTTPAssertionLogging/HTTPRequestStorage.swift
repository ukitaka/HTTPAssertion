import Foundation

// MARK: - FileStorage Extension for HTTP Requests
extension FileStorage {
    /// Shared storage for HTTP requests
    public static let httpRequests = FileStorage(subdirectory: "Requests")
}

/// Manages storage of HTTP requests to shared directory
public actor HTTPRequestStorage {
    public static let shared = HTTPRequestStorage()
    
    private var requests: [String: RecordedHTTPRequest] = [:]
    
    private init() {}
    
    /// Initializes the storage directory
    func initialize() {
        Task {
            await FileStorage.httpRequests.initialize()
            // Load existing requests
            loadStoredRequests()
        }
    }
    
    /// Stores a recorded HTTP request
    func store(_ request: RecordedHTTPRequest) {
        requests[request.id] = request
        saveRequestToDisk(request)
    }
    
    /// Updates a request with response information using UUID
    func updateResponse(requestID: String, response: HTTPURLResponse, data: Data?, error: Error?) {
        guard let request = requests[requestID] else { return }
        
        // Update the request with response
        var updatedRequest = request
        updatedRequest.response = CodableHTTPURLResponse(response)
        updatedRequest.responseData = data
        updatedRequest.error = error.map(CodableError.init)
        
        requests[requestID] = updatedRequest
        saveRequestToDisk(updatedRequest)
    }
    
    /// Clears all stored requests
    public func clear() {
        requests.removeAll()
        
        Task {
            await FileStorage.httpRequests.clear()
        }
    }
    
    /// Gets all stored requests
    public func allRequests() -> [RecordedHTTPRequest] {
        Array(requests.values).sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Loads all requests from disk (used for testing)
    public func loadRequestsFromDisk() async -> [RecordedHTTPRequest] {
        let loadedRequests = await FileStorage.httpRequests.loadAll(RecordedHTTPRequest.self)
        return loadedRequests.sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Private Methods
    
    private func saveRequestToDisk(_ request: RecordedHTTPRequest) {
        Task {
            do {
                try await FileStorage.httpRequests.store(request, forKey: request.id)
            } catch {
                print("HTTPAssertion: Failed to save request to disk: \(error)")
            }
        }
    }
    
    private func loadStoredRequests() {
        Task {
            let loadedRequests = await FileStorage.httpRequests.loadAll(RecordedHTTPRequest.self)
            for request in loadedRequests {
                self.requests[request.id] = request
            }
        }
    }
}