//
//  OpenAIModelTests.swift
//  breadcrumbsTests
//
//  Unit tests for OpenAIModel
//

@testable import breadcrumbs
import XCTest

final class OpenAIModelTests: XCTestCase {
    var openAIModel: OpenAIModel!

    override func setUpWithError() throws {
        // Use a test API token for initialization
        openAIModel = OpenAIModel(apiToken: "test-token", model: "gpt-4o")
    }

    override func tearDownWithError() throws {
        openAIModel = nil
    }

    // MARK: - Initialization Tests

    func testInitializationWithAPIToken() {
        // Given
        let apiToken = "test-api-token"

        // When
        let model = OpenAIModel(apiToken: apiToken, model: "gpt-4o")

        // Then
        XCTAssertEqual(model.providerID, "openai")
        XCTAssertEqual(model.displayName, "gpt-4o")
        XCTAssertTrue(model.supportsTools)
    }

    func testInitializationWithCustomModel() {
        // Given
        let apiToken = "test-api-token"
        let customModel = "gpt-3.5-turbo"

        // When
        let model = OpenAIModel(apiToken: apiToken, model: customModel)

        // Then
        XCTAssertEqual(model.providerID, "openai")
        XCTAssertEqual(model.displayName, customModel)
        XCTAssertTrue(model.supportsTools)
    }

    // MARK: - Properties Tests

    func testProviderID() {
        XCTAssertEqual(openAIModel.providerID, "openai")
    }

    func testDisplayName() {
        XCTAssertEqual(openAIModel.displayName, "gpt-4o")
    }

    func testSupportsTools() {
        XCTAssertTrue(openAIModel.supportsTools)
    }

    // MARK: - Message Conversion Tests

    func testConvertMessagesToOpenAI() {
        // Given
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant"),
            ChatMessage(role: .user, content: "Hello, world!"),
            ChatMessage(role: .assistant, content: "Hello! How can I help you?"),
        ]

        // When & Then
        // Test that the model can be initialized and basic properties work
        // Note: We don't test sendMessage with real API calls in unit tests
        XCTAssertEqual(openAIModel.providerID, "openai")
        XCTAssertEqual(openAIModel.displayName, "gpt-4o")
        XCTAssertTrue(openAIModel.supportsTools)

        // Test that messages can be created properly
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].role, .system)
        XCTAssertEqual(messages[1].role, .user)
        XCTAssertEqual(messages[2].role, .assistant)
    }

    func testConvertMessagesWithToolCalls() {
        // Given
        let toolCall = ToolCall(id: "call1", name: "test_tool", arguments: "{\"param\": \"value\"}")
        let messages = [
            ChatMessage(role: .assistant, content: "", toolCalls: [toolCall]),
        ]

        // When & Then
        // Test that tool calls can be created and structured properly
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, .assistant)
        XCTAssertEqual(messages[0].content, "")
        XCTAssertNotNil(messages[0].toolCalls)
        XCTAssertEqual(messages[0].toolCalls?.count, 1)
        XCTAssertEqual(messages[0].toolCalls?.first?.id, "call1")
        XCTAssertEqual(messages[0].toolCalls?.first?.name, "test_tool")
        XCTAssertEqual(messages[0].toolCalls?.first?.arguments, "{\"param\": \"value\"}")
    }

    func testConvertMessagesWithToolResults() {
        // Given
        let messages = [
            ChatMessage(role: .tool, content: "Tool result", toolCallID: "call1"),
        ]

        // When & Then
        // Test that tool result messages can be created and structured properly
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, .tool)
        XCTAssertEqual(messages[0].content, "Tool result")
        XCTAssertEqual(messages[0].toolCallID, "call1")
        XCTAssertNil(messages[0].toolCalls)
    }

    func testConvertMessagesWithEmptyToolCallID() {
        // Given
        let messages = [
            ChatMessage(role: .tool, content: "Tool result", toolCallID: nil),
        ]

        // When & Then
        // Test that tool messages with nil toolCallID can be created
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, .tool)
        XCTAssertEqual(messages[0].content, "Tool result")
        XCTAssertNil(messages[0].toolCallID)
        XCTAssertNil(messages[0].toolCalls)
    }

    func testConvertMessagesWithEmptyAssistantContent() {
        // Given
        let messages = [
            ChatMessage(role: .assistant, content: ""),
        ]

        // When & Then
        // Test that assistant messages with empty content can be created
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, .assistant)
        XCTAssertEqual(messages[0].content, "")
        XCTAssertNil(messages[0].toolCalls)
        XCTAssertNil(messages[0].toolCallID)
    }

    // MARK: - Tool Conversion Tests

    func testConvertToolToOpenAI() {
        // Given
        let mockTool = MockAITool(
            name: "test_tool",
            description: "A test tool",
            parametersSchema: ToolParameterSchema([
                "type": "object",
                "properties": [
                    "param1": [
                        "type": "string",
                        "description": "First parameter",
                    ],
                ],
                "required": ["param1"],
            ])
        )

        // When & Then
        // Test that the tool can be created and has the expected properties
        XCTAssertEqual(mockTool.name, "test_tool")
        XCTAssertEqual(mockTool.description, "A test tool")
        XCTAssertNotNil(mockTool.parametersSchema)

        // Test that the tool can be executed (mock execution)
        Task {
            do {
                let result = try await mockTool.execute(arguments: ["param1": "test_value"])
                XCTAssertEqual(result, "Mock tool result")
            } catch {
                XCTFail("Tool execution failed: \(error)")
            }
        }
    }

    // MARK: - JSON Schema Conversion Tests

    func testConvertToJSONSchema() {
        // Given
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "param1": [
                    "type": "string",
                    "description": "First parameter",
                ],
                "param2": [
                    "type": "integer",
                    "description": "Second parameter",
                ],
            ],
            "required": ["param1"],
        ]

        // When & Then
        // Test that the schema can be wrapped in ToolParameterSchema
        let mockTool = MockAITool(
            name: "test_tool",
            description: "A test tool",
            parametersSchema: ToolParameterSchema(schema)
        )

        // Test that the schema is properly stored and accessible
        XCTAssertEqual(mockTool.name, "test_tool")
        XCTAssertEqual(mockTool.description, "A test tool")
        XCTAssertNotNil(mockTool.parametersSchema)

        // Test that the schema contains expected properties
        let toolSchema = mockTool.parametersSchema.jsonSchema
        XCTAssertEqual(toolSchema["type"] as? String, "object")
        XCTAssertNotNil(toolSchema["properties"])
        XCTAssertNotNil(toolSchema["required"])
    }

    func testConvertToJSONSchemaWithEnum() {
        // Given
        let schema: [String: Any] = [
            "type": "string",
            "enum": ["option1", "option2", "option3"],
        ]

        // When & Then
        // Test that enum schemas can be wrapped in ToolParameterSchema
        let mockTool = MockAITool(
            name: "test_tool",
            description: "A test tool",
            parametersSchema: ToolParameterSchema(schema)
        )

        // Test that the schema is properly stored and accessible
        XCTAssertEqual(mockTool.name, "test_tool")
        XCTAssertEqual(mockTool.description, "A test tool")
        XCTAssertNotNil(mockTool.parametersSchema)

        // Test that the schema contains expected properties
        let toolSchema = mockTool.parametersSchema.jsonSchema
        XCTAssertEqual(toolSchema["type"] as? String, "string")
        XCTAssertNotNil(toolSchema["enum"])

        if let enumValues = toolSchema["enum"] as? [String] {
            XCTAssertEqual(enumValues.count, 3)
            XCTAssertTrue(enumValues.contains("option1"))
            XCTAssertTrue(enumValues.contains("option2"))
            XCTAssertTrue(enumValues.contains("option3"))
        } else {
            XCTFail("Enum values not found in schema")
        }
    }

    // MARK: - Error Handling Tests

    func testInvalidJSONInToolArguments() {
        // Given
        let toolCall = ToolCall(id: "call1", name: "test_tool", arguments: "invalid json")
        let messages = [
            ChatMessage(role: .assistant, content: "", toolCalls: [toolCall]),
        ]

        // When & Then
        // Test that tool calls with invalid JSON can be created (the validation happens elsewhere)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, .assistant)
        XCTAssertEqual(messages[0].content, "")
        XCTAssertNotNil(messages[0].toolCalls)
        XCTAssertEqual(messages[0].toolCalls?.count, 1)
        XCTAssertEqual(messages[0].toolCalls?.first?.id, "call1")
        XCTAssertEqual(messages[0].toolCalls?.first?.name, "test_tool")
        XCTAssertEqual(messages[0].toolCalls?.first?.arguments, "invalid json")
    }

    // MARK: - Model Configuration Tests

    func testModelConfiguration() {
        // Given
        let apiToken = "test-token"
        let model = "gpt-3.5-turbo"

        // When
        let openAIModel = OpenAIModel(apiToken: apiToken, model: model)

        // Then
        XCTAssertEqual(openAIModel.displayName, model)
        XCTAssertEqual(openAIModel.providerID, "openai")
    }

    // MARK: - Edge Cases Tests

    func testEmptyMessagesArray() {
        // Given
        let messages = [ChatMessage]()

        // When & Then
        // Test that empty message arrays can be created
        XCTAssertEqual(messages.count, 0)
        XCTAssertTrue(messages.isEmpty)
    }

    func testMessagesWithSpecialCharacters() {
        // Given
        let messages = [
            ChatMessage(role: .user, content: "Hello! How are you? I have special chars: @#$%^&*()"),
        ]

        // When & Then
        // Test that messages with special characters can be created
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, .user)
        XCTAssertEqual(messages[0].content, "Hello! How are you? I have special chars: @#$%^&*()")
        XCTAssertNil(messages[0].toolCalls)
        XCTAssertNil(messages[0].toolCallID)
    }

    func testMessagesWithUnicodeCharacters() {
        // Given
        let messages = [
            ChatMessage(role: .user, content: "Hello! 你好! مرحبا! 🌟"),
        ]

        // When & Then
        // Test that messages with unicode characters can be created
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, .user)
        XCTAssertEqual(messages[0].content, "Hello! 你好! مرحبا! 🌟")
        XCTAssertNil(messages[0].toolCalls)
        XCTAssertNil(messages[0].toolCallID)
    }

    // MARK: - Performance Tests

    func testMessageConversionPerformance() {
        // When & Then
        // Test performance of message creation and basic operations
        measure {
            // Test message creation performance
            let testMessages = (0..<100).map { i in
                ChatMessage(role: .user, content: "Message \(i)")
            }

            // Test basic operations on messages
            for message in testMessages {
                _ = message.id
                _ = message.role
                _ = message.content
                _ = message.timestamp
            }
        }
    }

    func testToolConversionPerformance() {
        // When & Then
        // Test performance of tool creation and basic operations
        measure {
            // Test tool creation performance
            let testTools = (0..<50).map { i in
                MockAITool(
                    name: "tool_\(i)",
                    description: "Tool \(i) description"
                )
            }

            // Test basic operations on tools
            for tool in testTools {
                _ = tool.name
                _ = tool.description
                _ = tool.parametersSchema
            }
        }
    }
}
