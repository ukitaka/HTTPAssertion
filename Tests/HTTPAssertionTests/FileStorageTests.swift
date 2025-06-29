import XCTest
@testable import HTTPAssertionLogging

final class FileStorageTests: XCTestCase {
    
    private var storage: FileStorage!
    private let testSubdirectory = "FileStorageTests"
    
    override func setUp() async throws {
        try await super.setUp()
        storage = FileStorage(subdirectory: testSubdirectory)
        // Initialize storage to ensure directory is created
        await storage.initialize()
        await storage.clear()
    }
    
    override func tearDown() async throws {
        await storage.clear()
        try await super.tearDown()
    }
    
    func testFileCreationAndModificationDates() async throws {
        struct TestData: Codable, Equatable {
            let value: String
        }
        
        let key = "test-file"
        let initialData = TestData(value: "initial")
        let updatedData = TestData(value: "updated")
        
        // Store initial data
        try await storage.store(initialData, forKey: key)
        
        // Wait to ensure time difference
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Get the storage directory from FileStorage
        let storageDir = await storage.storageDirectory
        XCTAssertNotNil(storageDir, "Storage directory should not be nil")
        let fileURL = storageDir!.appendingPathComponent("\(key).json")
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "File should exist")
        
        // Get initial attributes
        let initialAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let creationDate = initialAttributes[.creationDate] as! Date
        let modificationDate1 = initialAttributes[.modificationDate] as! Date
        
        // Initially, creation and modification dates should be very close
        XCTAssertEqual(creationDate.timeIntervalSince1970, modificationDate1.timeIntervalSince1970, accuracy: 1.0)
        
        // Wait before updating
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Update the file
        try await storage.store(updatedData, forKey: key)
        
        // Get updated attributes
        let updatedAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let creationDateAfterUpdate = updatedAttributes[.creationDate] as! Date
        let modificationDate2 = updatedAttributes[.modificationDate] as! Date
        
        // Creation date should remain the same (allow small difference due to filesystem precision)
        XCTAssertEqual(creationDate.timeIntervalSince1970, creationDateAfterUpdate.timeIntervalSince1970, accuracy: 1.0)
        
        // Modification date should be different (later)
        XCTAssertGreaterThan(modificationDate2, modificationDate1)
        
        // Verify data was actually updated
        let retrieved = try await storage.retrieve(TestData.self, forKey: key)
        XCTAssertEqual(retrieved?.value, "updated")
    }
    
    func testLoadSortedByCreationDate() async throws {
        struct TestData: Codable, Equatable {
            let id: String
            let value: String
        }
        
        // Create multiple files with delays
        let items = [
            TestData(id: "1", value: "first"),
            TestData(id: "2", value: "second"),
            TestData(id: "3", value: "third")
        ]
        
        for item in items {
            try await storage.store(item, forKey: item.id)
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds between creates
        }
        
        // Load sorted by creation date (ascending)
        let sortedAscending = await storage.loadSorted(TestData.self, sortBy: .creationDate, ascending: true)
        XCTAssertEqual(sortedAscending.map { $0.id }, ["1", "2", "3"])
        
        // Load sorted by creation date (descending)
        let sortedDescending = await storage.loadSorted(TestData.self, sortBy: .creationDate, ascending: false)
        XCTAssertEqual(sortedDescending.map { $0.id }, ["3", "2", "1"])
    }
    
    func testLoadSortedByModificationDate() async throws {
        struct TestData: Codable, Equatable {
            let id: String
            var value: String
        }
        
        // Create files
        let items = [
            TestData(id: "1", value: "first"),
            TestData(id: "2", value: "second"),
            TestData(id: "3", value: "third")
        ]
        
        for item in items {
            try await storage.store(item, forKey: item.id)
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        // Update files in different order
        try await Task.sleep(nanoseconds: 100_000_000)
        try await storage.store(TestData(id: "2", value: "second-updated"), forKey: "2")
        
        try await Task.sleep(nanoseconds: 100_000_000)
        try await storage.store(TestData(id: "1", value: "first-updated"), forKey: "1")
        
        // Load sorted by modification date (ascending)
        let sortedByMod = await storage.loadSorted(TestData.self, sortBy: .modificationDate, ascending: true)
        
        // "3" was not updated, so it should be first (oldest modification)
        // Then "2" (updated first), then "1" (updated last)
        XCTAssertEqual(sortedByMod[0].id, "3")
        XCTAssertEqual(sortedByMod[1].id, "2")
        XCTAssertEqual(sortedByMod[2].id, "1")
        
        // Verify values were updated
        XCTAssertEqual(sortedByMod.first { $0.id == "1" }?.value, "first-updated")
        XCTAssertEqual(sortedByMod.first { $0.id == "2" }?.value, "second-updated")
        XCTAssertEqual(sortedByMod.first { $0.id == "3" }?.value, "third")
    }
    
    func testLoadSortedWithLimit() async throws {
        struct TestData: Codable, Equatable {
            let id: String
        }
        
        // Create 5 files
        for i in 1...5 {
            try await storage.store(TestData(id: "\(i)"), forKey: "\(i)")
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        // Load only 3 most recent by creation date
        let limited = await storage.loadSorted(TestData.self, limit: 3, sortBy: .creationDate, ascending: false)
        XCTAssertEqual(limited.count, 3)
        XCTAssertEqual(limited.map { $0.id }, ["5", "4", "3"])
    }
    
    func testLoadSortedWithDateFilter() async throws {
        struct TestData: Codable, Equatable {
            let id: String
            let value: String
        }
        
        // Create first 2 files
        for i in 1...2 {
            try await storage.store(TestData(id: "\(i)", value: "value\(i)"), forKey: "\(i)")
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        // Get time after creating first 2 files
        let midTime = Date()
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Create remaining files
        for i in 3...5 {
            try await storage.store(TestData(id: "\(i)", value: "value\(i)"), forKey: "\(i)")
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        // Load files created since midTime (should get files 3, 4, 5)
        let filteredByCreation = await storage.loadSorted(TestData.self, sortBy: .creationDate, ascending: true, since: midTime)
        XCTAssertEqual(filteredByCreation.count, 3)
        XCTAssertEqual(filteredByCreation.map { $0.id }, ["3", "4", "5"])
        
        // Test with modification date filter
        let futureTime = Date().addingTimeInterval(1.0)
        let filteredByModification = await storage.loadSorted(TestData.self, sortBy: .modificationDate, ascending: true, since: futureTime)
        XCTAssertEqual(filteredByModification.count, 0) // No files modified after future time
        
        // Test with limit + date filter
        let limitedAndFiltered = await storage.loadSorted(TestData.self, limit: 2, sortBy: .creationDate, ascending: true, since: midTime)
        XCTAssertEqual(limitedAndFiltered.count, 2)
        XCTAssertEqual(limitedAndFiltered.map { $0.id }, ["3", "4"])
    }
}