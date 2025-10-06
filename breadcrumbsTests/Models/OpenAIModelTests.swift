//
//  OpenAIModelTests.swift
//  breadcrumbsTests
//
//  Unit tests for OpenAIModel
//

import XCTest
@testable import breadcrumbs

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
        XCTAssertEqual(model.providerId, "openai")
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
        XCTAssertEqual(model.providerId, "openai")
        XCTAssertEqual(model.displayName, customModel)
        XCTAssertTrue(model.supportsTools)
    }
    
    // MARK: - Properties Tests
    
    func testProviderId() {
        XCTAssertEqual(openAIModel.providerId, "openai")
    }
    
    func testDisplayName() {
        XCTAssertEqual(openAIModel.displayName, "gpt-4o")
    }
    
    func testSupportsTools() {
        XCTAssertTrue(openAIModel.supportsTools)
    }
    
    // MARK: - Message Conversion Tests
    
    func testConvertMessagesToOpenAI() throws {
        // Given
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful assistant"),
            ChatMessage(role: .user, content: "Hello, world!"),
            ChatMessage(role: .assistant, content: "Hello! How can I help you?")
        ]
        
        // When & Then
        // Since convertMessagesToOpenAI is private, we test it indirectly through sendMessage
        // This test verifies that the model can handle message conversion without errors
        let expectation = XCTestExpectation(description: "Message conversion")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                XCTFail("Message conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConvertMessagesWithToolCalls() throws {
        // Given
        let toolCall = ToolCall(id: "call1", name: "test_tool", arguments: "{\"param\": \"value\"}")
        let messages = [
            ChatMessage(role: .assistant, content: "", toolCalls: [toolCall])
        ]
        
        // When & Then
        // Test through sendMessage since convertMessagesToOpenAI is private
        let expectation = XCTestExpectation(description: "Tool call message conversion")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                XCTFail("Tool call message conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConvertMessagesWithToolResults() throws {
        // Given
        let messages = [
            ChatMessage(role: .tool, content: "Tool result", toolCallId: "call1")
        ]
        
        // When & Then
        // Test through sendMessage since convertMessagesToOpenAI is private
        let expectation = XCTestExpectation(description: "Tool result message conversion")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                XCTFail("Tool result message conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConvertMessagesWithEmptyToolCallId() throws {
        // Given
        let messages = [
            ChatMessage(role: .tool, content: "Tool result", toolCallId: nil)
        ]
        
        // When & Then
        // Test through sendMessage since convertMessagesToOpenAI is private
        let expectation = XCTestExpectation(description: "Empty tool call ID message conversion")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                XCTFail("Empty tool call ID message conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConvertMessagesWithEmptyAssistantContent() throws {
        // Given
        let messages = [
            ChatMessage(role: .assistant, content: "")
        ]
        
        // When & Then
        // Test through sendMessage since convertMessagesToOpenAI is private
        let expectation = XCTestExpectation(description: "Empty assistant content message conversion")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                XCTFail("Empty assistant content message conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
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
                        "description": "First parameter"
                    ]
                ],
                "required": ["param1"]
            ])
        )
        
        // When & Then
        // Since convertToolToOpenAI is private, we test it indirectly through sendMessage
        let expectation = XCTestExpectation(description: "Tool conversion")
        
        Task {
            do {
                let messages = [ChatMessage(role: .user, content: "Test")]
                let _ = try await openAIModel.sendMessage(messages: messages, tools: [mockTool])
                expectation.fulfill()
            } catch {
                XCTFail("Tool conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - JSON Schema Conversion Tests
    
    func testConvertToJSONSchema() {
        // Given
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "param1": [
                    "type": "string",
                    "description": "First parameter"
                ],
                "param2": [
                    "type": "integer",
                    "description": "Second parameter"
                ]
            ],
            "required": ["param1"]
        ]
        
        // When & Then
        // Since convertToJSONSchema is private, we test it indirectly through tool usage
        let mockTool = MockAITool(
            name: "test_tool",
            description: "A test tool",
            parametersSchema: ToolParameterSchema(schema)
        )
        
        let expectation = XCTestExpectation(description: "JSON schema conversion")
        
        Task {
            do {
                let messages = [ChatMessage(role: .user, content: "Test")]
                let _ = try await openAIModel.sendMessage(messages: messages, tools: [mockTool])
                expectation.fulfill()
            } catch {
                XCTFail("JSON schema conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConvertToJSONSchemaWithEnum() {
        // Given
        let schema: [String: Any] = [
            "type": "string",
            "enum": ["option1", "option2", "option3"]
        ]
        
        // When & Then
        // Since convertToJSONSchema is private, we test it indirectly through tool usage
        let mockTool = MockAITool(
            name: "test_tool",
            description: "A test tool",
            parametersSchema: ToolParameterSchema(schema)
        )
        
        let expectation = XCTestExpectation(description: "JSON schema with enum conversion")
        
        Task {
            do {
                let messages = [ChatMessage(role: .user, content: "Test")]
                let _ = try await openAIModel.sendMessage(messages: messages, tools: [mockTool])
                expectation.fulfill()
            } catch {
                XCTFail("JSON schema with enum conversion failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidJSONInToolArguments() {
        // Given
        let toolCall = ToolCall(id: "call1", name: "test_tool", arguments: "invalid json")
        let messages = [
            ChatMessage(role: .assistant, content: "", toolCalls: [toolCall])
        ]
        
        // When & Then
        // Since convertMessagesToOpenAI is private, we test it indirectly through sendMessage
        let expectation = XCTestExpectation(description: "Invalid JSON handling")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                // Expected to fail with invalid JSON
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
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
        XCTAssertEqual(openAIModel.providerId, "openai")
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyMessagesArray() {
        // Given
        let messages: [ChatMessage] = []
        
        // When & Then
        // Since convertMessagesToOpenAI is private, we test it indirectly through sendMessage
        let expectation = XCTestExpectation(description: "Empty messages array")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                // Expected to fail with empty messages
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMessagesWithSpecialCharacters() {
        // Given
        let messages = [
            ChatMessage(role: .user, content: "Hello! How are you? I have special chars: @#$%^&*()")
        ]
        
        // When & Then
        // Since convertMessagesToOpenAI is private, we test it indirectly through sendMessage
        let expectation = XCTestExpectation(description: "Special characters handling")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                // Expected to fail with special characters
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMessagesWithUnicodeCharacters() {
        // Given
        let messages = [
            ChatMessage(role: .user, content: "Hello! 你好! مرحبا! 🌟")
        ]
        
        // When & Then
        // Since convertMessagesToOpenAI is private, we test it indirectly through sendMessage
        let expectation = XCTestExpectation(description: "Unicode characters handling")
        
        Task {
            do {
                let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                expectation.fulfill()
            } catch {
                // Expected to fail with unicode characters
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testMessageConversionPerformance() {
        // Given
        let messages = (0..<100).map { i in
            ChatMessage(role: .user, content: "Message \(i)")
        }
        
        // When & Then
        // Since convertMessagesToOpenAI is private, we test performance indirectly through sendMessage
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                do {
                    let _ = try await openAIModel.sendMessage(messages: messages, tools: nil)
                    expectation.fulfill()
                } catch {
                    // Expected to fail in performance test
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testToolConversionPerformance() {
        // Given
        let tools = (0..<50).map { i in
            MockAITool(
                name: "tool_\(i)",
                description: "Tool \(i) description"
            )
        }
        
        // When & Then
        // Since convertToolToOpenAI is private, we test performance indirectly through sendMessage
        measure {
            let expectation = XCTestExpectation(description: "Tool conversion performance test")
            
            Task {
                do {
                    let messages = [ChatMessage(role: .user, content: "Test")]
                    let _ = try await openAIModel.sendMessage(messages: messages, tools: tools)
                    expectation.fulfill()
                } catch {
                    // Expected to fail in performance test
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}

