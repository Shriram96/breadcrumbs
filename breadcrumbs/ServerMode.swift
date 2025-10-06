//
//  ServerMode.swift
//  breadcrumbs
//
//  Command-line server mode for running as a daemon
//

import Foundation
import ArgumentParser
import Vapor

// Disambiguate ArgumentParser types
typealias ArgumentOption = ArgumentParser.Option
typealias ArgumentFlag = ArgumentParser.Flag

/// Command-line interface for running breadcrumbs in server mode
struct BreadcrumbsServer: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "breadcrumbs-server",
        abstract: "Breadcrumbs diagnostic server for remote access",
        version: "1.0.0"
    )
    
    @ArgumentOption(name: .shortAndLong, help: "Port to listen on")
    var port: UInt16 = 8181
    
    @ArgumentOption(name: .shortAndLong, help: "API key for authentication")
    var apiKey: String = "demo-key-123"
    
    @ArgumentFlag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false
    
    @ArgumentFlag(name: .shortAndLong, help: "Run in background (daemon mode)")
    var daemon: Bool = false
    
    mutating func run() async throws {
        // Configure logging
        if verbose {
            // Vapor logging is configured automatically
        }
        
        Logger.server("Starting Breadcrumbs Server...")
        Logger.server("Port: \(port)")
        Logger.server("API Key: \(apiKey.prefix(8))...")
        Logger.server("Daemon mode: \(daemon)")
        
        // Create AI model (you'll need to provide API key from environment or keychain)
        let openAIModel = try createOpenAIModel()
        
        // Create and start Vapor HTTP server
        let serviceManager = await ServiceManager(aiModel: openAIModel, toolRegistry: .shared)
        await serviceManager.updatePort(UInt16(port))
        await serviceManager.updateAPIKey(apiKey)
        
        // Start server
        await serviceManager.startServer()
        
        guard await serviceManager.isServerRunning else {
            throw ServerError.failedToStart
        }
        
        Logger.server("Vapor server started successfully on \(await serviceManager.serverURL)")
        Logger.server("API available at: \(await serviceManager.apiURL)")
        Logger.server("Health check: \(await serviceManager.apiURL)/health")
        
        if daemon {
            Logger.server("Running in daemon mode...")
            // Keep the process alive
            try await Task.sleep(for: Duration.seconds(Int.max))
        } else {
            Logger.server("Press Ctrl+C to stop the server")
            
            // Handle graceful shutdown
            let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
            signalSource.setEventHandler {
                Logger.server("Received shutdown signal")
                Task {
                    await serviceManager.stopServer()
                    Foundation.exit(0)
                }
            }
            signalSource.resume()
            signal(SIGINT, SIG_IGN)
            
            // Keep running until interrupted
            try await Task.sleep(for: Duration.seconds(Int.max))
        }
    }
    
    private func createOpenAIModel() throws -> OpenAIModel {
        // Try to get API key from environment first
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return OpenAIModel(apiToken: apiKey)
        }
        
        // Try to get from keychain (same key used across the app)
        let keychain = KeychainHelper.shared
        if let apiKey = keychain.get(forKey: KeychainHelper.openAIAPIKey) {
            return OpenAIModel(apiToken: apiKey)
        }
        
        // For demo purposes, use a placeholder (this won't work with real OpenAI)
        Logger.server("Warning: No OpenAI API key found. Using placeholder key.")
        Logger.server("Set OPENAI_API_KEY environment variable or configure in keychain.")
        return OpenAIModel(apiToken: "sk-placeholder-key")
    }
}

// MARK: - Server Errors

enum ServerError: LocalizedError {
    case failedToStart
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .failedToStart:
            return "Failed to start the HTTP server"
        case .invalidConfiguration:
            return "Invalid server configuration"
        }
    }
}


extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
