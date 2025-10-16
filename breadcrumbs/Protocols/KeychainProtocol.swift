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
    func save(_ value: String, forKey key: String) -> Bool
    func get(forKey key: String) -> String?
    func delete(forKey key: String) -> Bool
    func update(_ value: String, forKey key: String) -> Bool
    func exists(forKey key: String) -> Bool
}
