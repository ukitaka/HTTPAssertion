import Foundation

/// Represents a recorded HTTP request and its response
public struct RecordedHTTPRequest: Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let request: CodableURLRequest
    public var response: CodableHTTPURLResponse?
    public var responseData: Data?
    public var error: CodableError?
    
    init(id: String, timestamp: Date, request: URLRequest, response: HTTPURLResponse?, responseData: Data?, error: Error?) {
        self.id = id
        self.timestamp = timestamp
        self.request = CodableURLRequest(request)
        self.response = response.map(CodableHTTPURLResponse.init)
        self.responseData = responseData
        self.error = error.map(CodableError.init)
    }
}

/// Codable wrapper for URLRequest
public struct CodableURLRequest: Codable, Sendable {
    public let url: URL?
    public let httpMethod: String?
    public let allHTTPHeaderFields: [String: String]?
    public let httpBody: Data?
    public let timeoutInterval: TimeInterval
    
    init(_ request: URLRequest) {
        self.url = request.url
        self.httpMethod = request.httpMethod
        self.allHTTPHeaderFields = request.allHTTPHeaderFields
        self.httpBody = request.httpBody ?? request.httpBodyStream?.readData()
        self.timeoutInterval = request.timeoutInterval
    }
}

/// Codable wrapper for HTTPURLResponse
public struct CodableHTTPURLResponse: Codable, Sendable {
    public let url: URL?
    public let statusCode: Int
    public let allHeaderFields: [String: String]
    
    init(_ response: HTTPURLResponse) {
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
