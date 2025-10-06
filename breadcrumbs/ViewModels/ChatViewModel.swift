//
//  ChatViewModel.swift
//  breadcrumbs
//
//  ViewModel for managing chat conversations with AI and tool execution
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var currentInput: String = ""

    // MARK: - Private Properties

    private let aiModel: AIModel
    private let toolRegistry: ToolRegistry

    /// System prompt that defines the AI's behavior
    private let systemPrompt = """
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

    // MARK: - Initialization

    init(aiModel: AIModel, toolRegistry: ToolRegistry = .shared) {
        self.aiModel = aiModel
        self.toolRegistry = toolRegistry

        // Add system message
        self.messages = [
            ChatMessage(
                role: .system,
                content: systemPrompt
            )
        ]
    }

    // MARK: - Public Methods

    /// Send a user message and get AI response
    func sendMessage(_ content: String) async {
        guard !content.isEmpty else { return }

        // Clear any previous errors
        errorMessage = nil
        isProcessing = true

        // Add user message
        let userMessage = ChatMessage(role: .user, content: content)
        messages.append(userMessage)

        // Clear input
        currentInput = ""

        do {
            // Get available tools
            let tools = toolRegistry.getAllTools()

            // Send to AI with tools
            var response = try await aiModel.sendMessage(
                messages: messages,
                tools: tools.isEmpty ? nil : tools
            )

            // Check if AI wants to use tools
            if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
                response = try await handleToolCalls(toolCalls, assistantMessage: response)
            }

            // Add assistant response
            messages.append(response)

        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            // Add error message to chat
            messages.append(
                ChatMessage(
                    role: .assistant,
                    content: "I encountered an error: \(error.localizedDescription). Please try again."
                )
            )
        }

        isProcessing = false
    }

    /// Clear all messages except system prompt
    func clearChat() {
        messages = messages.filter { $0.role == .system }
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// Handle tool calls from the AI
    private func handleToolCalls(
        _ toolCalls: [ToolCall],
        assistantMessage: ChatMessage
    ) async throws -> ChatMessage {

        // Add the assistant message with tool calls to history
        messages.append(assistantMessage)

        var toolResults: [ChatMessage] = []

        // Execute each tool call
        for toolCall in toolCalls {
            do {
                // Decode arguments from JSON string
                // Handle empty arguments case (can be empty string or "{}")
                var arguments: [String: Any] = [:]

                if !toolCall.arguments.isEmpty && toolCall.arguments != "{}" {
                    guard let argumentsData = toolCall.arguments.data(using: .utf8),
                          let parsedArgs = try JSONSerialization.jsonObject(with: argumentsData) as? [String: Any] else {
                        throw ToolError.invalidArguments("Failed to parse tool arguments: \(toolCall.arguments)")
                    }
                    arguments = parsedArgs
                }

                // Execute the tool
                let result = try await toolRegistry.executeTool(
                    name: toolCall.name,
                    arguments: arguments
                )

                // Create tool result message
                let toolResultMessage = ChatMessage(
                    role: .tool,
                    content: result,
                    toolCallId: toolCall.id
                )
                toolResults.append(toolResultMessage)

            } catch {
                // If tool execution fails, send error as tool result
                let errorResult = ChatMessage(
                    role: .tool,
                    content: "Tool execution failed: \(error.localizedDescription)",
                    toolCallId: toolCall.id
                )
                toolResults.append(errorResult)
            }
        }

        // Add tool results to messages
        messages.append(contentsOf: toolResults)

        // Get final response from AI with tool results
        let finalResponse = try await aiModel.sendMessage(
            messages: messages,
            tools: nil  // Don't allow further tool calls in follow-up
        )

        return finalResponse
    }

    /// Format messages for display (excluding system messages)
    func displayMessages() -> [ChatMessage] {
        return messages.filter { $0.role != .system && $0.role != .tool }
    }
}
