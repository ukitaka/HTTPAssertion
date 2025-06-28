import Foundation

/// Generic context storage for sharing arbitrary Codable data between app and UI tests
public actor ContextStorage {
    public static let shared = ContextStorage()
    
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
                .appendingPathComponent("Context")
            return url
        }
        #endif
        
        // Fallback to app's caches directory
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("HTTPAssertion")
            .appendingPathComponent("Context")
    }
    
    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Initializes the context storage directory
    public func initialize() {
        guard let directory = storageDirectory else { return }
        
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            print("HTTPAssertion: Failed to create context storage directory: \(error)")
        }
    }
    
    /// Stores a context object with a given key
    public func store<T: Codable>(_ context: T, forKey key: String) throws {
        guard let directory = storageDirectory else {
            throw ContextStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        do {
            let data = try encoder.encode(context)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        } catch {
            throw ContextStorageError.encodingFailed(error)
        }
    }
    
    /// Stores a dictionary context with a given key
    public func store(_ dictionary: [String: String], forKey key: String) throws {
        guard let directory = storageDirectory else {
            throw ContextStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        do {
            let data = try encoder.encode(dictionary)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        } catch {
            throw ContextStorageError.encodingFailed(error)
        }
    }
    
    /// Retrieves a context object for a given key
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let directory = storageDirectory else {
            throw ContextStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(type, from: data)
        } catch {
            throw ContextStorageError.decodingFailed(error)
        }
    }
    
    /// Retrieves a dictionary context for a given key
    public func retrieve(forKey key: String) throws -> [String: String]? {
        guard let directory = storageDirectory else {
            throw ContextStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([String: String].self, from: data)
        } catch {
            throw ContextStorageError.decodingFailed(error)
        }
    }
    
    /// Lists all stored context keys
    public func listKeys() -> [String] {
        guard let directory = storageDirectory else { return [] }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            return files.compactMap { file in
                guard file.pathExtension == "json" else { return nil }
                return file.deletingPathExtension().lastPathComponent
            }
        } catch {
            return []
        }
    }
    
    /// Removes a stored context for a given key
    public func remove(forKey key: String) throws {
        guard let directory = storageDirectory else {
            throw ContextStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Clears all stored contexts
    public func clear() {
        guard let directory = storageDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("HTTPAssertion: Failed to clear context storage: \(error)")
        }
    }
}

/// Errors that can occur during context storage operations
public enum ContextStorageError: Error, LocalizedError {
    case noStorageDirectory
    case encodingFailed(Error)
    case decodingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noStorageDirectory:
            return "No storage directory available"
        case .encodingFailed(let error):
            return "Failed to encode context: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode context: \(error.localizedDescription)"
        }
    }
}