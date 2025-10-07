//
//  ItemTests.swift
//  breadcrumbsTests
//
//  Unit tests for Item SwiftData model
//

@testable import breadcrumbs
import SwiftData
import XCTest

final class ItemTests: XCTestCase {
    var modelContainer: ModelContainer!

    override func setUpWithError() throws {
        // Create in-memory model container for testing
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    override func tearDownWithError() throws {
        modelContainer = nil
    }

    // MARK: - Item Initialization Tests

    func testItemInitialization() {
        // Given
        let timestamp = Date()

        // When
        let item = Item(timestamp: timestamp)

        // Then
        XCTAssertEqual(item.timestamp, timestamp)
    }

    func testItemDefaultInitialization() {
        // When
        let item = Item(timestamp: Date())

        // Then
        XCTAssertNotNil(item.timestamp)
        XCTAssertTrue(item.timestamp <= Date())
    }

    // MARK: - SwiftData Persistence Tests

    @MainActor func testItemPersistence() throws {
        // Given
        let context = modelContainer.mainContext
        let timestamp = Date()
        let item = Item(timestamp: timestamp)

        // When
        context.insert(item)
        try context.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Item>()
        let fetchedItems = try context.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedItems.count, 1)
        XCTAssertEqual(fetchedItems.first?.timestamp, timestamp)
    }

    @MainActor func testMultipleItemsPersistence() throws {
        // Given
        let context = modelContainer.mainContext
        let timestamps = [Date(), Date().addingTimeInterval(100), Date().addingTimeInterval(200)]
        let items = timestamps.map { Item(timestamp: $0) }

        // When
        for item in items {
            context.insert(item)
        }
        try context.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Item>()
        let fetchedItems = try context.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedItems.count, 3)

        // Verify all timestamps are present
        let fetchedTimestamps = fetchedItems.map { $0.timestamp }
        for timestamp in timestamps {
            XCTAssertTrue(fetchedTimestamps.contains(timestamp))
        }
    }

    @MainActor func testItemUpdate() throws {
        // Given
        let context = modelContainer.mainContext
        let originalTimestamp = Date()
        let item = Item(timestamp: originalTimestamp)
        context.insert(item)
        try context.save()

        // When
        let newTimestamp = Date().addingTimeInterval(1000)
        item.timestamp = newTimestamp
        try context.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Item>()
        let fetchedItems = try context.fetch(fetchDescriptor)

        XCTAssertEqual(fetchedItems.count, 1)
        XCTAssertEqual(fetchedItems.first?.timestamp, newTimestamp)
    }

    @MainActor func testItemDeletion() throws {
        // Given
        let context = modelContainer.mainContext
        let item = Item(timestamp: Date())
        context.insert(item)
        try context.save()

        // Verify item exists
        let fetchDescriptor = FetchDescriptor<Item>()
        var fetchedItems = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedItems.count, 1)

        // When
        context.delete(item)
        try context.save()

        // Then
        fetchedItems = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedItems.count, 0)
    }

    // MARK: - Item Properties Tests

    func testItemTimestampProperty() {
        // Given
        let item = Item(timestamp: Date())
        let newTimestamp = Date().addingTimeInterval(500)

        // When
        item.timestamp = newTimestamp

        // Then
        XCTAssertEqual(item.timestamp, newTimestamp)
    }

    func testItemTimestampComparison() {
        // Given
        let earlierDate = Date()
        let laterDate = earlierDate.addingTimeInterval(1000)

        let earlierItem = Item(timestamp: earlierDate)
        let laterItem = Item(timestamp: laterDate)

        // Then
        XCTAssertTrue(earlierItem.timestamp < laterItem.timestamp)
        XCTAssertTrue(laterItem.timestamp > earlierItem.timestamp)
    }

    // MARK: - Edge Cases Tests

    func testItemWithMinimalTimestamp() {
        // Given
        let minimalDate = Date(timeIntervalSince1970: 0)

        // When
        let item = Item(timestamp: minimalDate)

        // Then
        XCTAssertEqual(item.timestamp, minimalDate)
    }

    func testItemWithFutureTimestamp() {
        // Given
        let futureDate = Date().addingTimeInterval(86400 * 365) // 1 year in the future

        // When
        let item = Item(timestamp: futureDate)

        // Then
        XCTAssertEqual(item.timestamp, futureDate)
    }

    // MARK: - Performance Tests

    func testItemCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = Item(timestamp: Date())
            }
        }
    }

    @MainActor func testItemPersistencePerformance() {
        let context = modelContainer.mainContext

        measure {
            for i in 0..<100 {
                let item = Item(timestamp: Date().addingTimeInterval(TimeInterval(i)))
                context.insert(item)
            }

            do {
                try context.save()
            } catch {
                XCTFail("Failed to save items: \(error)")
            }
        }
    }
}
