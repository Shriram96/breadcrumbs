//
//  ServerSettingsView.swift
//  breadcrumbs
//
//  Settings view for HTTP server configuration and management
//

import SwiftUI

// MARK: - ServerSettingsView

struct ServerSettingsView: View {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(aiModel: AIModel) {
        self._serviceManager = StateObject(wrappedValue: ServiceManager(aiModel: aiModel, toolRegistry: .shared))
    }

    // MARK: Internal

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Remote Access Server")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enable HTTP API for remote access to diagnostic capabilities")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Server Status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Server Status")
                        .font(.headline)

                    Spacer()

                    StatusIndicator(isRunning: serviceManager.isServerRunning)
                }

                Text(serviceManager.serverStatus)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let error = serviceManager.lastError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Server Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Configuration")
                    .font(.headline)

                // Port Configuration
                HStack {
                    Text("Port:")
                        .frame(width: 60, alignment: .leading)

                    Text("\(serviceManager.serverPort, specifier: "%.0f")")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)

                    Spacer()

                    Button("Change") {
                        newPortText = "\(serviceManager.serverPort)"
                        showingPortAlert = true
                    }
                    .buttonStyle(.bordered)
                }

                // API Key Configuration
                HStack {
                    Text("API Key:")
                        .frame(width: 60, alignment: .leading)

                    Text(serviceManager.apiKey.prefix(8) + "...")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)

                    Spacer()

                    Button("Change") {
                        newAPIKeyText = serviceManager.apiKey
                        showingAPIKeyAlert = true
                    }
                    .buttonStyle(.bordered)

                    Button("Generate") {
                        Task {
                            await serviceManager.generateNewAPIKey()
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Copy") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(serviceManager.apiKey, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Server Control
            VStack(alignment: .leading, spacing: 12) {
                Text("Control")
                    .font(.headline)

                HStack(spacing: 12) {
                    if !serviceManager.isServerRunning {
                        Button("Start Server") {
                            Task {
                                await serviceManager.startServer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }

            // API Information
            if serviceManager.isServerRunning {
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Information")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Server URL", value: serviceManager.serverURL)
                        InfoRow(label: "API Base", value: serviceManager.apiURL)
                        InfoRow(label: "Health Check", value: "\(serviceManager.apiURL)/health")
                        InfoRow(label: "Chat Endpoint", value: "\(serviceManager.apiURL)/chat")
                        InfoRow(label: "Tools List", value: "\(serviceManager.apiURL)/tools")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }

            // Example Usage
            if serviceManager.isServerRunning {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Example Usage")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test with curl:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(serviceManager.curlExample)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .onDisappear {
            // Stop server when settings view is closed
            if serviceManager.isServerRunning {
                serviceManager.stopServer()
            }
        }
        .alert("Change Port", isPresented: $showingPortAlert) {
            TextField("Port", text: $newPortText)
                .textFieldStyle(.roundedBorder)

            Button("Cancel", role: .cancel) {}

            Button("Update") {
                if let newPort = UInt16(newPortText) {
                    Task {
                        await serviceManager.updatePort(newPort)
                    }
                }
            }
        } message: {
            Text("Enter a port number between 1024 and 65535")
        }
        .alert("Change API Key", isPresented: $showingAPIKeyAlert) {
            TextField("API Key", text: $newAPIKeyText)
                .textFieldStyle(.roundedBorder)

            Button("Cancel", role: .cancel) {}

            Button("Update") {
                Task {
                    await serviceManager.updateAPIKey(newAPIKeyText)
                }
            }
        } message: {
            Text("Enter a new API key for authentication")
        }
    }

    // MARK: Private

    @Environment(\.dismiss) private var dismiss
    @StateObject private var serviceManager: ServiceManager
    @State private var showingAPIKeyAlert = false
    @State private var showingPortAlert = false
    @State private var newPortText = ""
    @State private var newAPIKeyText = ""
}

// MARK: - StatusIndicator

struct StatusIndicator: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isRunning ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(isRunning ? "Running" : "Stopped")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - InfoRow

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ServerSettingsView(aiModel: OpenAIModel(apiToken: "demo-key"))
}
