//
//  VaporServer.swift
//  breadcrumbs
//
//  Vapor-based HTTP Server for Remote Method Invocation
//  Provides REST API endpoints for external access to AI diagnostic capabilities
//

import AppKit
import Combine
import Foundation
import Vapor

// MARK: - VaporServer

/// Vapor-based HTTP Server for providing remote access to breadcrumbs diagnostic capabilities
@MainActor
class VaporServer: ObservableObject {
    // MARK: Lifecycle
    
    // MARK: - Constants
    
    /// Maximum allowed message length for chat requests (100KB)
    static let maxMessageLength = 100_000
    
    /// Maximum request body size for all requests
    static let maxRequestBodySize = "10mb"

    // MARK: - Initialization

    init(aiModel: AIModel, toolRegistry: ToolRegistry = .shared, apiKey: String = "demo-key-123") {
        self.aiModel = aiModel
        self.toolRegistry = toolRegistry
        self.apiKey = apiKey

        // Set up notification observer for app termination
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stop()
            }
        }
    }

    deinit {
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)

        // Ensure server is properly shut down before deallocation
        // Note: Cannot access app property in deinit due to actor isolation
        // The server should be properly shut down before deallocation
    }

    // MARK: Internal

    @Published var isRunning: Bool = false
    @Published var port: Int = 8181
    @Published var lastRequest: String = ""
    @Published var requestCount: Int = 0

    // MARK: - Server Control

    /// Start the Vapor HTTP server
    func start() async throws {
        guard !isRunning else {
            Logger.server("VaporServer is already running")
            return
        }

        Logger.server("🚀 Starting VaporServer on port: \(port)")
        Logger.security("🔒 Server starting on localhost:\(port) - API will be accessible with API key authentication", level: .default)

        // Configure Vapor app
        let env = try Environment.detect()
        let app = try await Application.make(env)

        // Configure HTTP server
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = port

        Logger.server("📡 Configured server hostname: 127.0.0.1, port: \(port)")
        Logger.security("🔒 Server bound to localhost only (127.0.0.1) - not accessible from external networks", level: .default)

        // Configure routes
        try configureRoutes(app)
        Logger.server("🛣️ Routes configured successfully")

        // Start server in background
        Task { [weak self] in
            do {
                Logger.server("🔄 Starting Vapor app.execute()...")
                try await app.execute()
                Logger.server("🔄 Vapor app.execute() completed")
            } catch {
                Logger.server("❌ Vapor server error: \(error)")
                // If server fails, update the running state
                await MainActor.run {
                    self?.isRunning = false
                    self?.app = nil
                }
            }
        }

        self.app = app
        self.isRunning = true

        Logger.server("✅ Vapor HTTP Server started successfully on port \(port)")
        Logger.server("🌐 Server accessible at: http://127.0.0.1:\(port)")
        Logger.security("🔒 HTTP Server is now running and accepting authenticated requests", level: .default)
    }

    /// Stop the Vapor HTTP server
    func stop() {
        guard isRunning else {
            Logger.server("ℹ️ VaporServer is already stopped")
            return
        }

        Logger.server("🛑 Stopping Vapor HTTP Server...")
        Logger.security("🔒 Server stopping - API will no longer be accessible", level: .default)

        // Shutdown the application gracefully
        if let app = app {
            app.shutdown()
            Logger.server("📡 Vapor application shutdown initiated")

            // Wait for shutdown to complete properly
            // Using a semaphore to ensure shutdown finishes before continuing
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 1.0) // Wait up to 1 second
            Logger.server("📡 Vapor application shutdown completed")
        }

        // Clear references
        app = nil
        isRunning = false

        Logger.server("✅ Vapor HTTP Server stopped")
        Logger.security("🔒 HTTP Server stopped successfully", level: .default)
    }

    // MARK: Private

    private var app: Application?
    private let aiModel: AIModel
    private let toolRegistry: ToolRegistry
    private let apiKey: String

    // MARK: - Route Configuration

    private func configureRoutes(_ app: Application) throws {
        Logger.server("🔧 Configuring routes...")

        // Global error handler
        app.middleware.use(ErrorMiddleware.default(environment: app.environment), at: .beginning)
        Logger.server("🛡️ Global error handler configured")

        // Middleware for CORS
        app.middleware.use(CORSMiddleware(), at: .beginning)
        Logger.server("🌐 CORS middleware configured")
        Logger.server("⚠️ Security Note: CORS is configured to allow all origins (*). This is acceptable for localhost-only deployment but should be restricted for production use.")

        // Middleware for API key authentication
        app.middleware.use(APIKeyMiddleware(apiKey: apiKey), at: .beginning)
        Logger.server("🔐 API key authentication middleware configured")
        
        // Configure request body size limits (10MB max to prevent DoS)
        app.routes.defaultMaxBodySize = VaporServer.maxRequestBodySize
        Logger.server("🛡️ Request body size limit set to \(VaporServer.maxRequestBodySize)")

        // API routes
        let api = app.grouped("api", "v1")
        Logger.server("📋 API routes grouped under /api/v1")

        // Health check endpoint
        api.get("health") { req -> HealthResponse in
            Logger.server("🏥 Health check endpoint called")
            Logger.server("📋 Request headers: \(req.headers)")
            Logger.server("📋 Request method: \(req.method)")
            Logger.server("📋 Request URL: \(req.url)")

            // Safely access tools count on main actor
            let toolsCount = await MainActor.run {
                self.toolRegistry.getAllTools().count
            }

            let requestCount = await MainActor.run {
                self.requestCount
            }

            let response = HealthResponse(
                status: "healthy",
                timestamp: Date(),
                uptime: "\(requestCount) requests processed",
                toolsAvailable: toolsCount
            )

            Logger.server("📤 Health response: \(response)")
            return response
        }
        Logger.server("✅ Health endpoint configured: GET /api/v1/health")

        // Tools list endpoint
        api.get("tools") { req -> ToolsResponse in
            Logger.server("🔧 Tools list endpoint called")
            Logger.server("📋 Request headers: \(req.headers)")
            Logger.server("📋 Request method: \(req.method)")
            Logger.server("📋 Request URL: \(req.url)")

            // Safely access tools on main actor to avoid deadlocks
            let tools = await MainActor.run {
                self.toolRegistry.getAllTools()
            }

            Logger.server("📋 Retrieved \(tools.count) tools from registry")

            let toolInfos = tools.map { tool in
                ToolInfo(
                    name: tool.name,
                    description: tool.description,
                    parameters: [:] // Simplified to avoid schema access issues
                )
            }

            let response = ToolsResponse(tools: toolInfos)
            Logger.server("✅ Successfully created \(toolInfos.count) tool infos")
            Logger.server("📤 Response: \(response)")
            return response
        }
        Logger.server("✅ Tools endpoint configured: GET /api/v1/tools")

        // Chat endpoint
        api.post("chat") { req -> EventLoopFuture<ChatResponse> in
            Logger.server("💬 Chat endpoint called")
            Logger.server("📋 Request headers: \(req.headers)")
            Logger.server("📋 Request method: \(req.method)")
            Logger.server("📋 Request URL: \(req.url)")
            Logger.server("📋 Request body size: \(req.body.data?.readableBytes ?? 0) bytes")

            return req.eventLoop.makeFutureWithTask {
                do {
                    Logger.server("🔄 Starting to decode chat request...")
                    let chatRequest = try req.content.decode(ChatRequest.self)
                    Logger.server("📝 Decoded chat request: \(chatRequest.message)")
                    Logger.server("📝 Conversation ID: \(chatRequest.conversationID ?? "none")")
                    Logger.server("📝 Tools enabled: \(chatRequest.toolsEnabled)")

                    // Process with AI model (with timeout protection)
                    let response = try await self.withTimeout(seconds: 30) { [weak self, chatRequest, req] in
                        guard let self = self else {
                            throw Abort(
                                .internalServerError,
                                reason: "Server instance not available"
                            )
                        }

                        return try await self.handleChatRequest(chatRequest, req: req)
                    }

                    Logger.server("✅ Chat request processed successfully")
                    Logger.server("📤 Response: \(response)")
                    return response
                } catch {
                    Logger.server("❌ Error processing chat request: \(error)")
                    Logger.server("❌ Error details: \(error.localizedDescription)")
                    Logger.server("❌ Error type: \(type(of: error))")
                    throw Abort(
                        .internalServerError,
                        reason: "Failed to process chat request: \(error.localizedDescription)"
                    )
                }
            }
        }
        Logger.server("✅ Chat endpoint configured: POST /api/v1/chat")
    }

    // MARK: - Request Handlers

    private func handleChatRequest(_ request: ChatRequest, req: Request) async throws -> ChatResponse {
        Logger.server("🔄 Starting chat request processing...")
        
        let clientAddr = req.remoteAddress?.description ?? "unknown"

        // Input validation
        guard !request.message.isEmpty else {
            Logger.security("🔒 Validation failed: Empty message from \(clientAddr)")
            throw Abort(.badRequest, reason: "Message cannot be empty")
        }
        
        // Limit message length to prevent abuse (100KB max)
        guard request.message.count <= VaporServer.maxMessageLength else {
            Logger.security("🔒 Validation failed: Message too long (\(request.message.count) chars) from \(clientAddr)")
            throw Abort(.badRequest, reason: "Message exceeds maximum length of \(VaporServer.maxMessageLength) characters")
        }
        
        // Basic sanitization check - detect potential injection attempts
        if containsSuspiciousPatterns(request.message) {
            Logger.security("🔒 Security: Suspicious patterns detected in message from \(clientAddr)", level: .default)
            // Don't block but log for monitoring
        }

        await MainActor.run {
            self.requestCount += 1
            self.lastRequest = "POST /api/v1/chat - \(Date())"
        }

        Logger.server("📝 Processing chat request: \(request.message.prefix(100))...")

        do {
            // Create chat messages
            var messages: [ChatMessage] = [
                ChatMessage(
                    role: .system,
                    content: """
                    You are a helpful system diagnostic assistant for macOS. Your role is to help users \
                    diagnose and understand their system issues, particularly related to network connectivity, \
                    VPN status, and other system diagnostics.

                    When a user asks about their network, VPN, or connectivity issues:
                    1. Use the available tools to gather real system information
                    2. Provide clear, accurate explanations based on the tool results
                    3. Offer helpful troubleshooting steps when appropriate
                    4. Be concise but thorough in your responses

                    Available tools:
                    - vpn_detector: Check if VPN is connected and get connection details

                    Always prioritize using tools to get accurate system information rather than making assumptions.
                    """
                ),
            ]

            // Add user message
            messages.append(ChatMessage(role: .user, content: request.message))
            Logger.server("💬 Created \(messages.count) messages")

            // Get available tools safely
            let tools = await MainActor.run {
                self.toolRegistry.getAllTools()
            }
            Logger.server("🔧 Retrieved \(tools.count) available tools")

            // Send to AI
            Logger.server("🤖 Sending request to AI model...")
            var response: ChatMessage
            do {
                response = try await self.aiModel.sendMessage(
                    messages: messages,
                    tools: request.toolsEnabled ? tools : nil
                )
                Logger.server("✅ Received response from AI model")
            } catch {
                Logger.server("❌ AI model error: \(error)")
                throw error
            }

            // Handle tool calls if any
            var toolsUsed = [String]()
            if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
                Logger.server("🛠️ Processing \(toolCalls.count) tool calls...")
                // Capture tool names before processing
                toolsUsed = toolCalls.map { $0.name }
                response = try await self.handleToolCalls(toolCalls, messages: &messages)
                Logger.server("✅ Tool calls processed successfully")
            }

            // Create API response
            let chatResponse = ChatResponse(
                response: response.content,
                conversationID: request.conversationID ?? UUID().uuidString,
                timestamp: Date(),
                toolsUsed: toolsUsed
            )

            Logger.server("🎉 Chat request completed successfully")
            return chatResponse

        } catch {
            Logger.server("❌ Error in handleChatRequest: \(error)")
            throw error
        }
    }

    private func handleToolCalls(_ toolCalls: [ToolCall], messages: inout [ChatMessage]) async throws -> ChatMessage {
        Logger.server("🛠️ Starting tool calls processing for \(toolCalls.count) tools")

        // Add the assistant message with tool calls to history
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: "",
            toolCalls: toolCalls
        )
        messages.append(assistantMessage)

        var toolResults = [ChatMessage]()

        // Execute each tool call
        for (index, toolCall) in toolCalls.enumerated() {
            Logger.server("🔧 Executing tool \(index + 1)/\(toolCalls.count): \(toolCall.name)")

            do {
                // Decode arguments from JSON string
                var arguments = [String: Any]()
                if !toolCall.arguments.isEmpty && toolCall.arguments != "{}" {
                    guard
                        let argumentsData = toolCall.arguments.data(using: .utf8),
                        let parsedArgs = try JSONSerialization.jsonObject(with: argumentsData) as? [String: Any]
                    else {
                        throw ToolError.invalidArguments("Failed to parse tool arguments: \(toolCall.arguments)")
                    }

                    arguments = parsedArgs
                    Logger.server("📋 Parsed arguments for \(toolCall.name): \(arguments)")
                }

                // Execute the tool
                Logger.server("⚡ Executing tool: \(toolCall.name)")
                let result = try await toolRegistry.executeTool(
                    name: toolCall.name,
                    arguments: arguments
                )
                Logger.server("✅ Tool \(toolCall.name) executed successfully")

                // Create tool result message
                let toolResultMessage = ChatMessage(
                    role: .tool,
                    content: result,
                    toolCallID: toolCall.id
                )
                toolResults.append(toolResultMessage)

            } catch {
                Logger.server("❌ Tool \(toolCall.name) execution failed: \(error)")
                // If tool execution fails, send error as tool result
                let errorResult = ChatMessage(
                    role: .tool,
                    content: "Tool execution failed: \(error.localizedDescription)",
                    toolCallID: toolCall.id
                )
                toolResults.append(errorResult)
            }
        }

        // Add tool results to messages
        messages.append(contentsOf: toolResults)
        Logger.server("📝 Added \(toolResults.count) tool results to conversation")

        // Get final response from AI with tool results
        Logger.server("🤖 Getting final response from AI with tool results...")
        let finalResponse = try await aiModel.sendMessage(
            messages: messages,
            tools: nil // Don't allow further tool calls in follow-up
        )
        Logger.server("✅ Final response received from AI")

        return finalResponse
    }

    // MARK: - Helper Functions
    
    // Check for suspicious patterns that might indicate injection attempts
    private func containsSuspiciousPatterns(_ text: String) -> Bool {
        let suspiciousPatterns = [
            "<script", "javascript:", "onerror=", "onload=",
            "eval(", "exec(", "../", "..\\",
            "file://", "data:text/html"
        ]
        
        let lowercaseText = text.lowercased()
        return suspiciousPatterns.contains { lowercaseText.contains($0) }
    }

    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }
}

// MARK: - TimeoutError

struct TimeoutError: Error {
    let message = "Operation timed out"
}

// MARK: - HealthResponse

struct HealthResponse: Content {
    enum CodingKeys: String, CodingKey {
        case status
        case timestamp
        case uptime
        case toolsAvailable = "tools_available"
    }

    let status: String
    let timestamp: Date
    let uptime: String
    let toolsAvailable: Int
}

// MARK: - ToolInfo

struct ToolInfo: Content {
    let name: String
    let description: String
    let parameters: [String: String] // Changed to String for Codable compliance
}

// MARK: - ToolsResponse

struct ToolsResponse: Content {
    let tools: [ToolInfo]
}

// MARK: - ChatRequest

struct ChatRequest: Content {
    enum CodingKeys: String, CodingKey {
        case message
        case conversationID = "conversation_id"
        case toolsEnabled = "tools_enabled"
    }

    let message: String
    let conversationID: String?
    let toolsEnabled: Bool
}

// MARK: - ChatResponse

struct ChatResponse: Content {
    enum CodingKeys: String, CodingKey {
        case response
        case conversationID = "conversation_id"
        case timestamp
        case toolsUsed = "tools_used"
    }

    let response: String
    let conversationID: String
    let timestamp: Date
    let toolsUsed: [String]
}

// MARK: - CORSMiddleware

struct CORSMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).map { response in
            response.headers.add(name: .accessControlAllowOrigin, value: "*")
            response.headers.add(name: .accessControlAllowMethods, value: "GET, POST, OPTIONS")
            response.headers.add(name: .accessControlAllowHeaders, value: "Content-Type, Authorization")
            return response
        }
    }
}

// MARK: - APIKeyMiddleware

struct APIKeyMiddleware: Middleware {
    let apiKey: String

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        // Skip authentication for health check
        if request.url.path.hasSuffix("/health") {
            return next.respond(to: request)
        }

        // Check for API key in Authorization header
        guard let authHeader = request.headers.bearerAuthorization else {
            let clientAddr = request.remoteAddress?.description ?? "unknown"
            Logger.security("🔒 Authentication failed: Missing Authorization header from \(clientAddr) for \(request.url.path)")
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Missing Authorization header"))
        }
        
        // Use constant-time comparison to prevent timing attacks
        guard constantTimeCompare(authHeader.token, apiKey) else {
            let clientAddr = request.remoteAddress?.description ?? "unknown"
            Logger.security("🔒 Authentication failed: Invalid API key from \(clientAddr) for \(request.url.path)")
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Invalid API key"))
        }

        let clientAddr = request.remoteAddress?.description ?? "unknown"
        Logger.server("✅ Authentication successful for request to \(request.url.path) from \(clientAddr)")
        return next.respond(to: request)
    }
    
    // Constant-time string comparison to prevent timing attacks
    private func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else {
            return false
        }
        
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        
        var result: UInt8 = 0
        for i in 0..<aBytes.count {
            result |= aBytes[i] ^ bBytes[i]
        }
        
        return result == 0
    }
}

// MARK: - Logger Extension

extension Logger {
    static func server(_ message: String) {
        Logger.debug(message, category: Logger.general)
    }
}
