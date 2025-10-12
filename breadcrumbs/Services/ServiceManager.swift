//
//  ServiceManager.swift
//  breadcrumbs
//
//  Service Manager for handling HTTP server lifecycle and configuration
//

import Combine
import Foundation
import Security
import SwiftUI

// MARK: - ServiceManager

/// Manages the HTTP server service for remote access
@MainActor
final class ServiceManager: ObservableObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(aiModel: AIModel, toolRegistry: ToolRegistry) {
        self.aiModel = aiModel
        self.toolRegistry = toolRegistry

        // Generate a random API key if using default
        if apiKey == "demo-key-123" {
            apiKey = generateAPIKey()
            Logger.security("🔒 Generated new cryptographically secure API key on initialization", level: .default)
        }
    }

    deinit {
        // Note: We can't access main actor properties in deinit
        // The server should be stopped explicitly before deallocation
        // This is handled by the VaporServer's own deinit and notification observers
    }

    // MARK: Internal

    // MARK: - Published Properties

    @Published var isServerRunning: Bool = false
    @Published var serverPort: UInt16 = 8181
    @Published var apiKey: String = "demo-key-123"
    @Published var serverStatus: String = "Stopped"
    @Published var lastError: String?

    // MARK: - Server Information

    /// Get server URL for external access
    var serverURL: String {
        return "http://localhost:\(serverPort)"
    }

    /// Get API endpoint URL
    var apiURL: String {
        return "\(serverURL)/api/v1"
    }

    /// Get curl command example for testing
    var curlExample: String {
        return """
        curl -X POST \(apiURL)/chat \\
          -H "Content-Type: application/json" \\
          -H "Authorization: Bearer \(apiKey)" \\
          -d '{
            "message": "Check my VPN status",
            "tools_enabled": true
          }'
        """
    }

    // MARK: - Server Control

    /// Start the HTTP server
    func startServer() async {
        guard !isServerRunning else {
            Logger.service("Server is already running")
            return
        }

        do {
            Logger.service("Starting server with port: \(serverPort)")

            vaporServer = VaporServer(
                aiModel: aiModel,
                toolRegistry: toolRegistry,
                apiKey: apiKey
            )

            // Ensure VaporServer uses the correct port
            vaporServer?.port = Int(serverPort)
            Logger.service("Set VaporServer port to: \(vaporServer?.port ?? 0)")

            // Set up server monitoring
            setupServerMonitoring()

            // Start the server
            Logger.service("Attempting to start VaporServer...")
            try await vaporServer?.start()

            isServerRunning = true
            serverStatus = "Running on port \(serverPort)"
            lastError = nil

            Logger.service("✅ Vapor HTTP Server started successfully on port \(serverPort)")
            Logger.service("Server URL: \(serverURL)")
            Logger.service("API URL: \(apiURL)")

        } catch {
            lastError = "Failed to start server: \(error.localizedDescription)"
            serverStatus = "Failed to start"
            Logger.service("❌ Failed to start Vapor HTTP server: \(error)")
        }
    }

    /// Stop the HTTP server
    func stopServer() {
        guard isServerRunning else {
            Logger.service("Server is not running")
            return
        }

        Logger.service("🛑 Stopping Vapor HTTP Server...")

        // Ensure proper shutdown before deallocating
        vaporServer?.stop()

        // Wait for shutdown to complete using a semaphore
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2.0) // Wait up to 2 seconds

        vaporServer = nil

        isServerRunning = false
        serverStatus = "Stopped"
        lastError = nil

        Logger.service("✅ Vapor HTTP Server stopped")
    }

    /// Restart the HTTP server
    func restartServer() async {
        stopServer()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        await startServer()
    }

    // MARK: - Configuration

    /// Update server port
    func updatePort(_ newPort: UInt16) async {
        Logger.service("🔄 Updating port from \(serverPort) to \(newPort)")

        guard newPort != serverPort else {
            Logger.service("Port is already \(newPort), no change needed")
            return
        }

        let wasRunning = isServerRunning
        if wasRunning {
            Logger.service("Server is running, stopping before port change...")
            stopServer()
        }

        serverPort = newPort
        Logger.service("✅ Port updated to \(serverPort)")

        if wasRunning {
            Logger.service("Server was running, restarting with new port...")
            await startServer()
        }
    }

    /// Update API key
    func updateAPIKey(_ newKey: String) async {
        guard !newKey.isEmpty else {
            return
        }

        let wasRunning = isServerRunning
        if wasRunning {
            stopServer()
        }

        apiKey = newKey
        Logger.security("🔒 API key updated - server will use new key for authentication", level: .default)

        if wasRunning {
            await startServer()
        }
    }

    /// Generate a new random API key
    func generateNewAPIKey() async {
        let newKey = generateAPIKey()
        Logger.security("🔒 Generating new cryptographically secure API key", level: .default)
        await updateAPIKey(newKey)
    }

    // MARK: Private

    // MARK: - Private Properties

    private var vaporServer: VaporServer?
    private let aiModel: AIModel
    private let toolRegistry: ToolRegistry
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Private Methods

    private func setupServerMonitoring() {
        // Monitor server status changes
        vaporServer?.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning in
                self?.isServerRunning = isRunning
                if !isRunning {
                    self?.serverStatus = "Stopped"
                }
            }
            .store(in: &cancellables)

        // Don't monitor port changes from VaporServer as it can cause synchronization issues
        // The ServiceManager should be the source of truth for the port
        // vaporServer?.$port
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] port in
        //         self?.serverPort = UInt16(port)
        //     }
        //     .store(in: &cancellables)
    }

    private func generateAPIKey() -> String {
        // Use cryptographically secure random generation
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        guard result == errSecSuccess else {
            Logger.service("⚠️ Failed to generate cryptographically secure random bytes, falling back to less secure method")
            // Fallback to less secure but still functional method
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
            let keyLength = 32
            var fallbackResult = ""
            for _ in 0..<keyLength {
                let randomIndex = Int.random(in: 0..<characters.count)
                let character = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
                fallbackResult.append(character)
            }
            return fallbackResult
        }
        
        // Convert bytes to base64 for a safe string representation
        let data = Data(bytes)
        let base64String = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        Logger.service("✅ Generated cryptographically secure API key")
        return base64String
    }
}

// MARK: - Logger Extension

extension Logger {
    static func service(_ message: String) {
        Logger.debug(message, category: Logger.general)
    }
}
