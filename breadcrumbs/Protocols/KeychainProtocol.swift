//
//  KeychainProtocol.swift
//  breadcrumbs
//
//  Protocol for keychain operations to enable testing
//

import Foundation

// MARK: - KeychainProtocol

/// Protocol defining keychain operations for dependency injection and testing
@MainActor
protocol KeychainProtocol {
    func save(_ value: String, forKey key: String, requireBiometric: Bool) -> Bool
    func get(forKey key: String, prompt: String?) -> String?
    func delete(forKey key: String) -> Bool
    func update(_ value: String, forKey key: String, requireBiometric: Bool) -> Bool
    func exists(forKey key: String) -> Bool
    func isBiometricAuthenticationAvailable() -> Bool
    func getBiometricType() -> String
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void)
}

// MARK: - Convenience Methods

extension KeychainProtocol {
    func save(_ value: String, forKey key: String) -> Bool {
        return save(value, forKey: key, requireBiometric: false)
    }

    func get(forKey key: String) -> String? {
        return get(forKey: key, prompt: nil)
    }

    func update(_ value: String, forKey key: String) -> Bool {
        return update(value, forKey: key, requireBiometric: false)
    }
}
