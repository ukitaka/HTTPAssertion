import Foundation

/// Manages storage of HTTP requests to shared directory
public final class HTTPRequestStorage: @unchecked Sendable {
    public static let shared = HTTPRequestStorage()
    
    private let queue = DispatchQueue(label: "com.httpassertion.storage", attributes: .concurrent)
    private var requests: [UUID: RecordedHTTPRequest] = [:]
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var storageDirectory: URL? {
        #if targetEnvironment(simulator)
        // Use SIMULATOR_SHARED_RESOURCES_DIRECTORY for simulator
        if let sharedDir = ProcessInfo.processInfo.environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] {
            let url = URL(fileURLWithPath: sharedDir)
                .appendingPathComponent("Library")
                .appendingPathComponent("Caches")
                .appendingPathComponent("HTTPAssertion")
            return url
        }
        #endif
        
        // Fallback to app's caches directory
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("HTTPAssertion")
    }
    
    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Initializes the storage directory
    func initialize() {
        guard let directory = storageDirectory else { return }
        
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            // Load existing requests
            loadStoredRequests()
        } catch {
            print("HTTPAssertion: Failed to create storage directory: \(error)")
        }
    }
    
    /// Stores a recorded HTTP request
    func store(_ request: RecordedHTTPRequest) {
        queue.async(flags: .barrier) {
            self.requests[request.id] = request
            self.saveRequestToDisk(request)
        }
    }
    
    /// Updates a request with response information
    func updateResponse(for urlRequest: URLRequest, response: HTTPURLResponse, data: Data?, error: Error?) {
        queue.async(flags: .barrier) {
            // Find the most recent matching request
            let matchingRequest = self.requests.values
                .filter { $0.request.url == urlRequest.url && $0.response == nil }
                .sorted { $0.timestamp > $1.timestamp }
                .first
            
            guard let request = matchingRequest else { return }
            
            // Update the request with response
            var updatedRequest = request
            updatedRequest.response = CodableHTTPURLResponse(response)
            updatedRequest.responseData = data
            updatedRequest.error = error.map(CodableError.init)
            
            self.requests[request.id] = updatedRequest
            self.saveRequestToDisk(updatedRequest)
        }
    }
    
    /// Clears all stored requests
    public func clear() {
        queue.async(flags: .barrier) {
            self.requests.removeAll()
            
            guard let directory = self.storageDirectory else { return }
            
            do {
                let files = try self.fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                for file in files where file.pathExtension == "json" {
                    try self.fileManager.removeItem(at: file)
                }
            } catch {
                print("HTTPAssertion: Failed to clear storage: \(error)")
            }
        }
    }
    
    /// Gets all stored requests
    public func getAllRequests() -> [RecordedHTTPRequest] {
        queue.sync {
            Array(requests.values).sorted { $0.timestamp < $1.timestamp }
        }
    }
    
    /// Loads all requests from disk (used for testing)
    public func loadAllRequestsFromDisk() -> [RecordedHTTPRequest] {
        var loadedRequests: [RecordedHTTPRequest] = []
        
        guard let directory = storageDirectory else { return [] }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: file)
                    let request = try decoder.decode(RecordedHTTPRequest.self, from: data)
                    loadedRequests.append(request)
                } catch {
                    // Skip corrupted files
                    continue
                }
            }
        } catch {
            // Directory might not exist yet
            return []
        }
        
        return loadedRequests.sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Private Methods
    
    private func saveRequestToDisk(_ request: RecordedHTTPRequest) {
        guard let directory = storageDirectory else { return }
        
        let fileURL = directory.appendingPathComponent("\(request.id.uuidString).json")
        
        do {
            let data = try encoder.encode(request)
            try data.write(to: fileURL)
        } catch {
            print("HTTPAssertion: Failed to save request to disk: \(error)")
        }
    }
    
    private func loadStoredRequests() {
        guard let directory = storageDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: file)
                    let request = try decoder.decode(RecordedHTTPRequest.self, from: data)
                    requests[request.id] = request
                } catch {
                    // Remove corrupted file
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("HTTPAssertion: Failed to load stored requests: \(error)")
        }
    }
}
