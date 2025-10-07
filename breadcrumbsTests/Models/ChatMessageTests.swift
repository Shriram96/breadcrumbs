//
//  ChatMessageTests.swift
//  breadcrumbsTests
//
//  Unit tests for ChatMessage and related data structures
//

@testable import breadcrumbs
import XCTest

final class ChatMessageTests: XCTestCase {
    // MARK: - ChatMessage Tests

    func testChatMessageInitialization() {
        // Given
        let id = UUID()
        let role = MessageRole.user
        let content = "Hello, world!"
        let timestamp = Date()
        let toolCalls = [ToolCall(id: "call1", name: "test_tool", arguments: "{}")]
        let toolCallID = "call1"

        // When
        let message = ChatMessage(
            id: id,
            role: role,
            content: content,
            timestamp: timestamp,
            toolCalls: toolCalls,
            toolCallID: toolCallID
        )

        // Then
        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.role, role)
        XCTAssertEqual(message.content, content)
        XCTAssertEqual(message.timestamp, timestamp)
        XCTAssertEqual(message.toolCalls, toolCalls)
        XCTAssertEqual(message.toolCallID, toolCallID)
    }

    func testChatMessageDefaultInitialization() {
        // When
        let message = ChatMessage(role: .assistant, content: "Test message")

        // Then
        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Test message")
        XCTAssertNotNil(message.timestamp)
        XCTAssertNil(message.toolCalls)
        XCTAssertNil(message.toolCallID)
    }

    @MainActor func testChatMessageCodable() throws {
        // Given
        let originalMessage = ChatMessage(
            role: .user,
            content: "Test message",
            toolCalls: [ToolCall(id: "call1", name: "test_tool", arguments: "{\"param\": \"value\"}")],
            toolCallID: "call1"
        )

        // When
        let data = try JSONEncoder().encode(originalMessage)
        let decodedMessage = try JSONDecoder().decode(ChatMessage.self, from: data)

        // Then
        XCTAssertEqual(decodedMessage.role, originalMessage.role)
        XCTAssertEqual(decodedMessage.content, originalMessage.content)
        XCTAssertEqual(decodedMessage.toolCalls?.count, originalMessage.toolCalls?.count)
        XCTAssertEqual(decodedMessage.toolCallID, originalMessage.toolCallID)
    }

    // MARK: - MessageRole Tests

    func testMessageRoleRawValues() {
        XCTAssertEqual(MessageRole.system.rawValue, "system")
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.tool.rawValue, "tool")
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

    // MARK: - ToolResult Tests

    func testToolResultInitialization() {
        // Given
        let toolCallID = "call123"
        let result = "Tool execution completed successfully"

        // When
        let toolResult = ToolResult(toolCallID: toolCallID, result: result)

        // Then
        XCTAssertEqual(toolResult.toolCallID, toolCallID)
        XCTAssertEqual(toolResult.result, result)
    }

    @MainActor func testToolResultCodable() throws {
        // Given
        let originalToolResult = ToolResult(
            toolCallID: "call123",
            result: "Tool execution completed successfully"
        )

        // When
        let data = try JSONEncoder().encode(originalToolResult)
        let decodedToolResult = try JSONDecoder().decode(ToolResult.self, from: data)

        // Then
        XCTAssertEqual(decodedToolResult.toolCallID, originalToolResult.toolCallID)
        XCTAssertEqual(decodedToolResult.result, originalToolResult.result)
    }

    // MARK: - Identifiable Conformance Tests

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

    // MARK: - Sendable Conformance Tests

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
}
