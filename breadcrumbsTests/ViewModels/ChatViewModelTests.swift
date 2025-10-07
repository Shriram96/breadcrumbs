//
//  ChatViewModelTests.swift
//  breadcrumbsTests
//
//  Unit tests for ChatViewModel
//

@testable import breadcrumbs
import Combine
import XCTest

@MainActor
final class ChatViewModelTests: XCTestCase {
    var viewModel: ChatViewModel!
    var mockAIModel: MockAIModel!
    var mockToolRegistry: MockToolRegistry!

    // MARK: - Helper Methods

    override func setUpWithError() throws {
        mockAIModel = MockAIModel()
        mockToolRegistry = MockToolRegistry(forTesting: true)
        viewModel = ChatViewModel(aiModel: mockAIModel, toolRegistry: mockToolRegistry)
    }

    override func tearDownWithError() throws {
        // Reset mock state to prevent issues
        mockAIModel?.reset()
        mockToolRegistry?.reset()

        // Let XCTest handle the cleanup automatically to avoid @MainActor deallocation issues
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Then
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.messages.first?.role, .system)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.currentInput.isEmpty)
    }

    func testSystemPromptIsSet() {
        // Then
        let systemMessage = viewModel.messages.first
        XCTAssertEqual(systemMessage?.role, .system)
        XCTAssertTrue(systemMessage?.content.contains("system diagnostic assistant") == true)
    }

    // MARK: - Send Message Tests

    func testSendMessageSuccess() async {
        // Given
        let userMessage = "Test message"
        let mockResponse = ChatMessage(role: .assistant, content: "Mock response")
        mockAIModel.configureSuccessResponse(mockResponse)

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(userMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertEqual(viewModel.messages.count, 3) // system + user + assistant
        XCTAssertEqual(viewModel.messages[1].content, userMessage)
        XCTAssertEqual(viewModel.messages[1].role, .user)
        XCTAssertEqual(viewModel.messages[2].content, "Mock response")
        XCTAssertEqual(viewModel.messages[2].role, .assistant)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.currentInput.isEmpty)
        XCTAssertEqual(mockAIModel.sendMessageCallCount, 1)
    }

    func testSendMessageWithEmptyContent() async {
        // Given
        let emptyMessage = ""
        let initialMessageCount = viewModel.messages.count

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(emptyMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertEqual(viewModel.messages.count, initialMessageCount)
        XCTAssertEqual(mockAIModel.sendMessageCallCount, 0)
    }

    func testSendMessageWithWhitespaceContent() async {
        // Given
        let whitespaceMessage = "   "
        let initialMessageCount = viewModel.messages.count

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(whitespaceMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertEqual(viewModel.messages.count, initialMessageCount)
        XCTAssertEqual(mockAIModel.sendMessageCallCount, 0)
    }

    func testSendMessageError() async throws {
        // Given
        let userMessage = "Test message"
        let mockError = AIModelError.networkError(NSError(domain: "TestError", code: -1, userInfo: nil))
        mockAIModel.configureError(mockError)

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(userMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertEqual(viewModel.messages.count, 3) // system + user + error message
        XCTAssertEqual(viewModel.messages[1].content, userMessage)
        XCTAssertEqual(viewModel.messages[1].role, .user)
        XCTAssertEqual(viewModel.messages[2].role, .assistant)
        XCTAssertTrue(viewModel.messages[2].content.contains("I encountered an error"))
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(try XCTUnwrap(viewModel.errorMessage?.contains("Network error")))
    }

    // MARK: - Tool Call Tests

    func testSendMessageWithToolCalls() async {
        // Given
        let userMessage = "Check VPN status"
        let toolCall = ToolCall(id: "call1", name: "vpn_detector", arguments: "{}")
        let mockResponseWithTools = ChatMessage(
            role: .assistant,
            content: "",
            toolCalls: [toolCall]
        )
        let finalResponse = ChatMessage(role: .assistant, content: "VPN is connected")

        // Register the required tool
        let mockTool = MockAITool(name: "vpn_detector", description: "VPN detector tool")
        mockToolRegistry.register(mockTool)

        // Configure multiple responses: first call returns tool calls, second call returns final response
        mockAIModel.configureMultipleResponses([mockResponseWithTools, finalResponse])

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(userMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        // Should have: system + user + assistant with tools + tool result + final response
        XCTAssertEqual(viewModel.messages.count, 5)
        XCTAssertEqual(viewModel.messages[1].content, userMessage)
        XCTAssertEqual(viewModel.messages[1].role, .user)
        XCTAssertEqual(viewModel.messages[2].role, .assistant)
        XCTAssertEqual(viewModel.messages[2].toolCalls?.count, 1)
        XCTAssertEqual(viewModel.messages[3].role, .tool)
        XCTAssertEqual(viewModel.messages[3].toolCallID, "call1")
        XCTAssertEqual(viewModel.messages[4].content, "VPN is connected")
        XCTAssertEqual(viewModel.messages[4].role, .assistant)
    }

    func testToolCallExecutionError() async {
        // Given
        let userMessage = "Check VPN status"
        let toolCall = ToolCall(id: "call1", name: "vpn_detector", arguments: "{}")
        let mockResponseWithTools = ChatMessage(
            role: .assistant,
            content: "",
            toolCalls: [toolCall]
        )
        let finalResponse = ChatMessage(role: .assistant, content: "Tool execution failed")

        // Register the required tool
        let mockTool = MockAITool(name: "vpn_detector", description: "VPN detector tool")
        mockToolRegistry.register(mockTool)

        // Configure multiple responses: first call returns tool calls, second call returns final response
        mockAIModel.configureMultipleResponses([mockResponseWithTools, finalResponse])
        mockToolRegistry.shouldThrowError = true
        mockToolRegistry.mockError = ToolError.executionFailed("Tool failed")

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(userMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertEqual(viewModel.messages.count, 5)
        XCTAssertEqual(viewModel.messages[3].role, .tool)
        XCTAssertEqual(viewModel.messages[3].toolCallID, "call1")
        XCTAssertTrue(viewModel.messages[3].content.contains("Tool execution failed"))
    }

    func testMultipleToolCalls() async {
        // Given
        let userMessage = "Check system status"
        let toolCall1 = ToolCall(id: "call1", name: "vpn_detector", arguments: "{}")
        let toolCall2 = ToolCall(id: "call2", name: "system_check", arguments: "{}")
        let mockResponseWithTools = ChatMessage(
            role: .assistant,
            content: "",
            toolCalls: [toolCall1, toolCall2]
        )
        let finalResponse = ChatMessage(role: .assistant, content: "System check complete")

        // Register the required tools
        let mockTool1 = MockAITool(name: "vpn_detector", description: "VPN detector tool")
        let mockTool2 = MockAITool(name: "system_check", description: "System check tool")
        mockToolRegistry.register(mockTool1)
        mockToolRegistry.register(mockTool2)

        // Configure multiple responses: first call returns tool calls, second call returns final response
        mockAIModel.configureMultipleResponses([mockResponseWithTools, finalResponse])
        mockToolRegistry.mockResult = "VPN Status: Connected"

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(userMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        // Should have: system + user + assistant with tools + 2 tool results + final response
        XCTAssertEqual(viewModel.messages.count, 6)
        XCTAssertEqual(viewModel.messages[2].toolCalls?.count, 2)
        XCTAssertEqual(viewModel.messages[3].toolCallID, "call1")
        XCTAssertEqual(viewModel.messages[4].toolCallID, "call2")
    }

    // MARK: - Clear Chat Tests

    func testClearChat() {
        // Given
        viewModel.messages.append(ChatMessage(role: .user, content: "Test message"))
        viewModel.messages.append(ChatMessage(role: .assistant, content: "Response"))
        viewModel.errorMessage = "Some error"

        // When
        viewModel.clearChat()

        // Then
        XCTAssertEqual(viewModel.messages.count, 1) // Only system message remains
        XCTAssertEqual(viewModel.messages.first?.role, .system)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Display Messages Tests

    func testDisplayMessages() {
        // Given
        let userMessage = ChatMessage(role: .user, content: "User message")
        let assistantMessage = ChatMessage(role: .assistant, content: "Assistant message")

        viewModel.messages.append(userMessage)
        viewModel.messages.append(assistantMessage)

        // When
        let displayMessages = viewModel.displayMessages()

        // Then
        XCTAssertEqual(displayMessages.count, 2)
        XCTAssertEqual(displayMessages[0].content, "User message")
        XCTAssertEqual(displayMessages[1].content, "Assistant message")
        XCTAssertFalse(displayMessages.contains { $0.role == .system })
    }

    func testDisplayMessagesWithToolCalls() {
        // Given
        let userMessage = ChatMessage(role: .user, content: "User message")
        let toolCall = ToolCall(id: "call1", name: "test_tool", arguments: "{}")
        let assistantMessageWithTools = ChatMessage(
            role: .assistant,
            content: "",
            toolCalls: [toolCall]
        )
        let toolResult = ChatMessage(role: .tool, content: "Tool result", toolCallID: "call1")
        let finalResponse = ChatMessage(role: .assistant, content: "Final response")

        viewModel.messages.append(userMessage)
        viewModel.messages.append(assistantMessageWithTools)
        viewModel.messages.append(toolResult)
        viewModel.messages.append(finalResponse)

        // When
        let displayMessages = viewModel.displayMessages()

        // Then
        XCTAssertEqual(displayMessages.count, 4)
        XCTAssertEqual(displayMessages[0].role, .user)
        XCTAssertEqual(displayMessages[1].role, .assistant)
        XCTAssertEqual(displayMessages[2].role, .tool)
        XCTAssertEqual(displayMessages[3].role, .assistant)
    }

    // MARK: - Processing State Tests

    func testProcessingStateDuringMessage() async {
        // Given
        let userMessage = "Test message"
        let expectation = XCTestExpectation(description: "Processing state changes")

        // Monitor processing state changes
        let cancellable = viewModel.$isProcessing
            .dropFirst() // Skip initial value
            .sink { isProcessing in
                if !isProcessing {
                    expectation.fulfill()
                }
            }

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(userMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isProcessing)
        cancellable.cancel()
    }

    // MARK: - Input Management Tests

    func testCurrentInputClearedAfterSend() async {
        // Given
        viewModel.currentInput = "Test input"
        mockAIModel.configureSuccessResponse(ChatMessage(role: .assistant, content: "Response"))

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage("Test message")
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertTrue(viewModel.currentInput.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testErrorMessageClearedOnNewMessage() async {
        // Given
        viewModel.errorMessage = "Previous error"
        mockAIModel.configureSuccessResponse(ChatMessage(role: .assistant, content: "Response"))

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage("New message")
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Tool Registry Integration Tests

    func testToolRegistryIntegration() async {
        // Given
        let mockTool = MockAITool(name: "test_tool", description: "Test tool")
        mockToolRegistry.register(mockTool)

        let userMessage = "Use test tool"
        let toolCall = ToolCall(id: "call1", name: "test_tool", arguments: "{}")
        let mockResponseWithTools = ChatMessage(
            role: .assistant,
            content: "",
            toolCalls: [toolCall]
        )
        let finalResponse = ChatMessage(role: .assistant, content: "Tool executed successfully")

        // Configure multiple responses: first call returns tool calls, second call returns final response
        mockAIModel.configureMultipleResponses([mockResponseWithTools, finalResponse])

        // When
        do {
            try await TestUtilities.withTimeout(seconds: 5) { [self] in
                await viewModel.sendMessage(userMessage)
            }
        } catch {
            XCTFail("Test timed out: \(error)")
        }

        // Then
        XCTAssertEqual(mockToolRegistry.executeToolCallCount, 1)
        XCTAssertEqual(mockToolRegistry.lastExecuteToolName, "test_tool")
    }
}
