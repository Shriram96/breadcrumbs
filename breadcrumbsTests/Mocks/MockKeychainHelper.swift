//
//  MockKeychainHelper.swift
//  breadcrumbsTests
//
//  Mock implementation of KeychainHelper for testing
//

@testable import breadcrumbs
import Foundation

/// Mock implementation of KeychainHelper for unit testing
final class MockKeychainHelper: KeychainProtocol {
    // MARK: - Mock Configuration

    var mockStorage: [String: String] = [:]
    var shouldThrowError: Bool = false
    var mockError: Error = NSError(
        domain: "MockKeychainError",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Mock keychain error"]
    )

    // MARK: - Call Tracking

    var saveCallCount: Int = 0
    var getCallCount: Int = 0
    var deleteCallCount: Int = 0
    var updateCallCount: Int = 0
    var existsCallCount: Int = 0

    var lastSaveKey: String?
    var lastSaveValue: String?
    var lastGetKey: String?
    var lastDeleteKey: String?
    var lastUpdateKey: String?
    var lastUpdateValue: String?
    var lastExistsKey: String?

    // MARK: - KeychainHelper Interface

    func save(_ value: String, forKey key: String) -> Bool {
        saveCallCount += 1
        lastSaveKey = key
        lastSaveValue = value

        if shouldThrowError {
            return false
        }

        mockStorage[key] = value
        return true
    }

    func get(forKey key: String) -> String? {
        getCallCount += 1
        lastGetKey = key

        if shouldThrowError {
            return nil
        }

        return mockStorage[key]
    }

    func delete(forKey key: String) -> Bool {
        deleteCallCount += 1
        lastDeleteKey = key

        if shouldThrowError {
            return false
        }

        mockStorage.removeValue(forKey: key)
        return true
    }

    func exists(forKey key: String) -> Bool {
        existsCallCount += 1
        lastExistsKey = key

        return mockStorage[key] != nil
    }

    func update(_ value: String, forKey key: String) -> Bool {
        updateCallCount += 1
        lastUpdateKey = key
        lastUpdateValue = value

        if shouldThrowError {
            return false
        }

        mockStorage[key] = value
        return true
    }

    // MARK: - Test Helpers

    func reset() {
        mockStorage.removeAll()
        shouldThrowError = false
        mockError = NSError(
            domain: "MockKeychainError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Mock keychain error"]
        )

        saveCallCount = 0
        getCallCount = 0
        deleteCallCount = 0
        updateCallCount = 0
        existsCallCount = 0

        lastSaveKey = nil
        lastSaveValue = nil
        lastGetKey = nil
        lastDeleteKey = nil
        lastUpdateKey = nil
        lastUpdateValue = nil
        lastExistsKey = nil
    }

    func configureError(_ error: Error) {
        shouldThrowError = true
        mockError = error
    }

    func setStoredValue(_ value: String, forKey key: String) {
        mockStorage[key] = value
    }

    func removeStoredValue(forKey key: String) {
        mockStorage.removeValue(forKey: key)
    }
}
