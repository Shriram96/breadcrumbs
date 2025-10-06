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
                        ForEach(viewModel.displayMessages()) { message in
                            MessageBubble(message: message)
                                .id(message.id)
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
                    if let lastMessage = viewModel.displayMessages().last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
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

                // Tool calls indicator
                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.caption2)
                        Text("Using tools: \(toolCalls.map { $0.name }.joined(separator: ", "))")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                }
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
