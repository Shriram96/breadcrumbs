//
//  KeychainHelper.swift
//  breadcrumbs
//
//  Secure storage for sensitive data using macOS Keychain
//

import Foundation
import os.log
import Security

// MARK: - KeychainHelper

/// Helper class for storing and retrieving sensitive data from macOS Keychain
@MainActor
final class KeychainHelper: KeychainProtocol {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared: KeychainHelper = .init()

    // MARK: - Public Methods

    /// Save a string value to Keychain
    /// - Parameters:
    ///   - value: The string to save
    ///   - key: The key to identify the value
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        #if UNIT_TESTS
            // Skip actual keychain operations during unit tests to avoid system prompts
            return true
        #else
            guard let data = value.data(using: .utf8) else {
                return false
            }

            // Delete any existing item
            delete(forKey: key)

            /// Create query dictionary
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            ]

            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        #endif
    }

    /// Retrieve a string value from Keychain
    /// - Parameter key: The key to identify the value
    /// - Returns: The stored string, or nil if not found
    func get(forKey key: String) -> String? {
        #if UNIT_TESTS
            // Skip actual keychain operations during unit tests to avoid system prompts
            // Return a mock value for testing
            return "mock_api_key_for_testing"
        #else
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

            guard
                status == errSecSuccess,
                let data = dataTypeRef as? Data,
                let value = String(data: data, encoding: .utf8)
            else {
                os_log(
                    "Failed to retrieve keychain item for key: %{public}@, status: %d",
                    log: .default,
                    type: .error,
                    key,
                    status
                )
                return nil
            }

            return value
        #endif
    }

    /// Delete a value from Keychain
    /// - Parameter key: The key to identify the value
    /// - Returns: True if successful or item doesn't exist, false if error
    @discardableResult
    func delete(forKey key: String) -> Bool {
        #if UNIT_TESTS
            // Skip actual keychain operations during unit tests to avoid system prompts
            return true
        #else
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]

            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        #endif
    }

    /// Check if a value exists in Keychain
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists, false otherwise
    func exists(forKey key: String) -> Bool {
        return get(forKey: key) != nil
    }

    /// Update an existing value in Keychain
    /// - Parameters:
    ///   - value: The new value
    ///   - key: The key to update
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func update(_ value: String, forKey key: String) -> Bool {
        #if UNIT_TESTS
            // Skip actual keychain operations during unit tests to avoid system prompts
            return true
        #else
            guard let data = value.data(using: .utf8) else {
                return false
            }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data,
            ]

            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

            if status == errSecItemNotFound {
                // Item doesn't exist, create it
                return save(value, forKey: key)
            }

            return status == errSecSuccess
        #endif
    }

    // MARK: Private

    /// Service identifier for Keychain items
    private let service = "com.breadcrumbs.systemdiagnostics"
}

// MARK: - Convenience Keys

extension KeychainHelper {
    /// Key for OpenAI API key
    static let openAIAPIKey = "openai_api_key"
}
