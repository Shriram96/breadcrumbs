//
//  KeychainHelper.swift
//  breadcrumbs
//
//  Secure storage for sensitive data using macOS Keychain with Touch ID/Face ID authentication
//

import Foundation
import LocalAuthentication
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

    /// Save a string value to Keychain with biometric protection
    /// - Parameters:
    ///   - value: The string to save
    ///   - key: The key to identify the value
    ///   - requireBiometric: Whether to require Touch ID/Face ID for access
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func save(_ value: String, forKey key: String, requireBiometric: Bool = false) -> Bool {
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
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            ]

            // Add biometric protection if requested
            if requireBiometric {
                if let accessControl = createBiometricAccessControl() {
                    query[kSecAttrAccessControl as String] = accessControl
                } else {
                    os_log("Failed to create biometric access control", log: .default, type: .error)
                    return false
                }
            }

            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        #endif
    }

    /// Retrieve a string value from Keychain with optional biometric authentication
    /// - Parameters:
    ///   - key: The key to identify the value
    ///   - prompt: Optional prompt message for biometric authentication
    /// - Returns: The stored string, or nil if not found or authentication failed
    func get(forKey key: String, prompt: String? = nil) -> String? {
        #if UNIT_TESTS
            // Skip actual keychain operations during unit tests to avoid system prompts
            // Return a mock value for testing
            return "mock_api_key_for_testing"
        #else
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            // Add biometric authentication context if provided
            if let prompt = prompt {
                let context = LAContext()
                context.localizedReason = prompt
                query[kSecUseAuthenticationContext as String] = context
            }

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

    /// Update an existing value in Keychain with optional biometric protection
    /// - Parameters:
    ///   - value: The new value
    ///   - key: The key to update
    ///   - requireBiometric: Whether to require Touch ID/Face ID for access
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func update(_ value: String, forKey key: String, requireBiometric: Bool = false) -> Bool {
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

            var attributes: [String: Any] = [
                kSecValueData as String: data,
            ]

            // Add biometric protection if requested
            if requireBiometric {
                if let accessControl = createBiometricAccessControl() {
                    attributes[kSecAttrAccessControl as String] = accessControl
                } else {
                    os_log("Failed to create biometric access control for update", log: .default, type: .error)
                    return false
                }
            }

            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

            if status == errSecItemNotFound {
                // Item doesn't exist, create it
                return save(value, forKey: key, requireBiometric: requireBiometric)
            }

            return status == errSecSuccess
        #endif
    }

    // MARK: - Biometric Authentication Methods

    /// Check if biometric authentication is available on the device
    /// - Returns: True if Touch ID/Face ID is available and enrolled
    func isBiometricAuthenticationAvailable() -> Bool {
        #if UNIT_TESTS
            // Skip biometric checks during unit tests to avoid prompts
            return false
        #else
            let context = LAContext()
            var error: NSError?

            let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

            if let error = error {
                os_log(
                    "Biometric authentication check failed: %{public}@",
                    log: .default,
                    type: .error,
                    error.localizedDescription
                )
            }

            return isAvailable
        #endif
    }

    /// Get the type of biometric authentication available
    /// - Returns: String describing the biometric type (Touch ID, Face ID, etc.)
    func getBiometricType() -> String {
        #if UNIT_TESTS
            // Return mock biometric type during unit tests
            return "Touch ID"
        #else
            let context = LAContext()
            var error: NSError?

            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return "Not Available"
            }

            switch context.biometryType {
            case .none:
                return "None"
            case .touchID:
                return "Touch ID"
            case .faceID:
                return "Face ID"
            case .opticID:
                return "Optic ID"
            @unknown default:
                return "Unknown"
            }
        #endif
    }

    /// Authenticate user with biometric authentication
    /// - Parameters:
    ///   - reason: The reason for authentication (shown to user)
    ///   - completion: Completion handler with success/failure result
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        #if UNIT_TESTS
            // Skip biometric authentication during unit tests to avoid prompts
            DispatchQueue.main.async {
                completion(true, nil)
            }
        #else
            let context = LAContext()

            // Set Touch ID authentication reuse duration (up to 5 minutes)
            context.touchIDAuthenticationAllowableReuseDuration = 60 // 1 minute

            context
                .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                    Task { @MainActor in
                        completion(success, error)
                    }
                }
        #endif
    }

    // MARK: Private

    /// Service identifier for Keychain items
    private let service = "com.breadcrumbs.systemdiagnostics"

    // MARK: - Private Helper Methods

    /// Create a SecAccessControl object for biometric authentication
    /// - Returns: SecAccessControl object or nil if creation fails
    private func createBiometricAccessControl() -> SecAccessControl? {
        var error: Unmanaged<CFError>?

        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            [.biometryAny, .or, .devicePasscode],
            &error
        )

        if let error = error {
            let errorDescription = CFErrorCopyDescription(error.takeRetainedValue())
            let description = errorDescription as String? ?? "Unknown error"
            os_log("Failed to create access control: %{public}@", log: .default, type: .error, description)
            return nil
        }

        return accessControl
    }
}

// MARK: - Convenience Keys

extension KeychainHelper {
    /// Key for OpenAI API key
    static let openAIAPIKey = "openai_api_key"

    // MARK: - Convenience Methods for Biometric-Protected Operations

    /// Save a string value to Keychain with biometric protection (convenience method)
    /// - Parameters:
    ///   - value: The string to save
    ///   - key: The key to identify the value
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func saveWithBiometric(_ value: String, forKey key: String) -> Bool {
        return save(value, forKey: key, requireBiometric: true)
    }

    /// Retrieve a string value from Keychain with biometric authentication (convenience method)
    /// - Parameters:
    ///   - key: The key to identify the value
    ///   - reason: The reason for authentication (shown to user)
    /// - Returns: The stored string, or nil if not found or authentication failed
    func getWithBiometric(forKey key: String, reason: String) -> String? {
        return get(forKey: key, prompt: reason)
    }

    /// Update a string value in Keychain with biometric protection (convenience method)
    /// - Parameters:
    ///   - value: The new value
    ///   - key: The key to update
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func updateWithBiometric(_ value: String, forKey key: String) -> Bool {
        return update(value, forKey: key, requireBiometric: true)
    }
}
