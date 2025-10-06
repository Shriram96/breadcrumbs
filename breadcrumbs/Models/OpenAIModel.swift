//
//  OpenAIModel.swift
//  breadcrumbs
//
//  OpenAI implementation of AIModel protocol using MacPaw/OpenAI package
//

import Foundation
import OpenAI

/// OpenAI implementation of the AIModel protocol
/// Uses the MacPaw/OpenAI Swift package for API communication
final class OpenAIModel: AIModel {

    // MARK: - Properties

    private let client: OpenAI
    private let modelType: Model

    /// Unique identifier for OpenAI provider
    let providerId: String = "openai"

    /// Display name based on selected model
    var displayName: String {
        modelType  // Model is a String typealias, not an enum
    }

    /// OpenAI supports tool/function calling
    let supportsTools: Bool = true

    // MARK: - Initialization

    /// Initialize OpenAI model with API token
    /// - Parameters:
    ///   - apiToken: OpenAI API key
    ///   - model: The specific OpenAI model to use (defaults to GPT-4o)
    init(apiToken: String, model: Model = .gpt4_o) {
        self.client = OpenAI(apiToken: apiToken)
        self.modelType = model
    }

    /// Initialize with custom configuration
    /// - Parameters:
    ///   - configuration: OpenAI configuration object
    ///   - model: The specific OpenAI model to use
    init(configuration: OpenAI.Configuration, model: Model = .gpt4_o) {
        self.client = OpenAI(configuration: configuration)
        self.modelType = model
    }

    // MARK: - AIModel Protocol Implementation

    /// Send a chat completion request to OpenAI
    /// - Parameters:
    ///   - messages: Array of conversation messages
    ///   - tools: Optional array of available tools
    /// - Returns: Assistant's response message
    func sendMessage(
        messages: [ChatMessage],
        tools: [AITool]?
    ) async throws -> ChatMessage {

        Logger.tools("OpenAIModel.sendMessage: Called with \(messages.count) messages and \(tools?.count ?? 0) tools")
        
        // Convert our messages to OpenAI format
        let openAIMessages = try convertMessagesToOpenAI(messages)
        Logger.tools("OpenAIModel.sendMessage: Converted to \(openAIMessages.count) OpenAI messages")

        // Convert tools to OpenAI format
        let openAITools = tools?.map { convertToolToOpenAI($0) }
        Logger.tools("OpenAIModel.sendMessage: Converted to \(openAITools?.count ?? 0) OpenAI tools")

        // Create chat query
        let query = ChatQuery(
            messages: openAIMessages,
            model: modelType,
            tools: openAITools
        )
        Logger.tools("OpenAIModel.sendMessage: Created ChatQuery with model: \(modelType)")

        // Execute request with async/await wrapper
        Logger.tools("OpenAIModel.sendMessage: Executing chat request...")
        let result = try await executeChat(query: query)
        Logger.tools("OpenAIModel.sendMessage: Received response with \(result.choices.count) choices")

        // Extract the first choice
        guard let choice = result.choices.first else {
            Logger.tools("OpenAIModel.sendMessage: ERROR - No choices in response")
            throw AIModelError.invalidResponse
        }

        // Convert OpenAI response to our ChatMessage format
        let response = try convertOpenAIResponseToMessage(choice.message)
        Logger.tools("OpenAIModel.sendMessage: Converted response - role: \(response.role), content: \(response.content.prefix(50))..., toolCalls: \(response.toolCalls?.count ?? 0)")
        return response
    }

    /// Stream a chat completion response from OpenAI
    /// - Parameters:
    ///   - messages: Array of conversation messages
    ///   - tools: Optional array of available tools
    /// - Returns: AsyncThrowingStream of response chunks
    func streamMessage(
        messages: [ChatMessage],
        tools: [AITool]?
    ) async throws -> AsyncThrowingStream<String, Error> {

        // Convert our messages to OpenAI format
        let openAIMessages = try convertMessagesToOpenAI(messages)

        // Convert tools to OpenAI format
        let openAITools = tools?.map { convertToolToOpenAI($0) }

        // Create streaming chat query
        let query = ChatQuery(
            messages: openAIMessages,
            model: modelType,
            tools: openAITools,
            stream: true
        )

        // Return async stream
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await executeChatStream(query: query) { chunk in
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private Helper Methods

    /// Execute non-streaming chat request with async/await
    private func executeChat(query: ChatQuery) async throws -> ChatResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ChatResult, Error>) in
            _ = client.chats(query: query) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Execute streaming chat request with async/await
    private func executeChatStream(
        query: ChatQuery,
        onChunk: @escaping (String) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var hasResumed = false

            _ = client.chatsStream(query: query) { result in
                switch result {
                case .success(let streamResult):
                    // Extract delta content from stream
                    if let content = streamResult.choices.first?.delta.content {
                        onChunk(content)
                    }
                case .failure(let error):
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                }
            } completion: { error in
                if let error = error {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                } else {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                }
            }
        }
    }

    /// Convert our ChatMessage array to OpenAI's message format
    private func convertMessagesToOpenAI(_ messages: [ChatMessage]) throws -> [ChatQuery.ChatCompletionMessageParam] {
        Logger.tools("OpenAIModel.convertMessagesToOpenAI: Converting \(messages.count) messages")
        
        return messages.compactMap { message -> ChatQuery.ChatCompletionMessageParam? in
            Logger.tools("OpenAIModel.convertMessagesToOpenAI: Converting message - role: \(message.role), content: \(message.content.prefix(50))..., toolCalls: \(message.toolCalls?.count ?? 0), toolCallId: \(message.toolCallId ?? "nil")")
            
            switch message.role {
            case .system:
                return .system(
                    .init(content: .textContent(message.content))
                )

            case .user:
                return .user(
                    .init(content: .string(message.content))
                )

            case .assistant:
                // Check if there are tool calls
                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    let openAIToolCalls = toolCalls.map { toolCall in
                        ChatQuery.ChatCompletionMessageParam.AssistantMessageParam.ToolCallParam(
                            id: toolCall.id,
                            function: .init(
                                arguments: toolCall.arguments,
                                name: toolCall.name
                            )
                        )
                    }
                    // For tool call messages, omit content parameter (it's optional)
                    return .assistant(
                        .init(toolCalls: openAIToolCalls)
                    )
                } else {
                    // Regular assistant message - skip if empty content
                    if message.content.isEmpty {
                        return nil
                    }
                    // Set the content field properly for assistant messages
                    return .assistant(
                        .init(content: .textContent(message.content))
                    )
                }

            case .tool:
                // Tool result messages - must include the tool_call_id
                guard let toolCallId = message.toolCallId else {
                    // Skip tool messages without ID (shouldn't happen)
                    Logger.tools("OpenAIModel.convertMessagesToOpenAI: WARNING - Tool message without toolCallId, skipping")
                    return nil
                }
                Logger.tools("OpenAIModel.convertMessagesToOpenAI: Converting tool message with toolCallId: \(toolCallId)")
                return .tool(
                    .init(content: .textContent(message.content), toolCallId: toolCallId)
                )
            }
        }
    }

    /// Convert AITool to OpenAI's ChatCompletionToolParam format
    private func convertToolToOpenAI(_ tool: AITool) -> ChatQuery.ChatCompletionToolParam {
        // Convert parameters schema to JSONSchema
        let parameters = convertToJSONSchema(tool.parametersSchema.jsonSchema)

        return ChatQuery.ChatCompletionToolParam(
            function: .init(
                name: tool.name,
                description: tool.description,
                parameters: parameters
            )
        )
    }

    /// Convert dictionary to JSONSchema format
    private func convertToJSONSchema(_ schema: [String: Any]) -> JSONSchema {
        var fields: [JSONSchemaField] = [.type(.object)]

        // Add properties if present
        if let schemaProperties = schema["properties"] as? [String: [String: Any]] {
            var propsDict: [String: JSONSchema] = [:]
            for (key, value) in schemaProperties {
                propsDict[key] = createJSONSchemaFromDict(value)
            }
            fields.append(.properties(propsDict))
        }

        // Add required fields if present
        if let required = schema["required"] as? [String], !required.isEmpty {
            fields.append(.required(required))
        }

        return JSONSchema(fields: fields)
    }

    /// Recursively create JSONSchema from dictionary
    private func createJSONSchemaFromDict(_ dict: [String: Any]) -> JSONSchema {
        let typeString = dict["type"] as? String ?? "string"

        var fields: [JSONSchemaField] = []

        // Add type field - convert string to JSONSchemaInstanceType
        let instanceType: JSONSchemaInstanceType
        switch typeString {
        case "string":
            instanceType = .string
        case "number":
            instanceType = .number
        case "integer":
            instanceType = .integer
        case "boolean":
            instanceType = .boolean
        case "array":
            instanceType = .array
        case "object":
            instanceType = .object
        case "null":
            instanceType = .null
        default:
            instanceType = .string
        }
        fields.append(.type(instanceType))

        // Add description if present
        if let description = dict["description"] as? String {
            fields.append(.description(description))
        }

        // Add enum values if present (as additionalProperties)
        if let enumValues = dict["enum"] as? [String] {
            // Store enum values as a nested property
            let enumSchemas = enumValues.map { value in
                JSONSchema(.const(value))
            }
            // For now, we'll skip enum handling as the API doesn't have direct support
            // This may need refinement based on actual usage
        }

        return JSONSchema(fields: fields)
    }

    /// Convert OpenAI response message to our ChatMessage format
    private func convertOpenAIResponseToMessage(
        _ message: ChatResult.Choice.Message
    ) throws -> ChatMessage {

        Logger.tools("OpenAIModel.convertOpenAIResponseToMessage: Converting OpenAI response")
        
        // Extract content - message.content is String? in v0.4.6
        let content = message.content ?? ""
        Logger.tools("OpenAIModel.convertOpenAIResponseToMessage: Content: \(content.prefix(50))...")

        // Extract tool calls if present
        var toolCalls: [ToolCall]? = nil
        if let openAIToolCalls = message.toolCalls {
            Logger.tools("OpenAIModel.convertOpenAIResponseToMessage: Found \(openAIToolCalls.count) tool calls")
            toolCalls = openAIToolCalls.map { openAIToolCall in
                Logger.tools("OpenAIModel.convertOpenAIResponseToMessage: Tool call - ID: \(openAIToolCall.id), name: \(openAIToolCall.function.name)")
                return ToolCall(
                    id: openAIToolCall.id,
                    name: openAIToolCall.function.name,
                    arguments: openAIToolCall.function.arguments
                )
            }
        } else {
            Logger.tools("OpenAIModel.convertOpenAIResponseToMessage: No tool calls in response")
        }

        let result = ChatMessage(
            role: .assistant,
            content: content,
            toolCalls: toolCalls
        )
        
        Logger.tools("OpenAIModel.convertOpenAIResponseToMessage: Created ChatMessage - role: \(result.role), content: \(result.content.prefix(50))..., toolCalls: \(result.toolCalls?.count ?? 0)")
        return result
    }
}
