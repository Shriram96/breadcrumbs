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
    @State private var useBiometric: Bool = true
    @State private var isAuthenticating: Bool = false
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

                // Biometric authentication toggle
                HStack {
                    Toggle("Use Touch ID/Face ID", isOn: $useBiometric)
                        .help("Require biometric authentication to access your API key")

                    if keychain.isBiometricAuthenticationAvailable() {
                        HStack(spacing: 4) {
                            Image(systemName: "touchid")
                                .foregroundColor(.blue)
                            Text(keychain.getBiometricType())
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("Not Available")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Your API key is stored securely in macOS Keychain and never leaves your device.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(tempApiKey.isEmpty || isAuthenticating)

                    if hasExistingKey && !tempApiKey.isEmpty {
                        Button("Clear") {
                            clearAPIKey()
                        }
                        .foregroundColor(.red)
                        .disabled(isAuthenticating)
                    }

                    if isAuthenticating {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Authenticating...")
                                .foregroundColor(.secondary)
                        }
                    } else if showingSaved {
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
            // Check if we should use biometric authentication
            if useBiometric, keychain.isBiometricAuthenticationAvailable() {
                isAuthenticating = true
                authenticationError = nil

                keychain.authenticateWithBiometrics(reason: "Access your stored API key") { [self] success, error in
                    DispatchQueue.main.async {
                        isAuthenticating = false

                        if success {
                            // Authentication successful, get the API key
                            if
                                let storedKey = keychain.get(
                                    forKey: KeychainHelper.openAIAPIKey,
                                    prompt: "Access your API key"
                                )
                            {
                                // Show masked version for security
                                tempApiKey = String(repeating: "•", count: min(storedKey.count, 20))
                                hasExistingKey = true
                            } else {
                                hasExistingKey = false
                            }
                        } else {
                            // Authentication failed
                            if let error = error {
                                authenticationError = "Authentication failed: \(error.localizedDescription)"
                            } else {
                                authenticationError = "Authentication was cancelled"
                            }
                            hasExistingKey = false
                        }
                    }
                }
            } else {
                // Fallback to regular keychain access
                if let storedKey = keychain.get(forKey: KeychainHelper.openAIAPIKey) {
                    // Show masked version for security
                    tempApiKey = String(repeating: "•", count: min(storedKey.count, 20))
                    hasExistingKey = true
                } else {
                    hasExistingKey = false
                }
            }
        #endif
    }

    private func saveAPIKey() {
        #if UNIT_TESTS
            // Skip keychain operations during unit tests to avoid system prompts
            hasExistingKey = true
            showingSaved = true
        #else
            // Check if we should use biometric authentication
            if useBiometric, keychain.isBiometricAuthenticationAvailable() {
                isAuthenticating = true
                authenticationError = nil

                keychain.authenticateWithBiometrics(reason: "Save your API key securely") { [self] success, error in
                    DispatchQueue.main.async {
                        isAuthenticating = false

                        if success {
                            // Authentication successful, save the API key with biometric protection
                            let saveSuccess = keychain.save(
                                tempApiKey,
                                forKey: KeychainHelper.openAIAPIKey,
                                requireBiometric: useBiometric
                            )

                            if saveSuccess {
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
                        } else {
                            // Authentication failed
                            if let error = error {
                                authenticationError = "Authentication failed: \(error.localizedDescription)"
                            } else {
                                authenticationError = "Authentication was cancelled"
                            }
                        }
                    }
                }
            } else {
                // Fallback to regular keychain save
                let success = keychain.save(tempApiKey, forKey: KeychainHelper.openAIAPIKey, requireBiometric: false)

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
            }
        #endif
    }

    private func clearAPIKey() {
        #if UNIT_TESTS
            // Skip keychain operations during unit tests to avoid system prompts
            tempApiKey = ""
            hasExistingKey = false
        #else
            // Check if we should use biometric authentication
            if useBiometric, keychain.isBiometricAuthenticationAvailable() {
                isAuthenticating = true
                authenticationError = nil

                keychain
                    .authenticateWithBiometrics(reason: "Remove your API key from secure storage") { [
                        self
                    ] success, error in
                        DispatchQueue.main.async {
                            isAuthenticating = false

                            if success {
                                // Authentication successful, delete the API key
                                _ = keychain.delete(forKey: KeychainHelper.openAIAPIKey)
                                tempApiKey = ""
                                hasExistingKey = false
                            } else {
                                // Authentication failed
                                if let error = error {
                                    authenticationError = "Authentication failed: \(error.localizedDescription)"
                                } else {
                                    authenticationError = "Authentication was cancelled"
                                }
                            }
                        }
                    }
            } else {
                // Fallback to regular keychain delete
                _ = keychain.delete(forKey: KeychainHelper.openAIAPIKey)
                tempApiKey = ""
                hasExistingKey = false
            }
        #endif
    }
}

#Preview {
    SettingsView()
}
