//
//  ChatView.swift
//  breadcrumbs
//
//  Main chat interface for system diagnostics
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    init(apiKey: String) {
        let model = OpenAIModel(apiToken: apiKey, model: "gpt-4o")
        _viewModel = StateObject(wrappedValue: ChatViewModel(aiModel: model))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(groupedMessages()) { group in
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
                    if let lastGroup = groupedMessages().last {
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
    }

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

    // MARK: - Actions

    private func sendMessage() {
        let message = viewModel.currentInput
        Task {
            await viewModel.sendMessage(message)
        }
    }
    
    // MARK: - Message Grouping
    
    private func groupedMessages() -> [MessageGroup] {
        let displayMessages = viewModel.displayMessages()
        var groups: [MessageGroup] = []
        var i = 0
        
        while i < displayMessages.count {
            let message = displayMessages[i]
            
            // Check if this is an assistant message with tool calls
            if message.role == .assistant, let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                // Collect tool results that follow
                var toolResults: [ChatMessage] = []
                var j = i + 1
                
                while j < displayMessages.count && displayMessages[j].role == .tool {
                    toolResults.append(displayMessages[j])
                    j += 1
                }
                
                // Find the final assistant response (if any)
                var finalResponse: ChatMessage? = nil
                if j < displayMessages.count && displayMessages[j].role == .assistant {
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
        
        return groups
    }
}

// MARK: - Message Grouping Data Structures

struct ToolUsageGroup: Identifiable {
    let id: UUID
    let toolCalls: [ToolCall]
    let toolResults: [ChatMessage]
    let finalResponse: ChatMessage?
    
    init(id: UUID, toolCalls: [ToolCall], toolResults: [ChatMessage], finalResponse: ChatMessage?) {
        self.id = id
        self.toolCalls = toolCalls
        self.toolResults = toolResults
        self.finalResponse = finalResponse
    }
}

enum MessageGroup: Identifiable {
    case regular(ChatMessage)
    case toolUsage(ToolUsageGroup)
    
    var id: UUID {
        switch self {
        case .regular(let message):
            return message.id
        case .toolUsage(let group):
            return group.id
        }
    }
}

// MARK: - Message Group View

struct MessageGroupView: View {
    let group: MessageGroup
    @State private var isToolUsageExpanded = false
    
    var body: some View {
        switch group {
        case .regular(let message):
            MessageBubble(message: message)
            
        case .toolUsage(let toolGroup):
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
}

// MARK: - Tool Usage Header

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

// MARK: - Tool Usage Details

struct ToolUsageDetails: View {
    let toolCalls: [ToolCall]
    let toolResults: [ChatMessage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(zip(toolCalls, toolResults)), id: \.0.id) { toolCall, toolResult in
                VStack(alignment: .leading, spacing: 4) {
                    // Tool call info
                    HStack {
                        Text("🔧 \(toolCall.name)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    // Tool result
                    Text(toolResult.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
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

// MARK: - Error Banner

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
