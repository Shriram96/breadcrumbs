//
//  SettingsView.swift
//  breadcrumbs
//
//  Settings view for API configuration
//

import SwiftUI

struct SettingsView: View {
    // MARK: Lifecycle

    /// Default initializer for production use
    init() {
        self.keychain = KeychainHelper.shared
    }

    /// Test initializer for dependency injection
    init(keychain: KeychainProtocol) {
        self.keychain = keychain
    }

    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Settings", selection: $selectedTab) {
                Text("API Key").tag(0)
                Text("Server").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content based on selected tab
            if selectedTab == 0 {
                apiKeySettingsView
            } else {
                serverSettingsView
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadAPIKey()
        }
    }

    // MARK: Private

    @Environment(\.dismiss) private var dismiss

    @State private var tempApiKey: String = ""
    @State private var showingSaved: Bool = false
    @State private var hasExistingKey: Bool = false
    @State private var authenticationError: String?
    @State private var selectedTab: Int = 0

    private let keychain: KeychainProtocol

    private var apiKeySettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("API Key Settings")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("OpenAI API Key")
                    .font(.headline)

                SecureField("sk-...", text: $tempApiKey)
                    .textFieldStyle(.roundedBorder)
                    .help("Enter your OpenAI API key")

                Text("Your API key is stored securely in macOS Keychain and never leaves your device.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(tempApiKey.isEmpty)

                    if hasExistingKey && !tempApiKey.isEmpty {
                        Button("Clear") {
                            clearAPIKey()
                        }
                        .foregroundColor(.red)
                    }

                    if showingSaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Saved to Keychain")
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity)
                    }
                }

                // Show authentication error if any
                if let error = authenticationError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Get your API key from: [platform.openai.com](https://platform.openai.com/api-keys)")
                    .font(.caption)
                    .foregroundColor(.blue)

                if hasExistingKey {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("API key is stored in Keychain")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }

    private var serverSettingsView: some View {
        VStack {
            if let apiKey = keychain.get(forKey: KeychainHelper.openAIAPIKey), !apiKey.isEmpty {
                ServerSettingsView(aiModel: OpenAIModel(apiToken: apiKey))
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("API Key Required")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Please configure your OpenAI API key in the API Key tab before starting the server.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Button("Go to API Key Settings") {
                        selectedTab = 0
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    // MARK: - Private Methods

    private func loadAPIKey() {
        #if UNIT_TESTS
            // Skip keychain operations during unit tests to avoid system prompts
            hasExistingKey = false
            tempApiKey = ""
        #else
            if let storedKey = keychain.get(forKey: KeychainHelper.openAIAPIKey) {
                // Show masked version for security
                tempApiKey = String(repeating: "•", count: min(storedKey.count, 20))
                hasExistingKey = true
            } else {
                hasExistingKey = false
            }
        #endif
    }

    private func saveAPIKey() {
        #if UNIT_TESTS
            // Skip keychain operations during unit tests to avoid system prompts
            hasExistingKey = true
            showingSaved = true
        #else
            let success = keychain.save(tempApiKey, forKey: KeychainHelper.openAIAPIKey)

            if success {
                hasExistingKey = true
                showingSaved = true

                // Show success for 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingSaved = false
                    // Reload to show masked version
                    loadAPIKey()
                }
            } else {
                authenticationError = "Failed to save API key to keychain"
            }
        #endif
    }

    private func clearAPIKey() {
        #if UNIT_TESTS
            // Skip keychain operations during unit tests to avoid system prompts
            tempApiKey = ""
            hasExistingKey = false
        #else
            _ = keychain.delete(forKey: KeychainHelper.openAIAPIKey)
            tempApiKey = ""
            hasExistingKey = false
        #endif
    }
}

#Preview {
    SettingsView()
}
