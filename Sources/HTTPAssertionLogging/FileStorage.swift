import Foundation

/// Generic file-based storage for Codable data
public actor FileStorage {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let subdirectory: String
    
    
    private var storageDirectory: URL? {
        #if targetEnvironment(simulator)
        // Use SIMULATOR_SHARED_RESOURCES_DIRECTORY for simulator
        if let sharedDir = ProcessInfo.processInfo.environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] {
            let url = URL(fileURLWithPath: sharedDir)
                .appendingPathComponent("Library")
                .appendingPathComponent("Caches")
                .appendingPathComponent("HTTPAssertion")
                .appendingPathComponent(subdirectory)
            return url
        }
        #endif
        
        // Fallback to app's caches directory
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("HTTPAssertion")
            .appendingPathComponent(subdirectory)
    }
    
    internal init(subdirectory: String) {
        self.subdirectory = subdirectory
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Initializes the storage directory
    public func initialize() {
        guard let directory = storageDirectory else { return }
        
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            print("HTTPAssertion: Failed to create storage directory (\(subdirectory)): \(error)")
        }
    }
    
    /// Stores a Codable object with a given key
    public func store<T: Codable>(_ object: T, forKey key: String) throws {
        guard let directory = storageDirectory else {
            throw FileStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        do {
            let data = try encoder.encode(object)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        } catch {
            throw FileStorageError.encodingFailed(error)
        }
    }
    
    /// Retrieves a Codable object for a given key
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let directory = storageDirectory else {
            throw FileStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(type, from: data)
        } catch {
            throw FileStorageError.decodingFailed(error)
        }
    }
    
    /// Lists all stored keys
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
    
    /// Removes a stored object for a given key
    public func remove(forKey key: String) throws {
        guard let directory = storageDirectory else {
            throw FileStorageError.noStorageDirectory
        }
        
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Clears all stored objects
    public func clear() {
        guard let directory = storageDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("HTTPAssertion: Failed to clear storage (\(subdirectory)): \(error)")
        }
    }
    
    /// Loads all objects from disk
    public func loadAll<T: Codable>(_ type: T.Type) -> [T] {
        guard let directory = storageDirectory else { return [] }
        
        var objects: [T] = []
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: file)
                    let object = try decoder.decode(type, from: data)
                    objects.append(object)
                } catch {
                    // Skip corrupted files
                    continue
                }
            }
        } catch {
            return []
        }
        
        return objects
    }
}

/// Errors that can occur during file storage operations
public enum FileStorageError: Error, LocalizedError {
    case noStorageDirectory
    case encodingFailed(Error)
    case decodingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noStorageDirectory:
            return "No storage directory available"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        }
    }
}