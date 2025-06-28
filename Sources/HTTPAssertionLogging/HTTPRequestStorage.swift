import Foundation

/// Manages storage of HTTP requests to shared directory
public actor HTTPRequestStorage {
    public static let shared = HTTPRequestStorage()
    
    private var requests: [String: RecordedHTTPRequest] = [:]
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
        
        guard let directory = storageDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("HTTPAssertion: Failed to clear storage: \(error)")
        }
    }
    
    /// Gets all stored requests
    public func allRequests() -> [RecordedHTTPRequest] {
        Array(requests.values).sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Loads all requests from disk (used for testing)
    public func loadRequestsFromDisk() -> [RecordedHTTPRequest] {
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
        
        let fileURL = directory.appendingPathComponent("\(request.id).json")
        
        do {
            let data = try encoder.encode(request)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
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