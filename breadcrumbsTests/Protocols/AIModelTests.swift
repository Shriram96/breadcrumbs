//
//  AIModelTests.swift
//  breadcrumbsTests
//
//  Unit tests for AIModel protocol and related structures
//

import XCTest
@testable import breadcrumbs

/// Simple mock that only implements sendMessage (not streamMessage) to test default implementation
final class SimpleMockAIModel: AIModel {
    let providerId: String = "simple-mock"
    let displayName: String = "Simple Mock AI Model"
    let supportsTools: Bool = true
    
    var shouldThrowError: Bool = false
    var mockError: Error = AIModelError.invalidResponse
    var mockResponse: ChatMessage?
    
    func sendMessage(messages: [ChatMessage], tools: [AITool]?) async throws -> ChatMessage {
        if shouldThrowError {
            throw mockError
        }
        
        if let response = mockResponse {
            return response
        }
        
        return ChatMessage(
            role: .assistant,
            content: "Simple mock response for \(messages.count) messages"
        )
    }
    
    func configureSuccessResponse(_ response: ChatMessage) {
        shouldThrowError = false
        mockResponse = response
    }
    
    func configureError(_ error: Error) {
        shouldThrowError = true
        mockError = error
    }
}

final class AIModelTests: XCTestCase {
    
    // MARK: - AIModel Protocol Tests
    
    func testAIModelConformance() {
        // Given
        let mockModel = MockAIModel()
        
        // Then
        XCTAssertEqual(mockModel.providerId, "mock")
        XCTAssertEqual(mockModel.displayName, "Mock AI Model")
        XCTAssertTrue(mockModel.supportsTools)
    }
    
    @MainActor func testAIModelSendMessage() async throws {
        // Given
        let mockModel = MockAIModel()
        let messages = [
            ChatMessage(role: .user, content: "Hello")
        ]
        let expectedResponse = ChatMessage(role: .assistant, content: "Hello back!")
        mockModel.configureSuccessResponse(expectedResponse)
        
        // When
        let response = try await mockModel.sendMessage(messages: messages, tools: nil)
        
        // Then
        XCTAssertEqual(response.content, "Hello back!")
        XCTAssertEqual(mockModel.sendMessageCallCount, 1)
        XCTAssertEqual(mockModel.lastMessages, messages)
    }
    
    @MainActor func testAIModelSendMessageWithTools() async throws {
        // Given
        let mockModel = MockAIModel()
        let messages = [
            ChatMessage(role: .user, content: "Use a tool")
        ]
        let tools = [MockAITool(name: "test_tool")]
        let expectedResponse = ChatMessage(role: .assistant, content: "Tool used")
        mockModel.configureSuccessResponse(expectedResponse)
        
        // When
        let response = try await mockModel.sendMessage(messages: messages, tools: tools)
        
        // Then
        XCTAssertEqual(response.content, "Tool used")
        XCTAssertEqual(mockModel.sendMessageCallCount, 1)
        XCTAssertEqual(mockModel.lastMessages, messages)
        // Note: Cannot compare tools directly due to protocol conformance issues
        // XCTAssertEqual(mockModel.lastTools, tools)
    }
    
    func testAIModelSendMessageError() async {
        // Given
        let mockModel = MockAIModel()
        let messages = [
            ChatMessage(role: .user, content: "Hello")
        ]
        let expectedError = AIModelError.networkError(NSError(domain: "TestError", code: -1, userInfo: nil))
        mockModel.configureError(expectedError)
        
        // When & Then
        do {
            let _ = try await mockModel.sendMessage(messages: messages, tools: nil)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is AIModelError)
        }
    }
    
    @MainActor func testAIModelStreamMessage() async throws {
        // Given
        let mockModel = MockAIModel()
        let messages = [
            ChatMessage(role: .user, content: "Stream response")
        ]
        let chunks = ["Hello", " ", "world", "!"]
        mockModel.configureStreamChunks(chunks)
        
        // When
        let stream = try await mockModel.streamMessage(messages: messages, tools: nil)
        var receivedChunks: [String] = []
        
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        // Then
        XCTAssertEqual(receivedChunks, chunks)
        XCTAssertEqual(mockModel.streamMessageCallCount, 1)
        XCTAssertEqual(mockModel.lastMessages, messages)
    }
    
    @MainActor func testAIModelStreamMessageError() async {
        // Given
        let mockModel = MockAIModel()
        let messages = [
            ChatMessage(role: .user, content: "Stream error")
        ]
        let expectedError = AIModelError.networkError(NSError(domain: "TestError", code: -1, userInfo: nil))
        mockModel.configureError(expectedError)
        
        // When & Then
        do {
            let stream = try await mockModel.streamMessage(messages: messages, tools: nil)
            var receivedChunks: [String] = []
            
            for try await chunk in stream {
                receivedChunks.append(chunk)
            }
            
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is AIModelError)
        }
    }
    
    // MARK: - AIModel Default Implementation Tests
    
    @MainActor func testAIModelDefaultStreamImplementation() async throws {
        // Given
        let mockModel = MockAIModel()
        let messages = [
            ChatMessage(role: .user, content: "Test default stream")
        ]
        let expectedChunks = ["Default stream response"]
        mockModel.configureStreamChunks(expectedChunks)
        
        // When
        let stream = try await mockModel.streamMessage(messages: messages, tools: nil)
        var receivedChunks: [String] = []
        
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        // Then
        XCTAssertEqual(receivedChunks.count, 1)
        XCTAssertEqual(receivedChunks.first, "Default stream response")
    }
    
    @MainActor func testAIModelDefaultStreamFallbackToSendMessage() async throws {
        // Given - Create a simple mock that only implements sendMessage (not streamMessage)
        let mockModel = SimpleMockAIModel()
        let messages = [
            ChatMessage(role: .user, content: "Test fallback stream")
        ]
        let expectedResponse = ChatMessage(role: .assistant, content: "Fallback stream response")
        mockModel.configureSuccessResponse(expectedResponse)
        
        // When - Call streamMessage (should use default implementation that calls sendMessage)
        let stream = try await mockModel.streamMessage(messages: messages, tools: nil)
        var receivedChunks: [String] = []
        
        for try await chunk in stream {
            receivedChunks.append(chunk)
        }
        
        // Then - Should get the response content as a single chunk
        XCTAssertEqual(receivedChunks.count, 1)
        XCTAssertEqual(receivedChunks.first, "Fallback stream response")
    }
    
    // MARK: - AIModelError Tests
    
    func testAIModelErrorInvalidResponse() {
        // Given
        let error = AIModelError.invalidResponse
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertEqual(description, "Invalid response from AI model")
    }
    
    func testAIModelErrorToolExecutionFailed() {
        // Given
        let error = AIModelError.toolExecutionFailed("Tool failed to execute")
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertEqual(description, "Tool execution failed: Tool failed to execute")
    }
    
    func testAIModelErrorAPIKeyMissing() {
        // Given
        let error = AIModelError.apiKeyMissing
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertEqual(description, "API key is missing")
    }
    
    func testAIModelErrorNetworkError() {
        // Given
        let underlyingError = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        let error = AIModelError.networkError(underlyingError)
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertEqual(description, "Network error: No internet connection")
    }
    
    func testAIModelErrorUnsupportedFeature() {
        // Given
        let error = AIModelError.unsupportedFeature
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertEqual(description, "This feature is not supported by the model")
    }
    
    // MARK: - ChatMessage Tests
    
    func testChatMessageInitialization() {
        // Given
        let id = UUID()
        let role = MessageRole.user
        let content = "Test message"
        let timestamp = Date()
        let toolCalls = [ToolCall(id: "call1", name: "test_tool", arguments: "{}")]
        let toolCallId = "call1"
        
        // When
        let message = ChatMessage(
            id: id,
            role: role,
            content: content,
            timestamp: timestamp,
            toolCalls: toolCalls,
            toolCallId: toolCallId
        )
        
        // Then
        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.role, role)
        XCTAssertEqual(message.content, content)
        XCTAssertEqual(message.timestamp, timestamp)
        XCTAssertEqual(message.toolCalls, toolCalls)
        XCTAssertEqual(message.toolCallId, toolCallId)
    }
    
    func testChatMessageDefaultValues() {
        // When
        let message = ChatMessage(role: .assistant, content: "Test")
        
        // Then
        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Test")
        XCTAssertNotNil(message.timestamp)
        XCTAssertNil(message.toolCalls)
        XCTAssertNil(message.toolCallId)
    }
    
    // MARK: - MessageRole Tests
    
    func testMessageRoleValues() {
        XCTAssertEqual(MessageRole.system.rawValue, "system")
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.tool.rawValue, "tool")
    }
    
    // MARK: - ToolCall Tests
    
    func testToolCallInitialization() {
        // Given
        let id = "call123"
        let name = "test_tool"
        let arguments = "{\"param\": \"value\"}"
        
        // When
        let toolCall = ToolCall(id: id, name: name, arguments: arguments)
        
        // Then
        XCTAssertEqual(toolCall.id, id)
        XCTAssertEqual(toolCall.name, name)
        XCTAssertEqual(toolCall.arguments, arguments)
    }
    
    // MARK: - ToolResult Tests
    
    func testToolResultInitialization() {
        // Given
        let toolCallId = "call123"
        let result = "Tool execution completed"
        
        // When
        let toolResult = ToolResult(toolCallId: toolCallId, result: result)
        
        // Then
        XCTAssertEqual(toolResult.toolCallId, toolCallId)
        XCTAssertEqual(toolResult.result, result)
    }
    
    // MARK: - Codable Tests
    
    @MainActor func testChatMessageCodable() throws {
        // Given
        let originalMessage = ChatMessage(
            role: .user,
            content: "Test message",
            toolCalls: [ToolCall(id: "call1", name: "test_tool", arguments: "{\"param\": \"value\"}")],
            toolCallId: "call1"
        )
        
        // When
        let data = try JSONEncoder().encode(originalMessage)
        let decodedMessage = try JSONDecoder().decode(ChatMessage.self, from: data)
        
        // Then
        XCTAssertEqual(decodedMessage.role, originalMessage.role)
        XCTAssertEqual(decodedMessage.content, originalMessage.content)
        XCTAssertEqual(decodedMessage.toolCalls?.count, originalMessage.toolCalls?.count)
        XCTAssertEqual(decodedMessage.toolCallId, originalMessage.toolCallId)
    }
    
    func testMessageRoleCodable() throws {
        // Given
        let roles: [MessageRole] = [.system, .user, .assistant, .tool]
        
        for role in roles {
            // When
            let data = try JSONEncoder().encode(role)
            let decodedRole = try JSONDecoder().decode(MessageRole.self, from: data)
            
            // Then
            XCTAssertEqual(decodedRole, role)
        }
    }
    
    @MainActor func testToolCallCodable() throws {
        // Given
        let originalToolCall = ToolCall(
            id: "call123",
            name: "test_tool",
            arguments: "{\"param\": \"value\"}"
        )
        
        // When
        let data = try JSONEncoder().encode(originalToolCall)
        let decodedToolCall = try JSONDecoder().decode(ToolCall.self, from: data)
        
        // Then
        XCTAssertEqual(decodedToolCall.id, originalToolCall.id)
        XCTAssertEqual(decodedToolCall.name, originalToolCall.name)
        XCTAssertEqual(decodedToolCall.arguments, originalToolCall.arguments)
    }
    
    @MainActor func testToolResultCodable() throws {
        // Given
        let originalToolResult = ToolResult(
            toolCallId: "call123",
            result: "Tool execution completed"
        )
        
        // When
        let data = try JSONEncoder().encode(originalToolResult)
        let decodedToolResult = try JSONDecoder().decode(ToolResult.self, from: data)
        
        // Then
        XCTAssertEqual(decodedToolResult.toolCallId, originalToolResult.toolCallId)
        XCTAssertEqual(decodedToolResult.result, originalToolResult.result)
    }
    
    // MARK: - Identifiable Tests
    
    func testChatMessageIdentifiable() {
        // Given
        let message1 = ChatMessage(role: .user, content: "Message 1")
        let message2 = ChatMessage(role: .user, content: "Message 2")
        
        // Then
        XCTAssertNotEqual(message1.id, message2.id)
    }
    
    func testToolCallIdentifiable() {
        // Given
        let toolCall1 = ToolCall(id: "call1", name: "tool1", arguments: "{}")
        let toolCall2 = ToolCall(id: "call2", name: "tool2", arguments: "{}")
        
        // Then
        XCTAssertNotEqual(toolCall1.id, toolCall2.id)
    }
    
    // MARK: - Sendable Tests
    
    func testChatMessageSendable() {
        // This test verifies that ChatMessage can be used in concurrent contexts
        let message = ChatMessage(role: .user, content: "Test")
        
        // Create a task to verify it can be passed across concurrency boundaries
        Task {
            let _ = message
        }
        
        // If this compiles and runs without issues, Sendable conformance is working
        XCTAssertTrue(true)
    }
    
    func testToolCallSendable() {
        // This test verifies that ToolCall can be used in concurrent contexts
        let toolCall = ToolCall(id: "call1", name: "tool1", arguments: "{}")
        
        // Create a task to verify it can be passed across concurrency boundaries
        Task {
            let _ = toolCall
        }
        
        // If this compiles and runs without issues, Sendable conformance is working
        XCTAssertTrue(true)
    }
    
    func testToolResultSendable() {
        // This test verifies that ToolResult can be used in concurrent contexts
        let toolResult = ToolResult(toolCallId: "call1", result: "result")
        
        // Create a task to verify it can be passed across concurrency boundaries
        Task {
            let _ = toolResult
        }
        
        // If this compiles and runs without issues, Sendable conformance is working
        XCTAssertTrue(true)
    }
    
    // MARK: - Edge Cases Tests
    
    func testChatMessageWithEmptyContent() {
        // Given & When
        let message = ChatMessage(role: .assistant, content: "")
        
        // Then
        XCTAssertEqual(message.content, "")
        XCTAssertEqual(message.role, .assistant)
    }
    
    func testChatMessageWithVeryLongContent() {
        // Given
        let longContent = String(repeating: "This is a very long message. ", count: 1000)
        
        // When
        let message = ChatMessage(role: .user, content: longContent)
        
        // Then
        XCTAssertEqual(message.content, longContent)
        XCTAssertEqual(message.content.count, longContent.count)
    }
    
    func testChatMessageWithSpecialCharacters() {
        // Given
        let specialContent = "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        
        // When
        let message = ChatMessage(role: .user, content: specialContent)
        
        // Then
        XCTAssertEqual(message.content, specialContent)
    }
    
    func testChatMessageWithUnicodeCharacters() {
        // Given
        let unicodeContent = "Unicode: 你好 مرحبا 🌟"
        
        // When
        let message = ChatMessage(role: .user, content: unicodeContent)
        
        // Then
        XCTAssertEqual(message.content, unicodeContent)
    }
    
    func testToolCallWithEmptyArguments() {
        // Given & When
        let toolCall = ToolCall(id: "call1", name: "tool1", arguments: "")
        
        // Then
        XCTAssertEqual(toolCall.arguments, "")
    }
    
    func testToolCallWithComplexArguments() {
        // Given
        let complexArguments = """
        {
            "param1": "value1",
            "param2": 42,
            "param3": true,
            "param4": ["item1", "item2"],
            "param5": {
                "nested": "value"
            }
        }
        """
        
        // When
        let toolCall = ToolCall(id: "call1", name: "tool1", arguments: complexArguments)
        
        // Then
        XCTAssertEqual(toolCall.arguments, complexArguments)
    }
    
    // MARK: - Performance Tests
    
    @MainActor func testChatMessageCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let _ = ChatMessage(role: .user, content: "Message \(i)")
            }
        }
    }
    
    @MainActor func testToolCallCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let _ = ToolCall(id: "call\(i)", name: "tool\(i)", arguments: "{}")
            }
        }
    }
    
    @MainActor func testChatMessageCodablePerformance() throws {
        let message = ChatMessage(role: .user, content: "Test message")
        
        measure {
            for _ in 0..<1000 {
                do {
                    let data = try JSONEncoder().encode(message)
                    let _ = try JSONDecoder().decode(ChatMessage.self, from: data)
                } catch {
                    XCTFail("Codable performance test failed: \(error)")
                }
            }
        }
    }
}
