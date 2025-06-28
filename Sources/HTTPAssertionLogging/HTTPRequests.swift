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
    static func store(_ request: HTTPRequest) {
        Task {
            do {
                try await storage.store(request, forKey: request.id)
            } catch {
                print("HTTPAssertion: Failed to save request to disk: \(error)")
            }
        }
    }
    
    /// Updates a request with response information using UUID
    static func updateResponse(requestID: String, response: Foundation.HTTPURLResponse, data: Data?, error: Error?) {
        Task {
            do {
                guard let request = try await storage.retrieve(HTTPRequest.self, forKey: requestID) else { return }
                
                // Update the request with response
                var updatedRequest = request
                updatedRequest.response = HTTPRequests.HTTPURLResponse(response)
                updatedRequest.responseData = data
                updatedRequest.error = error.map(CodableError.init)
                
                try await storage.store(updatedRequest, forKey: requestID)
            } catch {
                print("HTTPAssertion: Failed to update response: \(error)")
            }
        }
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
            self.httpBody = request.httpBody ?? request.httpBodyStream?.readData()
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

// MARK: - Helper Extension
private extension InputStream {
    func readData() -> Data? {
        open()
        defer { close() }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        var data = Data()
        while hasBytesAvailable {
            let bytesRead = read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else {
                break
            }
        }
        
        return data.isEmpty ? nil : data
    }
}
