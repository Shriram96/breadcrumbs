//
//  MockKeychainHelper.swift
//  breadcrumbsTests
//
//  Mock implementation of KeychainHelper for testing
//

@testable import breadcrumbs
import Foundation
import LocalAuthentication

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
    var isBiometricAvailable: Bool = true
    var biometricType: String = "Touch ID"
    var shouldAuthenticateSuccessfully: Bool = true
    var authenticationError: Error?

    // MARK: - Call Tracking

    var saveCallCount: Int = 0
    var getCallCount: Int = 0
    var deleteCallCount: Int = 0
    var updateCallCount: Int = 0
    var existsCallCount: Int = 0
    var biometricAuthCallCount: Int = 0

    var lastSaveKey: String?
    var lastSaveValue: String?
    var lastSaveRequireBiometric: Bool?
    var lastGetKey: String?
    var lastDeleteKey: String?
    var lastUpdateKey: String?
    var lastUpdateValue: String?
    var lastUpdateRequireBiometric: Bool?
    var lastExistsKey: String?
    var lastBiometricReason: String?

    // MARK: - KeychainHelper Interface

    func save(_ value: String, forKey key: String, requireBiometric: Bool = false) -> Bool {
        saveCallCount += 1
        lastSaveKey = key
        lastSaveValue = value
        lastSaveRequireBiometric = requireBiometric

        if shouldThrowError {
            return false
        }

        mockStorage[key] = value
        return true
    }

    func get(forKey key: String, prompt: String? = nil) -> String? {
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

    func update(_ value: String, forKey key: String, requireBiometric: Bool = false) -> Bool {
        updateCallCount += 1
        lastUpdateKey = key
        lastUpdateValue = value
        lastUpdateRequireBiometric = requireBiometric

        if shouldThrowError {
            return false
        }

        mockStorage[key] = value
        return true
    }

    func isBiometricAuthenticationAvailable() -> Bool {
        return isBiometricAvailable
    }

    func getBiometricType() -> String {
        return biometricType
    }

    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        biometricAuthCallCount += 1
        lastBiometricReason = reason

        DispatchQueue.main.async {
            if self.shouldAuthenticateSuccessfully {
                completion(true, nil)
            } else {
                completion(false, self.authenticationError)
            }
        }
    }

    // MARK: - Convenience Methods

    func saveWithBiometric(_ value: String, forKey key: String) -> Bool {
        return save(value, forKey: key, requireBiometric: true)
    }

    func getWithBiometric(forKey key: String, reason: String) -> String? {
        return get(forKey: key, prompt: reason)
    }

    func updateWithBiometric(_ value: String, forKey key: String) -> Bool {
        return update(value, forKey: key, requireBiometric: true)
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
        isBiometricAvailable = true
        biometricType = "Touch ID"
        shouldAuthenticateSuccessfully = true
        authenticationError = nil

        saveCallCount = 0
        getCallCount = 0
        deleteCallCount = 0
        updateCallCount = 0
        existsCallCount = 0
        biometricAuthCallCount = 0

        lastSaveKey = nil
        lastSaveValue = nil
        lastSaveRequireBiometric = nil
        lastGetKey = nil
        lastDeleteKey = nil
        lastUpdateKey = nil
        lastUpdateValue = nil
        lastUpdateRequireBiometric = nil
        lastExistsKey = nil
        lastBiometricReason = nil
    }

    func configureError(_ error: Error) {
        shouldThrowError = true
        mockError = error
    }

    func configureBiometricAuth(success: Bool, error: Error? = nil) {
        shouldAuthenticateSuccessfully = success
        authenticationError = error
    }

    func setStoredValue(_ value: String, forKey key: String) {
        mockStorage[key] = value
    }

    func removeStoredValue(forKey key: String) {
        mockStorage.removeValue(forKey: key)
    }
}
