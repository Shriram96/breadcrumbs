//
//  SettingsView.swift
//  breadcrumbs
//
//  Settings view for API configuration
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var tempApiKey: String = ""
    @State private var showingSaved: Bool = false
    @State private var hasExistingKey: Bool = false

    private let keychain = KeychainHelper.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
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
        .frame(width: 450, height: 320)
        .onAppear {
            loadAPIKey()
        }
    }

    // MARK: - Private Methods

    private func loadAPIKey() {
        if let storedKey = keychain.get(forKey: KeychainHelper.openAIAPIKey) {
            // Show masked version for security
            tempApiKey = String(repeating: "•", count: min(storedKey.count, 20))
            hasExistingKey = true
        } else {
            hasExistingKey = false
        }
    }

    private func saveAPIKey() {
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
        }
    }

    private func clearAPIKey() {
        keychain.delete(forKey: KeychainHelper.openAIAPIKey)
        tempApiKey = ""
        hasExistingKey = false
    }
}

#Preview {
    SettingsView()
}
