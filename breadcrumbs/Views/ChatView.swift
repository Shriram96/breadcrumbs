//
//  ChatView.swift
//  breadcrumbs
//
//  Main chat interface for system diagnostics
//

import Foundation
import SwiftUI

// MARK: - ChatView

struct ChatView: View {
    // MARK: Lifecycle

    init(apiKey: String) {
        let model = OpenAIModel(apiToken: apiKey, model: "gpt-4o")
        _viewModel = StateObject(wrappedValue: ChatViewModel(aiModel: model))
    }

    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cachedMessageGroups) { group in
                            MessageGroupView(group: group)
                                .id(group.id)
                        }

                        // Processing indicator
                        if viewModel.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyzing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    updateCachedMessageGroups()
                    if let lastGroup = cachedMessageGroups.last {
                        withAnimation {
                            proxy.scrollTo(lastGroup.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Error message
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            Divider()

            // Input area
            inputArea
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            updateCachedMessageGroups()
        }
    }

    // MARK: Private

    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var cachedMessageGroups: [MessageGroup] = []
    @State private var lastMessageCount: Int = 0

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Diagnostics Assistant")
                    .font(.headline)
                Text("Ask about VPN, network, or connectivity issues")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                viewModel.clearChat()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear chat history")
        }
        .padding()
    }

    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Ask about your system...", text: $viewModel.currentInput, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.currentInput.isEmpty ? .gray : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentInput.isEmpty || viewModel.isProcessing)
        }
        .padding()
    }

    private func sendMessage() {
        let message = viewModel.currentInput
        Task {
            await viewModel.sendMessage(message)
        }
    }

    // MARK: - Message Grouping

    private func updateCachedMessageGroups() {
        // Only update if message count has changed
        if viewModel.messages.count != lastMessageCount {
            cachedMessageGroups = computeGroupedMessages()
            lastMessageCount = viewModel.messages.count
        }
    }

    private func computeGroupedMessages() -> [MessageGroup] {
        let displayMessages = viewModel.displayMessages()
        var groups = [MessageGroup]()
        var i = 0

        Logger.ui("Computing grouped messages from \(displayMessages.count) display messages")

        while i < displayMessages.count {
            let message = displayMessages[i]

            // Check if this is an assistant message with tool calls
            if message.role == .assistant, let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                Logger.ui("Found assistant message with \(toolCalls.count) tool calls")

                // Collect tool results that follow
                var toolResults = [ChatMessage]()
                var j = i + 1

                while j < displayMessages.count, displayMessages[j].role == .tool {
                    let toolResult = displayMessages[j]
                    toolResults.append(toolResult)
                    Logger
                        .ui(
                            "Found tool result: ID=\(toolResult.toolCallID ?? "nil"), Content=\(toolResult.content.prefix(50))..."
                        )
                    j += 1
                }

                Logger.ui("Collected \(toolResults.count) tool results for \(toolCalls.count) tool calls")

                // Find the final assistant response (if any)
                var finalResponse: ChatMessage? = nil
                if j < displayMessages.count, displayMessages[j].role == .assistant {
                    finalResponse = displayMessages[j]
                    j += 1
                }

                // Create tool group
                let toolGroup = ToolUsageGroup(
                    id: message.id,
                    toolCalls: toolCalls,
                    toolResults: toolResults,
                    finalResponse: finalResponse
                )
                groups.append(.toolUsage(toolGroup))

                i = j
            } else {
                // Regular message
                groups.append(.regular(message))
                i += 1
            }
        }

        Logger.ui("Created \(groups.count) message groups")
        return groups
    }
}

// MARK: - ToolUsageGroup

struct ToolUsageGroup: Identifiable {
    // MARK: Internal

    let id: UUID
    let toolCalls: [ToolCall]
    let toolResults: [ChatMessage]
    let finalResponse: ChatMessage?
}

// MARK: - MessageGroup

enum MessageGroup: Identifiable {
    case regular(ChatMessage)
    case toolUsage(ToolUsageGroup)

    // MARK: Internal

    var id: UUID {
        switch self {
        case let .regular(message):
            return message.id
        case let .toolUsage(group):
            return group.id
        }
    }
}

// MARK: - MessageGroupView

struct MessageGroupView: View {
    // MARK: Internal

    let group: MessageGroup

    var body: some View {
        switch group {
        case let .regular(message):
            MessageBubble(message: message)

        case let .toolUsage(toolGroup):
            VStack(alignment: .leading, spacing: 8) {
                // Tool usage header (collapsible)
                ToolUsageHeader(
                    toolCalls: toolGroup.toolCalls,
                    isExpanded: $isToolUsageExpanded
                )

                // Tool usage details (expandable)
                if isToolUsageExpanded {
                    ToolUsageDetails(
                        toolCalls: toolGroup.toolCalls,
                        toolResults: toolGroup.toolResults
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                // Final AI response
                if let finalResponse = toolGroup.finalResponse {
                    MessageBubble(message: finalResponse)
                }
            }
        }
    }

    // MARK: Private

    @State private var isToolUsageExpanded = false
}

// MARK: - ToolUsageHeader

struct ToolUsageHeader: View {
    let toolCalls: [ToolCall]
    @Binding var isExpanded: Bool

    var body: some View {
        HStack {
            Spacer(minLength: 60)

            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.caption2)
                        Text("Using tool: \(toolCalls.map { $0.name }.joined(separator: ", "))")
                            .font(.caption2)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 60)
        }
    }
}

// MARK: - ToolUsageDetails

struct ToolUsageDetails: View {
    let toolCalls: [ToolCall]
    let toolResults: [ChatMessage]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(toolCalls, id: \.id) { toolCall in
                VStack(alignment: .leading, spacing: 4) {
                    // Tool call info
                    HStack {
                        Text("🔧 \(toolCall.name)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }

                    // Find the corresponding tool result
                    if let toolResult = toolResults.first(where: { $0.toolCallID == toolCall.id }) {
                        // Tool result
                        Text(toolResult.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(6)
                    } else {
                        // No result found for this tool call
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No result available")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .italic()
                                .padding(8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(6)

                            // Debug info
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Debug Info:")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                Text("Tool Call ID: \(toolCall.id)")
                                    .font(.caption2)
                                Text("Available Results: \(toolResults.count)")
                                    .font(.caption2)
                                ForEach(toolResults, id: \.id) { result in
                                    Text("  - Result ID: \(result.toolCallID ?? "nil")")
                                        .font(.caption2)
                                }
                            }
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            Logger.ui("ToolUsageDetails: \(toolCalls.count) tool calls, \(toolResults.count) tool results")
            for toolCall in toolCalls {
                Logger.ui("  - Tool Call: \(toolCall.name), ID: \(toolCall.id)")
            }
            for toolResult in toolResults {
                Logger
                    .ui(
                        "  - Tool Result: ID: \(toolResult.toolCallID ?? "nil"), Content: \(toolResult.content.prefix(50))..."
                    )
            }
        }
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    // MARK: Internal

    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(12)
                    .textSelection(.enabled)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    // MARK: Private

    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return Color.accentColor
        case .assistant:
            return Color(nsColor: .controlBackgroundColor)
        default:
            return Color.gray.opacity(0.2)
        }
    }

    private var textColor: Color {
        message.role == .user ? .white : Color(nsColor: .labelColor)
    }
}

// MARK: - ErrorBanner

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text(message)
                .font(.caption)
            Spacer()
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
    }
}

// MARK: - Preview

#Preview {
    ChatView(apiKey: "test-key")
        .frame(width: 600, height: 500)
}
