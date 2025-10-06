//
//  MockAIModel.swift
//  breadcrumbsTests
//
//  Mock implementation of AIModel for testing
//

import Foundation
@testable import breadcrumbs

/// Mock implementation of AIModel for unit testing
final class MockAIModel: AIModel {
    
    // MARK: - Properties
    
    let providerId: String = "mock"
    let displayName: String = "Mock AI Model"
    let supportsTools: Bool = true
    
    // MARK: - Mock Configuration
    
    var shouldThrowError: Bool = false
    var mockError: Error = AIModelError.invalidResponse
    var mockResponse: ChatMessage?
    var mockResponses: [ChatMessage] = [] // Support multiple responses for different calls
    var mockStreamChunks: [String] = []
    var sendMessageCallCount: Int = 0
    var streamMessageCallCount: Int = 0
    var lastMessages: [ChatMessage]?
    var lastTools: [AITool]?
    
    // MARK: - AIModel Implementation
    
    func sendMessage(
        messages: [ChatMessage],
        tools: [AITool]?
    ) async throws -> ChatMessage {
        sendMessageCallCount += 1
        lastMessages = messages
        lastTools = tools
        
        if shouldThrowError {
            throw mockError
        }
        
        // Use multiple responses if available, otherwise fall back to single response
        if !mockResponses.isEmpty {
            let responseIndex = min(sendMessageCallCount - 1, mockResponses.count - 1)
            return mockResponses[responseIndex]
        }
        
        if let response = mockResponse {
            return response
        }
        
        // Default mock response - ensure no tool calls to prevent infinite loops
        // If tools are nil (follow-up call), return a simple response without tool calls
        if tools == nil {
            return ChatMessage(
                role: .assistant,
                content: "Final response after tool execution"
            )
        }
        
        return ChatMessage(
            role: .assistant,
            content: "Mock response for \(messages.count) messages"
        )
    }
    
    func streamMessage(
        messages: [ChatMessage],
        tools: [AITool]?
    ) async throws -> AsyncThrowingStream<String, Error> {
        streamMessageCallCount += 1
        lastMessages = messages
        lastTools = tools
        
        if shouldThrowError {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: mockError)
            }
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                for chunk in mockStreamChunks {
                    continuation.yield(chunk)
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                }
                continuation.finish()
            }
        }
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        shouldThrowError = false
        mockError = AIModelError.invalidResponse
        mockResponse = nil
        mockResponses = []
        mockStreamChunks = []
        sendMessageCallCount = 0
        streamMessageCallCount = 0
        lastMessages = nil
        lastTools = nil
    }
    
    func configureSuccessResponse(_ response: ChatMessage) {
        shouldThrowError = false
        mockResponse = response
        mockResponses = []
    }
    
    func configureMultipleResponses(_ responses: [ChatMessage]) {
        shouldThrowError = false
        mockResponse = nil
        mockResponses = responses
    }
    
    func configureError(_ error: Error) {
        shouldThrowError = true
        mockError = error
    }
    
    func configureStreamChunks(_ chunks: [String]) {
        mockStreamChunks = chunks
    }
}
