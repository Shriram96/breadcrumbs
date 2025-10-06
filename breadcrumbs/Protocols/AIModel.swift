//
//  AIModel.swift
//  breadcrumbs
//
//  AI Model Protocol - Abstract interface for all AI providers
//
//  PROTOCOL OVERVIEW:
//  The AIModel protocol defines the contract that all AI provider implementations must follow.
//  This enables the app to work with multiple AI providers (OpenAI, Anthropic, etc.) interchangeably.
//
//  KEY RESPONSIBILITIES:
//  1. Send chat completion requests with conversation history
//  2. Support tool/function calling capabilities
//  3. Handle both streaming and non-streaming responses
//  4. Convert provider-specific formats to our unified ChatMessage format
//
//  CONFORMING TYPES:
//  - OpenAIModel: Implementation using MacPaw/OpenAI package
//  - (Future) AnthropicModel, GoogleGeminiModel, etc.
//
//  USAGE EXAMPLE:
//  ```swift
//  let model: AIModel = OpenAIModel(apiToken: "sk-...")
//  let messages = [ChatMessage(role: .user, content: "Hello!")]
//  let response = try await model.sendMessage(messages: messages, tools: nil)
//  print(response.content) // AI's response
//  ```
//
//  THREAD SAFETY:
//  All conforming types must be Sendable for safe concurrent usage.
//

import Foundation

/// Represents a message in the chat conversation
struct ChatMessage: Identifiable, Codable, Sendable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let toolCalls: [ToolCall]?

    /// Additional metadata for tool results
    /// Used when role is .tool to reference which tool call this responds to
    let toolCallId: String?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        toolCalls: [ToolCall]? = nil,
        toolCallId: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }
}

/// Message roles in conversation
enum MessageRole: String, Codable, Sendable {
    case system
    case user
    case assistant
    case tool
}

/// Represents a tool call request from the AI
struct ToolCall: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let arguments: String // JSON string of arguments
}

/// Represents a tool call result
struct ToolResult: Codable, Sendable {
    let toolCallId: String
    let result: String
}

/// Protocol that all AI model providers must conform to
protocol AIModel: Sendable {
    /// Unique identifier for the model provider (e.g., "openai", "anthropic")
    var providerId: String { get }

    /// Display name for the model (e.g., "GPT-4", "Claude 3.5")
    var displayName: String { get }

    /// Whether this model supports tool/function calling
    var supportsTools: Bool { get }

    /// Send a chat completion request with conversation history
    /// - Parameters:
    ///   - messages: Array of conversation messages
    ///   - tools: Optional array of available tools the model can use
    /// - Returns: The assistant's response message
    func sendMessage(
        messages: [ChatMessage],
        tools: [AITool]?
    ) async throws -> ChatMessage

    /// Stream a chat completion response (optional, for streaming support)
    /// - Parameters:
    ///   - messages: Array of conversation messages
    ///   - tools: Optional array of available tools
    /// - Returns: AsyncThrowingStream of partial response chunks
    func streamMessage(
        messages: [ChatMessage],
        tools: [AITool]?
    ) async throws -> AsyncThrowingStream<String, Error>
}

/// Default implementation for streaming (optional feature)
extension AIModel {
    func streamMessage(
        messages: [ChatMessage],
        tools: [AITool]?
    ) async throws -> AsyncThrowingStream<String, Error> {
        // Default: convert non-streaming to single chunk
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await sendMessage(messages: messages, tools: tools)
                    continuation.yield(response.content)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

/// Errors that can occur during AI model operations
enum AIModelError: LocalizedError {
    case invalidResponse
    case toolExecutionFailed(String)
    case apiKeyMissing
    case networkError(Error)
    case unsupportedFeature

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI model"
        case .toolExecutionFailed(let message):
            return "Tool execution failed: \(message)"
        case .apiKeyMissing:
            return "API key is missing"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unsupportedFeature:
            return "This feature is not supported by the model"
        }
    }
}
