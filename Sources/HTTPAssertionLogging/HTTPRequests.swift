import Foundation

/// Manages storage of HTTP requests to shared directory
public enum HTTPRequests {
    private static let storage = FileStorage(subdirectory: "Requests")
    
    /// Sort key for retrieving requests
    public enum SortBy {
        case requestTime    // Sort by file creation date (when request was made)
        case responseTime   // Sort by file modification date (when response was received)
    }
    
    /// Initializes the storage directory
    static func initialize() async {
        await storage.initialize()
    }
    
    /// Stores a recorded HTTP request
    static func store(_ request: HTTPRequest) async throws {
        try await storage.store(request, forKey: request.id)
    }
    
    /// Updates a request with response information using UUID
    static func updateResponse(requestID: String, response: Foundation.HTTPURLResponse, data: Data?, error: Error?) async throws {
        guard let request = try await storage.retrieve(HTTPRequest.self, forKey: requestID) else { return }
        
        // Update the request with response
        var updatedRequest = request
        updatedRequest.response = HTTPRequests.HTTPURLResponse(response)
        updatedRequest.responseData = data
        updatedRequest.error = error.map(CodableError.init)
        
        try await storage.store(updatedRequest, forKey: requestID)
    }
    
    /// Clears all stored requests
    public static func clear() async {
        await storage.clear()
    }
    
    /// Gets all stored requests
    public static func allRequests() async -> [HTTPRequest] {
        let loadedRequests = await storage.loadAll(HTTPRequest.self)
        return loadedRequests.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Gets stored requests with optional sorting, limit and date filtering
    public static func recentRequests(limit: Int? = nil, sortBy: SortBy = .responseTime, ascending: Bool = false, since: Date? = nil) async -> [HTTPRequest] {
        let storageSortKey: FileStorage.SortKey = sortBy == .requestTime ? .creationDate : .modificationDate
        return await storage.loadSorted(HTTPRequest.self, limit: limit, sortBy: storageSortKey, ascending: ascending, since: since)
    }
}

extension HTTPRequests {
    /// Represents a recorded HTTP request and its response
    public struct HTTPRequest: Codable, Sendable {
        public let id: String
        public let timestamp: Date
        public let request: URLRequest
        public var response: HTTPURLResponse?
        public var responseData: Data?
        public var error: CodableError?
        
        init(id: String, timestamp: Date, request: Foundation.URLRequest, response: Foundation.HTTPURLResponse?, responseData: Data?, error: Error?) {
            self.id = id
            self.timestamp = timestamp
            self.request = URLRequest(request)
            self.response = response.map(HTTPURLResponse.init)
            self.responseData = responseData
            self.error = error.map(CodableError.init)
        }
    }
    
    /// Codable wrapper for URLRequest
    public struct URLRequest: Codable, Sendable {
        public let url: URL?
        public let httpMethod: String?
        public let allHTTPHeaderFields: [String: String]?
        public let httpBody: Data?
        public let timeoutInterval: TimeInterval
        
        init(_ request: Foundation.URLRequest) {
            self.url = request.url
            self.httpMethod = request.httpMethod
            self.allHTTPHeaderFields = request.allHTTPHeaderFields
            self.httpBody = request.httpBody
            self.timeoutInterval = request.timeoutInterval
        }
    }
    
    /// Codable wrapper for HTTPURLResponse
    public struct HTTPURLResponse: Codable, Sendable {
        public let url: URL?
        public let statusCode: Int
        public let allHeaderFields: [String: String]
        
        init(_ response: Foundation.HTTPURLResponse) {
            self.url = response.url
            self.statusCode = response.statusCode
            
            // Convert header fields to [String: String]
            var headers: [String: String] = [:]
            for (key, value) in response.allHeaderFields {
                if let keyString = key as? String, let valueString = value as? String {
                    headers[keyString] = valueString
                }
            }
            self.allHeaderFields = headers
        }
    }
}

/// Codable wrapper for Error
public struct CodableError: Codable, Sendable {
    public let domain: String
    public let code: Int
    public let localizedDescription: String
    
    init(_ error: Error) {
        let nsError = error as NSError
        self.domain = nsError.domain
        self.code = nsError.code
        self.localizedDescription = error.localizedDescription
    }
}

